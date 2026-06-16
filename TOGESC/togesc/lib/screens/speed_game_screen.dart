import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/game_constants.dart';
import '../constants/note_naming.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/speed_session_provider.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/note_input_field.dart';
import '../widgets/countdown_timer_widget.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(speedSessionProvider.notifier).setTargetMode(widget.targetMode);
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
    ref.read(speedSessionProvider.notifier).submitAnswer(notes, responseTime);
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
    });
    await ref.read(speedSessionProvider.notifier).startRound();
    setState(() => _roundStartTime = DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(speedSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Velocidad - ${widget.targetMode.displayName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Info bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoChip(
                  label: 'Racha',
                  value: '${session.consecutiveCorrect}',
                  color: Colors.deepPurple,
                ),
                _InfoChip(
                  label: 'Limite',
                  value: '${session.currentTimeLimit.toStringAsFixed(1)}s',
                  color: Colors.orange,
                ),
                if (session.responseTimes.isNotEmpty)
                  _InfoChip(
                    label: 'Promedio',
                    value: '${session.averageTime.toStringAsFixed(2)}s',
                    color: Colors.blue,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildContent(session)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SpeedSessionState session) {
    switch (session.state) {
      case SpeedState.idle:
        return _buildIdleView();
      case SpeedState.playing:
        return _buildPlayingView(session);
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

  Widget _buildIdleView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.speed, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Modo Velocidad',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tiempo inicial: ${speedInitialTime.toStringAsFixed(0)}s',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startRound,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Comenzar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayingView(SpeedSessionState session) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.volume_up, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            'Escucha... (${session.numNotes} nota(s))',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildAnswerView(SpeedSessionState session) {
    final namingMode =
        ref.watch(noteNamingModeProvider).valueOrNull ?? NoteNamingMode.letter;
    final hint = namingMode == NoteNamingMode.solfege
        ? 'Do Re Mi o C E G'
        : 'C E G o Do Re Mi';

    return SingleChildScrollView(
      child: Column(
        children: [
          CountdownTimerWidget(
            remainingTime: session.remainingTime,
            totalTime: session.currentTimeLimit,
          ),
          const SizedBox(height: 12),
          Text(
            'Que nota(s)? (${session.numNotes})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          PianoKeyboard(
            selectedNotes: _selectedNotes,
            onNoteTapped: _toggleNote,
            noteNamingMode: namingMode,
          ),
          const SizedBox(height: 8),
          if (_selectedNotes.isNotEmpty)
            Wrap(
              spacing: 8,
              children: _selectedNotes.map((note) => Chip(
                label: Text(note),
                onDeleted: () => _toggleNote(note),
              )).toList(),
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _selectedNotes.isNotEmpty ? _confirmSelection : null,
            icon: const Icon(Icons.check),
            label: const Text('Confirmar'),
          ),
          const SizedBox(height: 12),
          NoteInputField(
            onSubmitted: _submitNotes,
            hintText: hint,
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectView(SpeedSessionState session) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            'CORRECTO!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tiempo limite: ${session.currentTimeLimit.toStringAsFixed(1)}s',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startRound,
            icon: const Icon(Icons.skip_next),
            label: const Text('Siguiente'),
          ),
        ],
      ),
    );
  }

  Widget _buildIncorrectView(SpeedSessionState session) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cancel, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'INCORRECTO',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las notas eran: ${session.currentNotes.join(", ")}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildSpeedStats(session),
          const SizedBox(height: 24),
          _buildRetryButtons(),
        ],
      ),
    );
  }

  Widget _buildTimeoutView(SpeedSessionState session) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_off, size: 80, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            'TIEMPO AGOTADO!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las notas eran: ${session.currentNotes.join(", ")}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildSpeedStats(session),
          const SizedBox(height: 24),
          _buildRetryButtons(),
        ],
      ),
    );
  }

  Widget _buildGameOverView(SpeedSessionState session) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Game Over',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSpeedStats(session),
          const SizedBox(height: 24),
          _buildRetryButtons(),
        ],
      ),
    );
  }

  Widget _buildSpeedStats(SpeedSessionState session) {
    if (session.responseTimes.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Estadisticas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _statRow('Respuestas', '${session.responseTimes.length}'),
            _statRow('Racha', '${session.consecutiveCorrect}'),
            _statRow('Promedio', '${session.averageTime.toStringAsFixed(2)}s'),
            _statRow('Mejor tiempo', '${session.bestTime.toStringAsFixed(2)}s'),
            _statRow('Tiempo limite', '${session.currentTimeLimit.toStringAsFixed(1)}s'),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRetryButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            ref.read(speedSessionProvider.notifier).retry();
            _startRound();
          },
          icon: const Icon(Icons.replay),
          label: const Text('Reintentar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.home),
          label: const Text('Menu'),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
