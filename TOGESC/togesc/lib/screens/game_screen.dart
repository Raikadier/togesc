import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import '../app/design_tokens.dart';
import '../app/router.dart';
import '../constants/game_constants.dart';
import '../constants/note_naming.dart';
import '../models/audio_preferences.dart';
import '../models/last_practice_session.dart';
import '../models/practice_session_preferences.dart';
import '../models/ui_preferences.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/audio_preferences_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/game_session_provider.dart';
import '../providers/practice_focus_provider.dart';
import '../providers/practice_session_preferences_provider.dart';
import '../providers/session_history_provider.dart';
import '../providers/srs_provider.dart';
import '../providers/today_session_provider.dart';
import '../providers/ui_preferences_provider.dart';
import '../services/microphone_pitch_service.dart';
import '../utils/piano_note_selection.dart';
import '../utils/srs_level.dart';
import '../utils/today_session.dart';
import '../widgets/microphone_answer_panel.dart';
import '../widgets/note_input_field.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/session_v2/session_key_actions.dart';
import '../widgets/session_v2/session_phase.dart';
import '../widgets/session_v2/session_phase_ring.dart';
import '../widgets/session_v2/session_shortcuts.dart';
import '../widgets/session_v2/session_srs_panel.dart';
import '../widgets/session_v2/session_top_bar.dart';
import '../widgets/session_v2/srs_level_pill.dart';

/// Sesión de juego v2 «La sesión como instrumento» (1b móvil, 1d escritorio).
///
/// Máquina de estados: `listen` (≥1,5 s) → `answer` → (un toque) → `result`
/// (2,2 s, o el retardo reducido) → siguiente ronda. El feedback se pinta
/// sobre la misma tecla; no hay card de resultado ni segundo teclado.
///
/// Idle mínimo (D4): solo si la sesión arranca sin gesto previo (enlace
/// directo o recarga en web). Desde el Home se entra directo a `listen`.
class GameScreen extends ConsumerStatefulWidget {
  final GameMode mode;

  /// Arrancar la primera ronda sin pasar por «Toca para empezar».
  /// `null` = automático: fuera de web siempre; en web solo si se llegó
  /// navegando dentro de la app (hubo gesto y hay ruta a la que volver).
  final bool? autoStart;

  const GameScreen({super.key, required this.mode, this.autoStart});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final _selectedNotes = <String>{};
  DateTime? _roundStartTime;
  DateTime? _pauseStartedAt;
  Duration _accumulatedPause = Duration.zero;

  /// Se está preparando una ronda (entre el gesto y el primer audio).
  bool _starting = false;

  /// El audio ya sonó pero la fase `listen` aún no cumplió su mínimo.
  bool _holdingListen = false;

  /// «Repetir» está reproduciendo de nuevo la ronda.
  bool _replaying = false;

  /// Invalida continuaciones asíncronas de rondas anteriores.
  int _roundToken = 0;

  /// Foco de la sesión capturado al entrar (ver [_focusNotes]).
  List<String>? _sessionFocusNotes;

  Timer? _listenTimer;
  Timer? _advanceTimer;

  // --- Preferencias ---------------------------------------------------------

  UiPreferences _uiPrefs() =>
      ref.read(uiPreferencesProvider).valueOrNull ?? const UiPreferences();

  PracticeSessionPreferences _sessionPrefs() =>
      ref.read(practiceSessionPreferencesProvider).valueOrNull ??
      const PracticeSessionPreferences();

  bool _reduceMotion() =>
      _uiPrefs().reduceAnimations || MediaQuery.disableAnimationsOf(context);

  /// Retardo del avance automático: 2,2 s (v2) o 400 ms con movimiento
  /// reducido. Con lector de pantalla activo se duplica el de 2,2 s para que
  /// dé tiempo a oír el anuncio del resultado.
  Duration _autoAdvanceDelay() {
    if (MediaQuery.accessibleNavigationOf(context)) {
      return resultAutoAdvanceDelay * 2;
    }
    return _reduceMotion()
        ? resultAutoAdvanceDelayReducedMotion
        : resultAutoAdvanceDelay;
  }

