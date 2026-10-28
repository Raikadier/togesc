import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_theme.dart';
import '../app/design_tokens.dart';
import '../app/togesc_colors.dart';
import '../constants/game_constants.dart';
import '../constants/note_naming.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/audio_provider.dart';
import '../models/last_practice_session.dart';
import '../models/ui_preferences.dart';
import '../providers/session_history_provider.dart';
import '../providers/speed_best_streak_provider.dart';
import '../providers/speed_difficulty_provider.dart';
import '../providers/speed_session_provider.dart';
import '../providers/ui_preferences_provider.dart';
import '../utils/piano_note_selection.dart';
import '../widgets/countdown_timer_widget.dart';
import '../widgets/game_session_views.dart';
import '../widgets/note_input_field.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/speed_session_views.dart';
import '../widgets/togesc_ui.dart';

/// Pantalla del juego de velocidad con countdown.
///
/// Usa el tema oscuro forzado de la sesión v2 (`AppTheme.session`), igual
/// que la sesión normal: la práctica siempre se hace «en el instrumento».
class SpeedGameScreen extends ConsumerStatefulWidget {
  final GameMode targetMode;

  const SpeedGameScreen({super.key, required this.targetMode});

  @override
  ConsumerState<SpeedGameScreen> createState() => _SpeedGameScreenState();
}

class _SpeedGameScreenState extends ConsumerState<SpeedGameScreen> {
  final _selectedNotes = <String>{};
  DateTime? _roundStartTime;

  /// Dificultad con la que se abrió la pantalla (para la mejor racha).
  late final SpeedDifficulty _difficulty;

  /// Cifra de la cuenta atrás 3-2-1 (null fuera de la cuenta atrás).
  int? _countdown;
  Timer? _countdownTimer;

  /// La última ráfaga cerrada batió la mejor racha de [_difficulty].
  bool _newRecord = false;

  /// Destello de fondo tras cada respuesta (SPEC §2.4.2).
  int _flashId = 0;
  bool _flashCorrect = true;

  int _requiredNotes(SpeedSessionState session) {
    return selectableNoteCount(
      screenMode: widget.targetMode,
      sessionNumNotes: session.numNotes,
    );
  }

