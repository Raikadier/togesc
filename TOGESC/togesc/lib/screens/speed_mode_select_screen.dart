import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';
import '../constants/game_constants.dart';

/// Pantalla de seleccion de modo para entrenamiento de velocidad.
class SpeedModeSelectScreen extends StatelessWidget {
  const SpeedModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Velocidad - Elige modo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Que modo quieres practicar?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'El tiempo limite disminuira con cada respuesta correcta.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _SpeedModeOption(
              title: 'Una sola nota',
              icon: Icons.music_note,
              color: Colors.green,
              onTap: () => _start(context, GameMode.singleNote),
            ),
            _SpeedModeOption(
              title: 'Intervalo (2 notas)',
              icon: Icons.music_note_outlined,
              color: Colors.orange,
              onTap: () => _start(context, GameMode.interval),
            ),
            _SpeedModeOption(
              title: 'Acorde (3 notas)',
              icon: Icons.piano,
              color: Colors.deepOrange,
              onTap: () => _start(context, GameMode.chord),
            ),
            _SpeedModeOption(
              title: 'Aleatorio (1-5 notas)',
              icon: Icons.casino,
              color: Colors.purple,
              onTap: () => _start(context, GameMode.random),
            ),
            _SpeedModeOption(
              title: 'Solo sostenidos',
              icon: Icons.tag,
              color: Colors.blue,
              onTap: () => _start(context, GameMode.sharpsOnly),
            ),
          ],
        ),
      ),
    );
  }

  void _start(BuildContext context, GameMode mode) {
    context.pushReplacement('${AppRoutes.speedGame}/${mode.id}');
  }
}

class _SpeedModeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SpeedModeOption({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