  int _requiredNotes(GameSessionState session) => selectableNoteCount(
        screenMode: widget.mode,
        sessionNumNotes: session.numNotes,
      );

  int _displayRound(GameSessionState session) {
    if (session.state == GameState.showingResult) {
      return session.roundsCompleted;
    }
    return session.roundsCompleted + 1;
  }

  // --- Ciclo de vida --------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final single = ref.read(practiceFocusNoteProvider);
      setState(() {
        _sessionFocusNotes = single != null
            ? [single]
            : List.of(ref.read(practiceFocusNotesProvider));
      });
      ref.read(gameSessionProvider.notifier).setMode(widget.mode);
      final auto = widget.autoStart ??
          (!kIsWeb || Navigator.of(context).canPop());
      if (auto) _startRound();
    });
  }

  @override
  void deactivate() {
    MicrophonePitchService.stopListening();
    final session = ref.read(gameSessionProvider);
    if (session.roundsCompleted > 0) {
      ref.read(sessionHistoryProvider.notifier).record(
            mode: session.mode,
            kind: PracticeKind.game,
            roundsCompleted: session.roundsCompleted,
            correctRounds: session.correctRounds,
          );
    }
    clearPracticeFocusNote(ref);
    super.deactivate();
  }

  @override
  void dispose() {
    _listenTimer?.cancel();
    _advanceTimer?.cancel();
    super.dispose();
  }

  // --- Fases ----------------------------------------------------------------

  SessionPhase _phase(GameSessionState session) {
    if (session.isPaused) return SessionPhase.paused;
    switch (session.state) {
      case GameState.idle:
        return _starting ? SessionPhase.listen : SessionPhase.idle;
      case GameState.listening:
        return SessionPhase.listen;
      case GameState.waitingForAnswer:
        return (_holdingListen || _replaying)
            ? SessionPhase.listen
            : SessionPhase.answer;
      case GameState.showingResult:
        return SessionPhase.result;
      case GameState.playingCluster:
        return SessionPhase.cluster;
    }
  }

  void _cancelTimers() {
    _listenTimer?.cancel();
    _listenTimer = null;
    _advanceTimer?.cancel();
    _advanceTimer = null;
  }

  Future<void> _startRound() async {
    final token = ++_roundToken;
    _cancelTimers();
    final audio = ref.read(audioPlayerServiceProvider);
    // En web debe ir de forma síncrona dentro del gesto, antes de cualquier await.
    audio.captureUserGesture();
    setState(() {
      _starting = true;
      _holdingListen = true;
      _replaying = false;
      _selectedNotes.clear();
      _roundStartTime = null;
      _pauseStartedAt = null;
      _accumulatedPause = Duration.zero;
    });
    await audio.waitUntilReady();
    if (!mounted || token != _roundToken) return;
    final started = DateTime.now();
    await ref.read(gameSessionProvider.notifier).startRound();
    if (!mounted || token != _roundToken) return;
    if (ref.read(gameSessionProvider).state != GameState.waitingForAnswer) {
      // El SRS aún no cargó: se vuelve al idle.
      setState(() {
        _starting = false;
        _holdingListen = false;
      });
      return;
    }
    setState(() => _starting = false);
    _holdListenUntilMinimum(started, token);
  }

  /// Mantiene `listen` al menos [DesignTokens.sessionListenDuration].
  void _holdListenUntilMinimum(DateTime started, int token) {
    final remaining =
        DesignTokens.sessionListenDuration - DateTime.now().difference(started);
    void finish() {
      if (!mounted || token != _roundToken) return;
      setState(() {
        _holdingListen = false;
        _replaying = false;
        _roundStartTime = DateTime.now();
        _pauseStartedAt = null;
        _accumulatedPause = Duration.zero;
      });
    }

    if (remaining <= Duration.zero) {
      finish();
    } else {
      _listenTimer?.cancel();
      _listenTimer = Timer(remaining, finish);
    }
  }

  bool _canRepeat(GameSessionState session) =>
      session.state == GameState.waitingForAnswer &&
      !session.isPaused &&
      !_replaying &&
      !_holdingListen;

  /// «Repetir»: vuelve a `listen` con las mismas notas de la ronda.
  Future<void> _replay() async {
    final session = ref.read(gameSessionProvider);
    if (!_canRepeat(session) || session.currentNotes.isEmpty) return;
    final token = _roundToken;
    final audio = ref.read(audioPlayerServiceProvider);
    audio.captureUserGesture();
    setState(() => _replaying = true);
    final started = DateTime.now();
    try {
      await audio.waitUntilReady();
      final prefs = await ref.read(audioPreferencesProvider.future);
      final (frequencies, _) = ref
          .read(audioGeneratorProvider)
          .getNoteFrequencies(
            session.currentNotes,
            varyOctaves: prefs.octaveVariationEnabled,
          );
      audio.setMasterVolume(prefs.masterVolume);
      await audio.playTones(
        frequencies,
        duration: prefs.toneDurationSec,
        instrument: session.lastInstrument ??
            prefs.playbackInstrument(
              sessionOverrideKey: session.sessionInstrumentOverride,
            ),
      );
    } catch (_) {
      // Sin audio disponible: se vuelve a responder igualmente.
    }
    if (!mounted || token != _roundToken) return;
    _holdListenUntilMinimum(started, token);
  }

  /// Mientras suena el audio (estado `listening` del provider) no se puede
  /// saltar: el provider pasaría a `waitingForAnswer` al terminar el audio.
  bool _canSkip(GameSessionState session) =>
      session.state == GameState.waitingForAnswer && !session.isPaused;

  /// «Saltar»: descarta la ronda sin tocar el SRS y empieza la siguiente.
  void _skipRound() {
    final session = ref.read(gameSessionProvider);
    if (session.state != GameState.waitingForAnswer || session.isPaused) {
      return;
    }
    ref.read(gameSessionProvider.notifier).skipRound();
    _startRound();
  }

  void _toggleNote(String note, int required) {
    final session = ref.read(gameSessionProvider);
    if (_phase(session) != SessionPhase.answer) return;
    final next = togglePianoNoteSelection(
      current: _selectedNotes,
      note: note,
      maxNotes: required,
    );
    setState(() {
      _selectedNotes
        ..clear()
        ..addAll(next);
    });
    if (!_uiPrefs().confirmBeforeSubmit &&
        canConfirmPianoSelection(next, required)) {
      _submitNotes(next.toList(), required);
    }
  }

  void _confirmSelection(int required) {
    if (!canConfirmPianoSelection(_selectedNotes, required)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pianoSelectionRequiredMessage(required))),
      );
      return;
    }
    _submitNotes(_selectedNotes.toList(), required);
  }

  double _elapsedResponseTime() {
    final start = _roundStartTime;
    if (start == null) return 0;
    var elapsed = DateTime.now().difference(start) - _accumulatedPause;
    if (_pauseStartedAt != null) {
      elapsed -= DateTime.now().difference(_pauseStartedAt!);
    }
    return elapsed.inMilliseconds / 1000.0;
  }

  void _submitNotes(List<String> notes, int required) {
    if (_roundStartTime == null) return;
    if (notes.length != required) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pianoSelectionRequiredMessage(required))),
      );
      return;
    }
    ref
        .read(gameSessionProvider.notifier)
        .submitAnswer(notes, _elapsedResponseTime());
    setState(() {
      _selectedNotes.clear();
      _pauseStartedAt = null;
      _accumulatedPause = Duration.zero;
    });
  }

  /// Siguiente ronda tras `result` (automático o manual).
  Future<void> _advance() async {
    final session = ref.read(gameSessionProvider);
    if (session.state != GameState.showingResult || session.goalReached) {
      return;
    }
    _cancelTimers();
    final token = ++_roundToken;
    setState(() => _starting = true);
    await ref.read(gameSessionProvider.notifier).playCluster();
    if (!mounted || token != _roundToken) return;
    await _startRound();
  }

  void _pauseRound() {
    if (_pauseStartedAt != null) return;
    ref.read(gameSessionProvider.notifier).pauseRound();
    setState(() => _pauseStartedAt = DateTime.now());
  }

  void _resumeRound() {
    if (_pauseStartedAt != null) {
      setState(() {
        _accumulatedPause += DateTime.now().difference(_pauseStartedAt!);
        _pauseStartedAt = null;
      });
    }
    ref.read(gameSessionProvider.notifier).resumeRound();
  }

  void _onBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    GoRouter.maybeOf(context)?.go(AppRoutes.home);
  }

  void _onResultShown(GameSessionState session) {
    final result = session.lastResult;
    if (result == null) return;
    _announceResult(session);
    final autoAdvance = _sessionPrefs().autoAdvanceAfterResult;
    if (!autoAdvance || session.goalReached) return;
    _advanceTimer?.cancel();
    _advanceTimer = Timer(_autoAdvanceDelay(), () {
      if (!mounted) return;
      _advance();
    });
  }

  /// La región viva del anillo cubre web y Android; iOS y escritorio no
  /// leen `liveRegion`, así que ahí se envía además un anuncio explícito.
  void _announceResult(GameSessionState session) {
    final platform = defaultTargetPlatform;
    if (kIsWeb ||
        platform == TargetPlatform.android ||
        platform == TargetPlatform.fuchsia) {
      return;
    }
    final copy = sessionPhaseCopy(_phaseContext(session, SessionPhase.result));
    SemanticsService.sendAnnouncement(
      View.of(context),
      copy.announcement,
      Directionality.of(context),
    );
  }

  // --- Copy -----------------------------------------------------------------

  NoteNamingMode _namingMode() =>
      ref.read(noteNamingModeProvider).valueOrNull ?? NoteNamingMode.letter;

  String _label(String note) => formatNoteLabel(note, _namingMode());

  List<String> _sortedLabels(Iterable<String> notes) {
    const order = [
      'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', //
    ];
    final list = notes.toList()
      ..sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
    return list.map(_label).toList();
  }

  /// «Piano · octava 4 · 1 nota». Solo datos reales (D10): el instrumento si
  /// está fijo y la octava solo si no varía.
  String _listenDetail(GameSessionState session) {
    final prefs = ref.read(audioPreferencesProvider).valueOrNull ??
        const AudioPreferences();
    final parts = <String>[];
    final id = prefs.playbackInstrument(
      sessionOverrideKey: session.sessionInstrumentOverride,
    );
    if (id != null) parts.add(instrumentLabel(id));
    if (!prefs.octaveVariationEnabled) parts.add('octava 4');
    final n = _requiredNotes(session);
    parts.add(n == 1 ? '1 nota' : '$n notas');
    return parts.join(' · ');
  }

  SessionPhaseContext _phaseContext(
    GameSessionState session,
    SessionPhase phase,
  ) {
    final ui = _uiPrefs();
    final result = session.lastResult;
    return SessionPhaseContext(
      phase: phase,
      requiredNotes: _requiredNotes(session),
      listenDetail: _listenDetail(session),
      confirmMode: ui.confirmBeforeSubmit,
      textOnly: ui.inputMode == GameInputMode.textOnly,
      isCorrect: result?.isCorrect,
      correctLabels:
          result == null ? const [] : _sortedLabels(result.correctNotes),
      answerLabels: result == null
          ? const []
          : result.answerNotes.map(_label).toList(),
      autoAdvance: _sessionPrefs().autoAdvanceAfterResult,
      goalReached: session.goalReached,
      targetRounds: _sessionPrefs().targetRounds,
    );
  }

  String _keyboardPrompt(SessionPhase phase, int required, UiPreferences ui) {
    switch (phase) {
      case SessionPhase.answer:
        if (ui.inputMode == GameInputMode.textOnly) {
          return 'Escribe tu respuesta debajo';
        }
        if (ui.inputMode == GameInputMode.humming) {
          return 'Canta o tararea la nota';
        }
        return required == 1
            ? 'Toca la tecla que escuchaste'
            : 'Toca las $required teclas que escuchaste';
      case SessionPhase.listen:
        return 'Escucha primero…';
      case SessionPhase.result:
        return 'Respuesta marcada sobre el teclado';
      case SessionPhase.cluster:
        return 'Preparando la siguiente ronda…';
      case SessionPhase.paused:
        return 'Sesión en pausa';
      case SessionPhase.idle:
        return 'Pulsa «Empezar» para oír la primera nota';
    }
  }

  // --- Atajos ---------------------------------------------------------------

  void _onShortcutNote(String note) {
    final session = ref.read(gameSessionProvider);
    if (_phase(session) != SessionPhase.answer) return;
    if (_uiPrefs().inputMode == GameInputMode.humming) return;
    _toggleNote(note, _requiredNotes(session));
  }

  void _onShortcutNext() {
    final session = ref.read(gameSessionProvider);
    switch (_phase(session)) {
      case SessionPhase.idle:
        _startRound();
      case SessionPhase.result:
        _advance();
      case SessionPhase.answer:
      case SessionPhase.listen:
        _skipRound();
      case SessionPhase.paused:
        _resumeRound();
      case SessionPhase.cluster:
        break;
    }
  }

  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    ref.watch(uiPreferencesProvider);
    ref.watch(practiceSessionPreferencesProvider);
    ref.watch(audioPreferencesProvider);
    ref.watch(noteNamingModeProvider);
    ref.listen<GameSessionState>(gameSessionProvider, (previous, next) {
      final becameResult = next.state == GameState.showingResult &&
          (previous?.state != GameState.showingResult ||
              !identical(previous?.lastResult, next.lastResult));
      if (becameResult) _onResultShown(next);
    });

    return Theme(
      data: AppTheme.session,
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: DesignTokens.sessionBackground,
            body: SafeArea(
              child: SessionShortcuts(
                onNote: _onShortcutNote,
                onRepeat: _replay,
                onNext: _onShortcutNext,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >=
                        DesignTokens.desktopBreakpoint) {
                      return _buildDesktop(context, session);
                    }
                    return _buildMobile(context, session, constraints);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  SessionStats _stats(GameSessionState session) => SessionStats(
        round: _displayRound(session),
        targetRounds: _sessionPrefs().targetRounds,
        accuracyPercent: session.sessionAccuracyPercent,
        streak: session.currentStreak,
      );

  Widget _pauseButton(GameSessionState session, {bool showLabel = false}) {
    final phase = _phase(session);
    return SessionPauseButton(
      isPaused: session.isPaused,
      enabled: phase == SessionPhase.answer || phase == SessionPhase.paused,
      onPause: _pauseRound,
      onResume: _resumeRound,
      showLabel: showLabel,
    );
  }

  Widget _instrumentButton(GameSessionState session, {bool showLabel = false}) {
    return SessionInstrumentButton(
      sessionInstrumentOverride: session.sessionInstrumentOverride,
      showLabel: showLabel,
      onOverrideChanged: (key) =>
          ref.read(gameSessionProvider.notifier).setSessionInstrumentOverride(
                key,
              ),
    );
  }

  Widget? _ringFooter(GameSessionState session, SessionPhase phase) {
    final ui = _uiPrefs();
    final required = _requiredNotes(session);
    final amber = FilledButton.styleFrom(
      backgroundColor: DesignTokens.sessionAmber,
      foregroundColor: DesignTokens.sessionOnAccent,
      minimumSize: const Size(160, DesignTokens.touchTargetMin),
      shape: RoundedRectangleBorder(borderRadius: DesignTokens.borderRadiusCta),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
    );
    switch (phase) {
      case SessionPhase.idle:
        return FilledButton.icon(
          onPressed: _startRound,
          style: amber.copyWith(
            minimumSize: const WidgetStatePropertyAll(
              Size(200, DesignTokens.ctaHeight),
            ),
          ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Empezar'),
        );
      case SessionPhase.paused:
        return FilledButton.icon(
          onPressed: _resumeRound,
          style: amber,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Reanudar'),
        );
      case SessionPhase.answer:
        final pianoInput = ui.inputMode == GameInputMode.pianoOnly ||
            ui.inputMode == GameInputMode.both;
        if (!ui.confirmBeforeSubmit || !pianoInput) return null;
        return FilledButton.icon(
          onPressed: _selectedNotes.isEmpty
              ? null
              : () => _confirmSelection(required),
          style: amber,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Confirmar'),
        );
      case SessionPhase.result:
        final pills = _srsPills(session);
        final Widget? action;
        if (session.goalReached) {
          action = FilledButton.icon(
            onPressed: _onBack,
            style: amber,
            icon: const Icon(Icons.home_rounded),
            label: const Text('Volver al inicio'),
          );
        } else if (!_sessionPrefs().autoAdvanceAfterResult) {
          action = FilledButton.icon(
            onPressed: _advance,
            style: amber,
            icon: const Icon(Icons.skip_next_rounded),
            label: const Text('Siguiente ronda'),
          );
        } else {
          action = null;
        }
        if (pills.isEmpty && action == null) return null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pills.isNotEmpty)
              Wrap(
                spacing: DesignTokens.spacingSm,
                runSpacing: DesignTokens.spacingSm,
                alignment: WrapAlignment.center,
                children: pills,
              ),
            if (pills.isNotEmpty && action != null)
              const SizedBox(height: DesignTokens.spacingLg),
            ?action,
          ],
        );
      case SessionPhase.listen:
      case SessionPhase.cluster:
        return null;
    }
  }

  List<Widget> _srsPills(GameSessionState session) {
    final result = session.lastResult;
    if (result == null) return const [];
    final threshold = ref.read(srsLearningThresholdProvider);
    final ordered = <String>[
      ...result.correctNotes,
      ...result.srsChanges.keys.where((n) => !result.correctNotes.contains(n)),
    ];
    final pills = <Widget>[];
    for (final note in ordered) {
      final change = srsLevelChangeFromSrsChange(
        result.srsChanges[note],
        learningThreshold: threshold,
      );
      if (change == null) continue;
      pills.add(
        SrsLevelPill(
          key: ValueKey('srs-pill-$note'),
          noteLabel: _label(note),
          change: change,
        ),
      );
      if (pills.length == 3) break;
    }
    return pills;
  }

  Widget _ring(GameSessionState session, {required double size}) {
    final phase = _phase(session);
    final result = session.lastResult;
    return SessionPhaseRing(
      phase: phase,
      size: size,
      reduceMotion: _reduceMotion(),
      copy: sessionPhaseCopy(_phaseContext(session, phase)),
      noteLabel: phase == SessionPhase.result && result != null
          ? _sortedLabels(result.correctNotes).join(' · ')
          : null,
      footer: _ringFooter(session, phase),
    );
  }

  Widget _keyActions(GameSessionState session) {
    final phase = _phase(session);
    final ui = _uiPrefs();
    return SessionKeyActions(
      prompt: _keyboardPrompt(phase, _requiredNotes(session), ui),
      onRepeat: _canRepeat(session) ? _replay : null,
      onSkip: _canSkip(session) ? _skipRound : null,
    );
  }

  /// Entrada de respuesta: piano (por defecto, D6), texto o micrófono.
  Widget _answerInput(
    GameSessionState session, {
    required PianoKeyboardVariant variant,
  }) {
    final ui = _uiPrefs();
    final phase = _phase(session);
    final required = _requiredNotes(session);
    final namingMode = _namingMode();
    final result = phase == SessionPhase.result ? session.lastResult : null;
    final showMic = ui.inputMode == GameInputMode.humming;
    final showPiano = !showMic && ui.inputMode != GameInputMode.textOnly;
    final showText = !showMic && ui.inputMode != GameInputMode.pianoOnly;
    final answering = phase == SessionPhase.answer;

    final children = <Widget>[];
    if (showPiano) {
      children.add(
        Center(
          child: PianoKeyboard(
            variant: variant,
            selectedNotes: result == null ? _selectedNotes : const {},
            correctNotes: result?.correctNotes ?? const {},
            incorrectNotes: result?.wrongNotes ?? const {},
            dimOthers: true,
            disabled: !answering,
            onNoteTapped: (note) => _toggleNote(note, required),
            noteNamingMode: namingMode,
            hideLabels: ui.hidePianoLabels,
          ),
        ),
      );
    }
    if (showMic && answering) {
      children.add(
        MicrophoneAnswerPanel(
          requiredNotes: required,
          onNoteDetected: (note) => _toggleNote(note, required),
          onSubmit: () => _confirmSelection(required),
        ),
      );
    }
    if (showText) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: DesignTokens.spacingMd));
      }
      children.add(
        NoteInputField(
          enabled: answering,
          onSubmitted: (notes) => _submitNotes(notes, required),
          hintText: namingMode == NoteNamingMode.solfege
              ? 'Escribe notas (Do, Re, Mi…)'
              : 'Escribe notas (C, E, G…)',
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _scrollCenter(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingLg),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - DesignTokens.spacingLg * 2)
                .clamp(0.0, double.infinity),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildMobile(
    BuildContext context,
    GameSessionState session,
    BoxConstraints constraints,
  ) {
    final stats = _stats(session);
    final compactLandscape = constraints.maxWidth >= 600 &&
        constraints.maxHeight < 560;
    final topBar = SessionTopBar(
      stats: stats,
      onBack: _onBack,
      instrumentButton: _instrumentButton(session),
      pauseButton: _pauseButton(session),
    );
    final progress = Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.marginMobile),
      child: SessionProgressBar(progress: stats.progress),
    );
    final ring = Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.marginMobile),
      child: _ring(session, size: DesignTokens.sessionRingSize),
    );
    final keyboardBlock = Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.marginMobile,
        0,
        DesignTokens.marginMobile,
        DesignTokens.marginMobile,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _keyActions(session),
          const SizedBox(height: DesignTokens.spacingSm),
          _answerInput(session, variant: PianoKeyboardVariant.session),
        ],
      ),
    );

    if (compactLandscape) {
      return Column(
        children: [
          topBar,
          progress,
          Expanded(
            child: Row(
              children: [
                Expanded(child: _scrollCenter(ring)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: DesignTokens.spacingSm),
                    child: keyboardBlock,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          children: [
            topBar,
            progress,
            Expanded(child: _scrollCenter(ring)),
            keyboardBlock,
          ],
        ),
      ),
    );
  }

  /// Notas del panel: el foco con el que se abrió la sesión (nota única o
  /// las de la «Sesión de hoy») o, si no hay, las que propone el SRS hoy.
  /// El foco se captura al iniciar: `deactivate` lo limpia y vigilarlo
  /// marcaría la pantalla como sucia durante el desmontaje.
  List<String> _focusNotes() {
    final captured = _sessionFocusNotes;
    if (captured != null && captured.isNotEmpty) return captured;
    return ref.watch(todayFocusNotesProvider).map((f) => f.note).toList();
  }

  Widget _buildDesktop(BuildContext context, GameSessionState session) {
    final stats = _stats(session);
    final entries = buildSessionFocusEntries(
      notes: _focusNotes(),
      summaries: ref.watch(noteProgressSummariesProvider),
      criticalNotes: criticalNotesFromRecommendations(
        ref.watch(practiceRecommendationsProvider),
      ).map((e) => e.$1).toSet(),
      learningThreshold: ref.watch(srsLearningThresholdProvider),
    );
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.marginDesktop),
      child: Column(
        children: [
          SessionDesktopHeader(
            modeName: widget.mode.displayName,
            stats: stats,
            onBack: _onBack,
            instrumentButton: _instrumentButton(session, showLabel: true),
            pauseButton: _pauseButton(session, showLabel: true),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          SessionProgressBar(progress: stats.progress),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _scrollCenter(
                    _ring(session, size: DesignTokens.sessionRingSizeDesktop),
                  ),
                ),
                const SizedBox(width: DesignTokens.marginDesktop),
                Align(
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.spacingLg,
                    ),
                    child: SessionSrsPanel(
                      entries: entries,
                      formatNote: _label,
                      solfegeNames: _namingMode() == NoteNamingMode.solfege,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _keyActions(session),
                const SizedBox(height: DesignTokens.spacingSm),
                _answerInput(session, variant: PianoKeyboardVariant.sessionWide),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
