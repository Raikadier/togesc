import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_tokens.dart';
import '../constants/game_constants.dart';
import '../constants/note_naming.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/audio_provider.dart';
import '../models/last_practice_session.dart';
import '../providers/session_history_provider.dart';
import '../providers/speed_session_provider.dart';
import '../utils/piano_note_selection.dart';
import '../widgets/countdown_timer_widget.dart';
import '../widgets/game_session_views.dart';
import '../widgets/note_input_field.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/speed_session_views.dart';
import '../widgets/togesc_ui.dart';

/// Pantalla del juego de velocidad con countdown.
class SpeedGameScreen extends ConsumerStatefulWidget {
  final GameMode targetMode;

  const SpeedGameScreen({super.key, required this.targetMode});

  @override
  ConsumerState<SpeedGameScreen> createState() => _SpeedGameScreenState();
}

class _SpeedGameScreenState extends ConsumerState<SpeedGameScreen> {
  final _selectedNotes = <String>{};
  DateTime? _roundStartTime;

  int _requiredNotes(SpeedSessionState session) {
    return selectableNoteCount(
      screenMode: widget.targetMode,
      sessionNumNotes: session.numNotes,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(speedSessionProvider.notifier).setTargetMode(widget.targetMode);
    });
  }

  @override
  void deactivate() {
    final session = ref.read(speedSessionProvider);
    if (session.roundsPlayed > 0) {
      ref.read(sessionHistoryProvider.notifier).record(
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
    _startRound();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(speedSessionProvider);
    final showMetrics = session.state != SpeedState.idle;

    return TogescScaffold(
      title: 'Velocidad - ${widget.targetMode.displayName}',
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
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.marginMobile),
              child: _buildContent(session),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SpeedSessionState session) {
    switch (session.state) {
      case SpeedState.idle:
        return SpeedSessionIdleView(onStart: _startRound);
      case SpeedState.playing:
        return SpeedSessionListeningView(numNotes: _requiredNotes(session));
      case SpeedState.waitingForAnswer:
        return _buildAnswerView(session);
      case SpeedState.correct:
        return _buildCorrectView(session);
      case SpeedState.incorrect:
        return _buildIncorrectView(session);
      case SpeedState.timeout:
        return _buildTimeoutView(session);
      case SpeedState.gameOver:
        return _buildGameOverView(session);
    }
  }

  Widget _buildAnswerView(SpeedSessionState session) {
    final namingMode =
        ref.watch(noteNamingModeProvider).valueOrNull ?? NoteNamingMode.letter;
    final required = _requiredNotes(session);
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
                  deleteIconColor: Theme.of(context).colorScheme.primaryContainer,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    width: 2,
                  ),
                  backgroundColor:
                      DesignTokens.selection.withValues(alpha: 0.15),
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

  Widget _buildCorrectView(SpeedSessionState session) {
    return SpeedSessionFeedbackView(
      icon: Icons.check_circle_rounded,
      accentColor: DesignTokens.correct,
      title: 'CORRECTO!',
      subtitle:
          'Tiempo limite: ${session.currentTimeLimit.toStringAsFixed(1)}s',
      footer: FilledButton.icon(
        onPressed: _startRound,
        icon: const Icon(Icons.skip_next_rounded),
        label: const Text('Siguiente'),
      ),
    );
  }

  Widget _buildIncorrectView(SpeedSessionState session) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SpeedSessionFeedbackView(
            icon: Icons.cancel_rounded,
            accentColor: DesignTokens.incorrect,
            title: 'INCORRECTO',
            subtitle: 'Las notas eran: ${session.currentNotes.join(", ")}',
          ),
          if (session.responseTimes.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spacingLg),
            SpeedSessionSummaryCard(
              responses: session.responseTimes.length,
              streak: session.consecutiveCorrect,
              averageTime: session.averageTime,
              bestTime: session.bestTime,
              timeLimit: session.currentTimeLimit,
            ),
          ],
          const SizedBox(height: DesignTokens.spacingLg),
          SpeedSessionRetryActions(
            onRetry: _retrySession,
            onMenu: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeoutView(SpeedSessionState session) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SpeedSessionFeedbackView(
            icon: Icons.timer_off_rounded,
            accentColor: DesignTokens.selection,
            title: 'TIEMPO AGOTADO!',
            subtitle: 'Las notas eran: ${session.currentNotes.join(", ")}',
          ),
          if (session.responseTimes.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spacingLg),
            SpeedSessionSummaryCard(
              responses: session.responseTimes.length,
              streak: session.consecutiveCorrect,
              averageTime: session.averageTime,
              bestTime: session.bestTime,
              timeLimit: session.currentTimeLimit,
            ),
          ],
          const SizedBox(height: DesignTokens.spacingLg),
          SpeedSessionRetryActions(
            onRetry: _retrySession,
            onMenu: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverView(SpeedSessionState session) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            'Fin de sesion',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          if (session.responseTimes.isNotEmpty)
            SpeedSessionSummaryCard(
              responses: session.responseTimes.length,
              streak: session.consecutiveCorrect,
              averageTime: session.averageTime,
              bestTime: session.bestTime,
              timeLimit: session.currentTimeLimit,
            ),
          const SizedBox(height: DesignTokens.spacingLg),
          SpeedSessionRetryActions(
            onRetry: _retrySession,
            onMenu: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
