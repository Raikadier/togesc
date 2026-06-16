import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';
import '../constants/game_constants.dart';
import '../constants/subscription_constants.dart';
import '../models/subscription_status.dart';
import '../providers/audio_provider.dart';
import '../providers/srs_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/subscription_access.dart';
import '../widgets/recommendation_card.dart';

/// Pantalla principal con menu de modos de juego y recomendaciones.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(practiceRecommendationsProvider);
    final hasPro = ref.watch(hasProAccessProvider);
    final status = ref.watch(subscriptionStatusProvider).valueOrNull;
    final effectiveStatus = status ?? const SubscriptionStatus.free();

    void openGame(String route, GameMode mode) {
      if (!SubscriptionAccess.canPlayMode(effectiveStatus, mode)) {
        ref.read(audioPlayerServiceProvider).captureUserGesture();
        context.push(
          '${AppRoutes.paywall}?feature=${Uri.encodeComponent(SubscriptionConstants.modeProLabel(mode))}',
        );
        return;
      }
      ref.read(audioPlayerServiceProvider).captureUserGesture();
      context.push(route);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrenador de Oido Absoluto'),
        actions: [
          if (!hasPro)
            IconButton(
              icon: const Icon(Icons.workspace_premium_outlined),
              tooltip: 'TOGESC Pro',
              onPressed: () => context.push(AppRoutes.paywall),
            ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Cuenta',
            onPressed: () => context.push(AppRoutes.account),
          ),
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
              onTap: () => openGame(
                '${AppRoutes.game}/${GameMode.singleNote.id}',
                GameMode.singleNote,
              ),
            ),
            _ModeCard(
              icon: Icons.music_note_outlined,
              title: 'Intervalo (2 notas)',
              subtitle: 'Identifica dos notas simultaneas',
              color: Colors.orange,
              onTap: () => openGame(
                '${AppRoutes.game}/${GameMode.interval.id}',
                GameMode.interval,
              ),
            ),
            _ModeCard(
              icon: Icons.piano,
              title: 'Acorde (3 notas)',
              subtitle: 'Identifica tres notas simultaneas',
              color: Colors.deepOrange,
              isPro: true,
              locked: !SubscriptionAccess.canPlayMode(
                effectiveStatus,
                GameMode.chord,
              ),
              onTap: () => openGame(
                '${AppRoutes.game}/${GameMode.chord.id}',
                GameMode.chord,
              ),
            ),
            _ModeCard(
              icon: Icons.casino,
              title: 'Aleatorio (1-5 notas)',
              subtitle: 'Numero aleatorio de notas',
              color: Colors.purple,
              isPro: true,
              locked: !SubscriptionAccess.canPlayMode(
                effectiveStatus,
                GameMode.random,
              ),
              onTap: () => openGame(
                '${AppRoutes.game}/${GameMode.random.id}',
                GameMode.random,
              ),
            ),
            _ModeCard(
              icon: Icons.tag,
              title: 'Solo sostenidos',
              subtitle: 'C#, D#, F#, G#, A#',
              color: Colors.blue,
              onTap: () => openGame(
                '${AppRoutes.game}/${GameMode.sharpsOnly.id}',
                GameMode.sharpsOnly,
              ),
            ),
            _ModeCard(
              icon: Icons.speed,
              title: 'Entrenamiento de velocidad',
              subtitle: 'Responde antes de que se agote el tiempo',
              color: Colors.red,
              isPro: true,
              locked: !SubscriptionAccess.canPlayMode(
                effectiveStatus,
                GameMode.speedTraining,
              ),
              onTap: () {
                ref.read(audioPlayerServiceProvider).captureUserGesture();
                if (!SubscriptionAccess.canPlayMode(
                  effectiveStatus,
                  GameMode.speedTraining,
                )) {
                  context.push(
                    '${AppRoutes.paywall}?feature=${Uri.encodeComponent('Entrenamiento de velocidad')}',
                  );
                  return;
                }
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
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isPro = false,
    this.locked = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isPro;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isPro)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(subtitle),
        trailing: Icon(locked ? Icons.lock_outline : Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
