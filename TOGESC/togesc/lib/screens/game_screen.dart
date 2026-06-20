import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../constants/game_constants.dart';
import '../constants/note_naming.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/game_session_provider.dart';
import '../providers/practice_focus_provider.dart';
import '../models/ui_preferences.dart';
import '../providers/practice_session_preferences_provider.dart';
import '../models/last_practice_session.dart';
import '../providers/session_history_provider.dart';
import '../providers/ui_preferences_provider.dart';
import '../utils/piano_note_selection.dart';
import '../widgets/game_session_views.dart';
import '../widgets/note_input_field.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/result_card.dart';
import '../widgets/togesc_ui.dart';

/// Pantalla principal del juego.
///
/// Flujo: idle -> escuchar -> seleccionar notas -> confirmar -> resultado -> cluster -> idle
class GameScreen extends ConsumerStatefulWidget {
  final GameMode mode;

  const GameScreen({super.key, required this.mode});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final _selectedNotes = <String>{};
  DateTime? _roundStartTime;
  DateTime? _pauseStartedAt;
  Duration _accumulatedPause = Duration.zero;
  bool _autoContinueScheduled = false;

  Duration _autoAdvanceDelay() {
    final reduce = ref.read(uiPreferencesProvider).valueOrNull?.reduceAnimations ??
        false;
    return Duration(milliseconds: reduce ? 400 : 1800);
  }

  UiPreferences _uiPrefs() {
    return ref.read(uiPreferencesProvider).valueOrNull ?? const UiPreferences();
  }

  int _requiredNotes(GameSessionState session) {
    return selectableNoteCount(
      screenMode: widget.mode,
      sessionNumNotes: session.numNotes,
    );
  }

  int _targetRounds() {
    return ref
            .read(practiceSessionPreferencesProvider)
            .valueOrNull
            ?.targetRounds ??
        0;
  }

  int _displayRound(GameSessionState session) {
    if (session.state == GameState.showingResult) {
      return session.roundsCompleted;
    }
    return session.roundsCompleted + 1;
  }

