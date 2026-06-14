import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';
import '../constants/game_constants.dart';
import '../providers/audio_provider.dart';
import '../providers/srs_provider.dart';
import '../widgets/recommendation_card.dart';

/// Pantalla principal con menu de modos de juego y recomendaciones.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(practiceRecommendationsProvider);

    void openGame(String route) {
      ref.read(audioPlayerServiceProvider).captureUserGesture();
      context.push(route);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrenador de Oido Absoluto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Acerca de',
            onPressed: () => context.push(AppRoutes.about),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Estadisticas',
            onPressed: () => context.push(AppRoutes.statistics),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (recommendations.isNotEmpty)
              RecommendationCard(recommendations: recommendations),
            const SizedBox(height: 16),
            const Text(
              'Modos de Juego',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _ModeCard(
              icon: Icons.music_note,
              title: 'Una sola nota',
              subtitle: 'Identifica notas individuales',
              color: Colors.green,
              onTap: () => openGame('${AppRoutes.game}/${GameMode.singleNote.id}'),
            ),
            _ModeCard(
              icon: Icons.music_note_outlined,
              title: 'Intervalo (2 notas)',
              subtitle: 'Identifica dos notas simultaneas',
              color: Colors.orange,
              onTap: () => openGame('${AppRoutes.game}/${GameMode.interval.id}'),
            ),
            _ModeCard(
              icon: Icons.piano,
              title: 'Acorde (3 notas)',
              subtitle: 'Identifica tres notas simultaneas',
              color: Colors.deepOrange,
              onTap: () => openGame('${AppRoutes.game}/${GameMode.chord.id}'),
            ),
            _ModeCard(
              icon: Icons.casino,
              title: 'Aleatorio (1-5 notas)',
              subtitle: 'Numero aleatorio de notas',
              color: Colors.purple,
              onTap: () => openGame('${AppRoutes.game}/${GameMode.random.id}'),
            ),
            _ModeCard(
              icon: Icons.tag,
              title: 'Solo sostenidos',
              subtitle: 'C#, D#, F#, G#, A#',
              color: Colors.blue,
              onTap: () => openGame('${AppRoutes.game}/${GameMode.sharpsOnly.id}'),
            ),
            _ModeCard(
              icon: Icons.speed,
              title: 'Entrenamiento de velocidad',
              subtitle: 'Responde antes de que se agote el tiempo',
              color: Colors.red,
              onTap: () {
                ref.read(audioPlayerServiceProvider).captureUserGesture();
                context.push(AppRoutes.speedSelect);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
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
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