  @override
  void initState() {
    super.initState();
    _difficulty = ref.read(speedDifficultyProvider);
    ref.listenManual(speedSessionProvider, _onSessionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(speedSessionProvider.notifier)
          .setTargetMode(
            widget.targetMode,
            initialTime: _difficulty.initialTime,
          );
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Destello verde o rojo con cada respuesta y, al cerrar la ráfaga, la
  /// mejor racha por dificultad. Las reglas siguen en el provider (§2.4.4).
  void _onSessionChanged(SpeedSessionState? prev, SpeedSessionState next) {
    if (prev?.state == next.state) return;
    final closed =
        next.state == SpeedState.incorrect || next.state == SpeedState.timeout;
    if (next.state == SpeedState.correct || closed) {
      setState(() {
        _flashId++;
        _flashCorrect = next.state == SpeedState.correct;
      });
    }
    if (closed) unawaited(_recordBest(next.consecutiveCorrect));
  }

  Future<void> _recordBest(int streak) async {
    final record = await ref
        .read(speedBestStreakProvider.notifier)
        .submit(_difficulty, streak);
    if (mounted && record) setState(() => _newRecord = true);
  }

  /// Cuenta atrás 3-2-1 con un clic sutil (más agudo en el 1) y, al
  /// terminar, la primera ráfaga.
  void _beginCountdown() {
    final audio = ref.read(audioPlayerServiceProvider);
    audio.captureUserGesture();
    _countdownTimer?.cancel();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final step = Duration(milliseconds: reduced ? 500 : 800);
    setState(() {
      _newRecord = false;
      _countdown = 3;
    });
    _playClick(3);
    _countdownTimer = Timer.periodic(step, (timer) {
      if (!mounted) return timer.cancel();
      final next = (_countdown ?? 1) - 1;
      if (next <= 0) {
        timer.cancel();
        setState(() => _countdown = null);
        _startRound();
        return;
      }
      setState(() => _countdown = next);
      _playClick(next);
    });
  }

  void _playClick(int value) {
    final audio = ref.read(audioPlayerServiceProvider);
    final tone = audio.generator.generateTone(
      value == 1 ? 1046.5 : 523.25,
      duration: 0.08,
    );
    unawaited(
      audio.playBuffer(Float64List.fromList([for (final x in tone) x * 0.3])),
    );
  }

  @override
  void deactivate() {
    final session = ref.read(speedSessionProvider);
    if (session.roundsPlayed > 0) {
      ref
          .read(sessionHistoryProvider.notifier)
          .record(
            mode: session.targetMode,
            kind: PracticeKind.speed,
            roundsCompleted: session.roundsPlayed,
            correctRounds: session.correctRounds,
          );
    }
    super.deactivate();
  }

  void _toggleNote(String note, int maxNotes) {
    setState(() {
      _selectedNotes
        ..clear()
        ..addAll(
          togglePianoNoteSelection(
            current: _selectedNotes,
            note: note,
            maxNotes: maxNotes,
          ),
        );
    });
  }

  void _submitNotes(List<String> notes, int required) {
    if (_roundStartTime == null) return;
    if (notes.length != required) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pianoSelectionRequiredMessage(required))),
      );
      return;
    }
    final responseTime =
        DateTime.now().difference(_roundStartTime!).inMilliseconds / 1000.0;
    ref.read(speedSessionProvider.notifier).submitAnswer(notes, responseTime);
    setState(() => _selectedNotes.clear());
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
    });
    await ref.read(speedSessionProvider.notifier).startRound();
    setState(() => _roundStartTime = DateTime.now());
  }

  void _retrySession() {
    ref.read(speedSessionProvider.notifier).retry();
    _beginCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(speedSessionProvider);
    final showMetrics = session.state != SpeedState.idle;

    return Theme(
      data: AppTheme.session,
      // El Builder da un contexto bajo el tema de sesión a todo el contenido
      // (TogescColors y colorScheme de sesión).
      child: Builder(
        builder: (context) => _buildScaffold(context, session, showMetrics),
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    SpeedSessionState session,
    bool showMetrics,
  ) {
    return TogescScaffold(
      title: 'Velocidad · ${widget.targetMode.displayName}',
      actions: [
        GameInstrumentToggleAction(
          sessionInstrumentOverride: session.sessionInstrumentOverride,
          onOverrideChanged: (key) => ref
              .read(speedSessionProvider.notifier)
              .setSessionInstrumentOverride(key),
        ),
      ],
      body: Column(
        children: [
          if (showMetrics)
            TogescSpeedMetricsBar(
              streak: session.consecutiveCorrect,
              timeLimit: session.currentTimeLimit,
              averageTime: session.responseTimes.isEmpty
                  ? null
                  : session.averageTime,
            ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _AnswerFlash(
                    key: ValueKey('speed-flash-$_flashId'),
                    active: _flashId > 0,
                    color: _flashCorrect
                        ? TogescColors.of(context).correct
                        : TogescColors.of(context).incorrect,
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.all(
                      MediaQuery.sizeOf(context).width >=
                              DesignTokens.shellBreakpoint
                          ? DesignTokens.marginDesktop
                          : DesignTokens.marginMobile,
                    ),
                    child: AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : DesignTokens.motionMedium,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final offset = Tween<Offset>(
                          begin: const Offset(0, 0.04),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: offset,
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(session.state.name),
                        child: _buildContent(context, session),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, SpeedSessionState session) {
    switch (session.state) {
      case SpeedState.idle:
        if (_countdown case final int value) {
          return SpeedCountdownView(
            value: value,
            difficultyLabel: _difficulty.label,
          );
        }
        return SpeedSessionIdleView(
          onStart: _beginCountdown,
          initialTime: session.sessionInitialTime,
        );
      case SpeedState.playing:
        return SpeedSessionListeningView(numNotes: _requiredNotes(session));
      case SpeedState.waitingForAnswer:
        return _buildAnswerView(context, session);
      case SpeedState.correct:
        return _buildCorrectView(context, session);
      case SpeedState.incorrect:
        return _buildIncorrectView(context, session);
      case SpeedState.timeout:
        return _buildTimeoutView(context, session);
      case SpeedState.gameOver:
        return _buildGameOverView(context, session);
    }
  }

  Widget _buildAnswerView(BuildContext context, SpeedSessionState session) {
    final namingMode =
        ref.watch(noteNamingModeProvider).valueOrNull ?? NoteNamingMode.letter;
    final required = _requiredNotes(session);
    final ui =
        ref.watch(uiPreferencesProvider).valueOrNull ?? const UiPreferences();
    final hint = namingMode == NoteNamingMode.solfege
        ? 'Do Re Mi o C E G'
        : 'C E G o Do Re Mi';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CountdownTimerWidget(
              remainingTime: session.remainingTime,
              totalTime: session.currentTimeLimit,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          SpeedSessionAnswerHeader(numNotes: required),
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            '${_selectedNotes.length}/$required notas seleccionadas',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )
                .merge(DesignTokens.tabularNumbers),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          Center(
            child: PianoKeyboard(
              selectedNotes: _selectedNotes,
              onNoteTapped: (note) => _toggleNote(note, required),
              noteNamingMode: namingMode,
              variant: PianoKeyboardVariant.session,
              large: ui.largePiano,
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
                  // `primaryContainer` es #2A0640 en la sesión (1,2:1 sobre
                  // el fondo): borde e icono van en el ámbar de selección.
                  deleteIconColor: TogescColors.of(context).selection,
                  side: BorderSide(
                    color: TogescColors.of(context).selection,
                    width: 2,
                  ),
                  backgroundColor: TogescColors.of(
                    context,
                  ).selection.withValues(alpha: 0.15),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: DesignTokens.spacingLg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _selectedNotes.isEmpty
                  ? null
                  : () => _confirmSelection(required),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Confirmar'),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          NoteInputField(
            onSubmitted: (notes) => _submitNotes(notes, required),
            hintText: hint,
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectView(BuildContext context, SpeedSessionState session) {
    return SpeedSessionFeedbackView(
      icon: Icons.check_circle_rounded,
      accentColor: TogescColors.of(context).correct,
      title: 'Correcto',
      subtitle:
          'Tiempo límite: ${session.currentTimeLimit.toStringAsFixed(1)}s',
      footer: FilledButton.icon(
        onPressed: _startRound,
        icon: const Icon(Icons.skip_next_rounded),
        label: const Text('Siguiente'),
      ),
    );
  }

  Widget _summary(SpeedSessionState session) => SpeedSessionSummaryCard(
    streak: session.consecutiveCorrect,
    bestTime: session.bestTime,
    averageTime: session.averageTime,
    correctRounds: session.correctRounds,
    roundsPlayed: session.roundsPlayed,
  );

  Widget _buildIncorrectView(BuildContext context, SpeedSessionState session) {
    return SpeedSessionResultView(
      icon: Icons.cancel_rounded,
      accentColor: TogescColors.of(context).incorrect,
      title: 'Incorrecto',
      subtitle: 'Las notas eran: ${session.currentNotes.join(", ")}',
      newRecord: _newRecord,
      summary: _summary(session),
      onRetry: _retrySession,
      onMenu: () => Navigator.pop(context),
    );
  }

  Widget _buildTimeoutView(BuildContext context, SpeedSessionState session) {
    return SpeedSessionResultView(
      icon: Icons.timer_off_rounded,
      accentColor: TogescColors.of(context).selection,
      title: 'Tiempo agotado',
      subtitle: 'Las notas eran: ${session.currentNotes.join(", ")}',
      newRecord: _newRecord,
      summary: _summary(session),
      onRetry: _retrySession,
      onMenu: () => Navigator.pop(context),
    );
  }

  Widget _buildGameOverView(BuildContext context, SpeedSessionState session) {
    return SpeedSessionResultView(
      icon: Icons.flag_rounded,
      accentColor: TogescColors.of(context).speedAccent,
      title: 'Fin de sesión',
      subtitle: 'Racha final: ${session.consecutiveCorrect}',
      newRecord: _newRecord,
      summary: _summary(session),
      onRetry: _retrySession,
      onMenu: () => Navigator.pop(context),
    );
  }
}

/// Destello de fondo verde o rojo (14 % de opacidad que se apaga en
/// 500 ms). Sin destello con movimiento reducido: el resultado ya se
/// anuncia con icono y texto.
class _AnswerFlash extends StatelessWidget {
  const _AnswerFlash({super.key, required this.active, required this.color});

  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final duration = motionDuration(context, const Duration(milliseconds: 500));
    if (!active || duration == Duration.zero) return const SizedBox.shrink();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1, end: 0),
          duration: duration,
          curve: Curves.easeOut,
          builder: (context, t, _) => ColoredBox(
            key: const ValueKey('speed-flash'),
            color: color.withValues(alpha: 0.14 * t),
          ),
        ),
      ),
    );
  }
}