  @override
  void deactivate() {
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameSessionProvider.notifier).setMode(widget.mode);
    });
  }

  void _toggleNote(String note, int maxNotes) {
    final next = togglePianoNoteSelection(
      current: _selectedNotes,
      note: note,
      maxNotes: maxNotes,
    );
    setState(() {
      _selectedNotes
        ..clear()
        ..addAll(next);
    });
    _maybeAutoSubmit(next, maxNotes);
  }

  void _maybeAutoSubmit(Set<String> notes, int required) {
    if (!_uiPrefs().confirmBeforeSubmit &&
        canConfirmPianoSelection(notes, required)) {
      _submitNotes(notes.toList(), required);
    }
  }

  double _elapsedResponseTime() {
    if (_roundStartTime == null) return 0;
    var elapsed = DateTime.now().difference(_roundStartTime!);
    if (ref.read(gameSessionProvider).isPaused && _pauseStartedAt != null) {
      elapsed -= DateTime.now().difference(_pauseStartedAt!);
    }
    elapsed -= _accumulatedPause;
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

  void _confirmSelection(int required) {
    if (!canConfirmPianoSelection(_selectedNotes, required)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pianoSelectionRequiredMessage(required))),
      );
      return;
    }
    _submitNotes(_selectedNotes.toList(), required);
  }

  Future<void> _startRound() async {
    final audio = ref.read(audioPlayerServiceProvider);
    audio.captureUserGesture();
    await audio.waitUntilReady();

    setState(() {
      _selectedNotes.clear();
      _roundStartTime = DateTime.now();
      _pauseStartedAt = null;
      _accumulatedPause = Duration.zero;
      _autoContinueScheduled = false;
    });
    await ref.read(gameSessionProvider.notifier).startRound();
    setState(() => _roundStartTime = DateTime.now());
  }

  Future<void> _continueAfterResult() async {
    if (ref.read(gameSessionProvider).goalReached) return;

    final audio = ref.read(audioPlayerServiceProvider);
    audio.captureUserGesture();
    await audio.waitUntilReady();
    await ref.read(gameSessionProvider.notifier).playCluster();
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

  void _skipRound() {
    ref.read(gameSessionProvider.notifier).skipRound();
    setState(() {
      _selectedNotes.clear();
      _roundStartTime = null;
      _pauseStartedAt = null;
      _accumulatedPause = Duration.zero;
    });
  }

  void _maybeScheduleAutoContinue(GameSessionState session) {
    if (_autoContinueScheduled ||
        session.state != GameState.showingResult ||
        session.goalReached) {
      return;
    }

    final autoAdvance = ref
            .read(practiceSessionPreferencesProvider)
            .valueOrNull
            ?.autoAdvanceAfterResult ??
        false;
    if (!autoAdvance) return;

    _autoContinueScheduled = true;
    Future<void>.delayed(_autoAdvanceDelay(), () async {
      if (!mounted) return;
      final current = ref.read(gameSessionProvider);
      if (current.state != GameState.showingResult || current.goalReached) {
        return;
      }
      await _continueAfterResult();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    ref.listen<GameSessionState>(gameSessionProvider, (previous, next) {
      _maybeScheduleAutoContinue(next);
    });

    final targetRounds = _targetRounds();

    return TogescScaffold(
      title: widget.mode.displayName,
      actions: [
        GameInstrumentToggleAction(
          sessionInstrumentOverride: session.sessionInstrumentOverride,
          onOverrideChanged: (key) => ref
              .read(gameSessionProvider.notifier)
              .setSessionInstrumentOverride(key),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(DesignTokens.marginMobile),
        child: Column(
          children: [
            if (targetRounds > 0 &&
                session.state != GameState.idle &&
                !session.goalReached) ...[
              GameSessionProgressBar(
                roundsCompleted: _displayRound(session),
                targetRounds: targetRounds,
              ),
              const SizedBox(height: DesignTokens.spacingMd),
            ],
            Expanded(child: _buildContent(session, targetRounds)),
            if (session.state == GameState.showingResult)
              _buildResultActions(session),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(GameSessionState session, int targetRounds) {
    if (session.isPaused && session.state == GameState.waitingForAnswer) {
      return GameSessionPausedOverlay(onResume: _resumeRound);
    }

    switch (session.state) {
      case GameState.idle:
        return GameSessionIdleView(onPlay: _startRound);
      case GameState.listening:
        return Column(
          children: [
            Expanded(
              child: GameSessionListeningView(
                numNotes: _requiredNotes(session),
              ),
            ),
            GameSessionRoundControls(
              isPaused: false,
              onPause: () {},
              onResume: () {},
              onSkip: _skipRound,
              showPause: false,
            ),
          ],
        );
      case GameState.waitingForAnswer:
        return _buildAnswerView(session);
      case GameState.showingResult:
        return _buildResultView(session, targetRounds);
      case GameState.playingCluster:
        return const GameSessionClusterView();
    }
  }

  Widget _buildAnswerView(GameSessionState session) {
    final namingMode =
        ref.watch(noteNamingModeProvider).valueOrNull ?? NoteNamingMode.letter;
    final ui = ref.watch(uiPreferencesProvider).valueOrNull ?? const UiPreferences();
    final required = _requiredNotes(session);
    final hint = namingMode == NoteNamingMode.solfege
        ? 'O escribe aqui: Do Re Mi'
        : 'O escribe aqui: C E G';
    final showPiano = ui.inputMode != GameInputMode.textOnly;
    final showText = ui.inputMode != GameInputMode.pianoOnly;
    final showConfirm = ui.confirmBeforeSubmit && showPiano;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameSessionAnswerHeader(numNotes: required),
          if (showPiano) ...[
            const SizedBox(height: DesignTokens.spacingSm),
            Text(
              '${_selectedNotes.length}/$required notas seleccionadas',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: DesignTokens.spacingLg),
            TogescCard(
              padding: const EdgeInsets.all(DesignTokens.spacingMd),
              child: Center(
                child: PianoKeyboard(
                  selectedNotes: _selectedNotes,
                  onNoteTapped: (note) => _toggleNote(note, required),
                  noteNamingMode: namingMode,
                  large: ui.largePiano,
                  hideLabels: ui.hidePianoLabels,
                ),
              ),
            ),
            if (_selectedNotes.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.spacingMd),
              Wrap(
                spacing: DesignTokens.spacingSm,
                runSpacing: DesignTokens.spacingSm,
                alignment: WrapAlignment.center,
                children: _selectedNotes.map((note) {
                  return InputChip(
                    label: Text(note),
                    onDeleted: () => _toggleNote(note, required),
                    deleteIconColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    backgroundColor: DesignTokens.selection.withValues(alpha: 0.15),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: DesignTokens.spacingLg),
            GameSessionRoundControls(
              isPaused: session.isPaused,
              onPause: _pauseRound,
              onResume: _resumeRound,
              onSkip: _skipRound,
            ),
            const SizedBox(height: DesignTokens.spacingMd),
          ],
          if (showPiano) ...[
            Row(
              children: [
                if (showConfirm)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _selectedNotes.isEmpty
                          ? null
                          : () => _confirmSelection(required),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Confirmar'),
                    ),
                  ),
                if (showConfirm) const SizedBox(width: DesignTokens.spacingMd),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _startRound,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Repetir'),
                  ),
                ),
              ],
            ),
            if (showText) const SizedBox(height: DesignTokens.spacingLg),
          ],
          if (showText)
            NoteInputField(
              onSubmitted: (notes) => _submitNotes(notes, required),
              hintText: hint,
            ),
          if (!showPiano && showText) ...[
            const SizedBox(height: DesignTokens.spacingMd),
            OutlinedButton.icon(
              onPressed: _startRound,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Repetir'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultView(GameSessionState session, int targetRounds) {
    final result = session.lastResult;
    if (result == null) return const SizedBox.shrink();

    final correctSet = result.correctNotes;
    final incorrectSet = _selectedNotes.difference(correctSet);
    final namingMode =
        ref.watch(noteNamingModeProvider).valueOrNull ?? NoteNamingMode.letter;
    final ui = ref.watch(uiPreferencesProvider).valueOrNull ?? const UiPreferences();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (session.goalReached && targetRounds > 0) ...[
            GameSessionGoalCompleteBanner(targetRounds: targetRounds),
            const SizedBox(height: DesignTokens.spacingMd),
          ],
          TogescCard(
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            child: Center(
              child: PianoKeyboard(
                correctNotes: correctSet,
                incorrectNotes: incorrectSet,
                disabled: true,
                noteNamingMode: namingMode,
                large: ui.largePiano,
                hideLabels: ui.hidePianoLabels,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          ResultCard(
            isCorrect: result.isCorrect,
            correctNotes: result.correctNotes,
            responseTime: result.responseTime,
            srsChanges: result.srsChanges,
          ),
        ],
      ),
    );
  }

  Widget _buildResultActions(GameSessionState session) {
    if (session.goalReached) {
      return Padding(
        padding: const EdgeInsets.only(top: DesignTokens.spacingSm),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.home_rounded),
            label: const Text('Volver al inicio'),
          ),
        ),
      );
    }

    final autoAdvance = ref
            .watch(practiceSessionPreferencesProvider)
            .valueOrNull
            ?.autoAdvanceAfterResult ??
        false;

    if (autoAdvance) {
      return Padding(
        padding: const EdgeInsets.only(top: DesignTokens.spacingSm),
        child: Text(
          'Siguiente ronda en breve...',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DesignTokens.onSurfaceVariant,
              ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.spacingSm),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _continueAfterResult,
          icon: const Icon(Icons.skip_next_rounded),
          label: const Text('Siguiente'),
        ),
      ),
    );
  }
}
