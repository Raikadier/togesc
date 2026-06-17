import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_tokens.dart';
import '../constants/game_constants.dart';
import '../constants/note_naming.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/game_session_provider.dart';
import '../utils/piano_note_selection.dart';
import '../widgets/game_session_views.dart';
import '../widgets/note_srs_detail_card.dart';
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

  int _requiredNotes(GameSessionState session) {
    return selectableNoteCount(
      screenMode: widget.mode,
      sessionNumNotes: session.numNotes,
    );
  }

  @override
  void deactivate() {
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
    ref.read(gameSessionProvider.notifier).submitAnswer(notes, responseTime);
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
      _roundStartTime = DateTime.now();
    });
    await ref.read(gameSessionProvider.notifier).startRound();
    setState(() => _roundStartTime = DateTime.now());
  }

  Future<void> _continueAfterResult() async {
    final audio = ref.read(audioPlayerServiceProvider);
    audio.captureUserGesture();
    await audio.waitUntilReady();
    await ref.read(gameSessionProvider.notifier).playCluster();
    await _startRound();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);

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
            Expanded(child: _buildContent(session)),
            if (session.state == GameState.showingResult)
              _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(GameSessionState session) {
    switch (session.state) {
      case GameState.idle:
        return GameSessionIdleView(onPlay: _startRound);
      case GameState.listening:
        return GameSessionListeningView(numNotes: _requiredNotes(session));
      case GameState.waitingForAnswer:
        return _buildAnswerView(session);
      case GameState.showingResult:
        return _buildResultView(session);
      case GameState.playingCluster:
        return const GameSessionClusterView();
    }
  }

  Widget _buildAnswerView(GameSessionState session) {
    final namingMode =
        ref.watch(noteNamingModeProvider).valueOrNull ?? NoteNamingMode.letter;
    final required = _requiredNotes(session);
    final hint = namingMode == NoteNamingMode.solfege
        ? 'O escribe aqui: Do Re Mi'
        : 'O escribe aqui: C E G';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameSessionAnswerHeader(numNotes: required),
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            '${_selectedNotes.length}/$required notas seleccionadas',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.onSurfaceVariant,
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
                  deleteIconColor: DesignTokens.primaryContainer,
                  side: const BorderSide(
                    color: DesignTokens.primaryContainer,
                    width: 2,
                  ),
                  backgroundColor:
                      DesignTokens.selection.withValues(alpha: 0.15),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: DesignTokens.spacingLg),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _selectedNotes.isEmpty
                      ? null
                      : () => _confirmSelection(required),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Confirmar'),
                ),
              ),
              const SizedBox(width: DesignTokens.spacingMd),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _startRound,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Repetir'),
                ),
              ),
            ],
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

  Widget _buildResultView(GameSessionState session) {
    final result = session.lastResult;
    if (result == null) return const SizedBox.shrink();

    final correctSet = result.correctNotes;
    final incorrectSet = _selectedNotes.difference(correctSet);
    final namingMode =
        ref.watch(noteNamingModeProvider).valueOrNull ?? NoteNamingMode.letter;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TogescCard(
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            child: Center(
              child: PianoKeyboard(
                correctNotes: correctSet,
                incorrectNotes: incorrectSet,
                disabled: true,
                noteNamingMode: namingMode,
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

  Widget _buildContinueButton() {
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
