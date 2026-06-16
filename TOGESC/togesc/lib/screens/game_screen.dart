import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/game_constants.dart';
import '../constants/note_naming.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/game_session_provider.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/note_input_field.dart';
import '../widgets/result_card.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameSessionProvider.notifier).setMode(widget.mode);
    });
  }

  void _toggleNote(String note) {
    setState(() {
      if (_selectedNotes.contains(note)) {
        _selectedNotes.remove(note);
      } else {
        _selectedNotes.add(note);
      }
    });
  }

  void _submitNotes(List<String> notes) {
    if (_roundStartTime == null) return;
    final responseTime =
        DateTime.now().difference(_roundStartTime!).inMilliseconds / 1000.0;
    ref.read(gameSessionProvider.notifier).submitAnswer(notes, responseTime);
    setState(() => _selectedNotes.clear());
  }

  void _confirmSelection() {
    if (_selectedNotes.isEmpty) return;
    _submitNotes(_selectedNotes.toList());
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
    // Actualizar timestamp despues de que el audio termine
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode.displayName),
        actions: [
          IconButton(
            icon: Icon(
              session.useRandomInstrument ? Icons.music_note : Icons.graphic_eq,
            ),
            tooltip: session.useRandomInstrument
                ? 'Timbre aleatorio'
                : 'Onda senoidal',
            onPressed: () =>
                ref.read(gameSessionProvider.notifier).toggleInstrument(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(child: _buildContent(session)),
            const SizedBox(height: 8),
            _buildBottomSection(session),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(GameSessionState session) {
    switch (session.state) {
      case GameState.idle:
        return _buildIdleView();
      case GameState.listening:
        return _buildListeningView(session);
      case GameState.waitingForAnswer:
        return _buildAnswerView(session);
      case GameState.showingResult:
        return _buildResultView(session);
      case GameState.playingCluster:
        return _buildClusterView();
    }
  }

  Widget _buildIdleView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.headphones, size: 64, color: Colors.deepPurple),
          const SizedBox(height: 16),
          const Text(
            'Preparate para escuchar',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startRound,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Reproducir'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningView(GameSessionState session) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.volume_up, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            'Escucha atentamente... (${session.numNotes} nota(s))',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildAnswerView(GameSessionState session) {
    final correctSet = <String>{};
    final incorrectSet = <String>{};
    final namingMode =
        ref.watch(noteNamingModeProvider).valueOrNull ?? NoteNamingMode.letter;
    final hint = namingMode == NoteNamingMode.solfege
        ? 'O escribe aqui: Do Re Mi'
        : 'O escribe aqui: C E G';

    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            'Que nota(s) escuchaste? (${session.numNotes})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          PianoKeyboard(
            selectedNotes: _selectedNotes,
            correctNotes: correctSet,
            incorrectNotes: incorrectSet,
            onNoteTapped: _toggleNote,
            noteNamingMode: namingMode,
          ),
          const SizedBox(height: 12),
          if (_selectedNotes.isNotEmpty)
            Wrap(
              spacing: 8,
              children: _selectedNotes.map((note) => Chip(
                label: Text(note),
                onDeleted: () => _toggleNote(note),
              )).toList(),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _selectedNotes.isNotEmpty ? _confirmSelection : null,
                icon: const Icon(Icons.check),
                label: const Text('Confirmar'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _startRound,
                icon: const Icon(Icons.replay),
                label: const Text('Repetir'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NoteInputField(
            onSubmitted: _submitNotes,
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
        children: [
          PianoKeyboard(
            correctNotes: correctSet,
            incorrectNotes: incorrectSet,
            disabled: true,
            noteNamingMode: namingMode,
          ),
          const SizedBox(height: 16),
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

  Widget _buildClusterView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.waves, size: 64, color: Colors.cyan),
          SizedBox(height: 16),
          Text('Limpiando el oido...', style: TextStyle(fontSize: 18)),
          SizedBox(height: 16),
          CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildBottomSection(GameSessionState session) {
    if (session.state == GameState.showingResult) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _continueAfterResult,
              icon: const Icon(Icons.skip_next),
              label: const Text('Siguiente'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
