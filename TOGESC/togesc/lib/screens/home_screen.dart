import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../constants/game_constants.dart';
import '../constants/subscription_constants.dart';
import '../models/subscription_status.dart';
import '../providers/audio_provider.dart';
import '../providers/last_practice_provider.dart';
import '../providers/srs_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/subscription_access.dart';
import '../widgets/continue_practice_card.dart';
import '../widgets/home_hub_views.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/togesc_ui.dart';

/// Pantalla principal con menu de modos de juego y recomendaciones.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _modes = [
    (
      GameMode.singleNote,
      Icons.music_note_rounded,
      'Una sola nota',
      'Identifica notas individuales',
      false,
    ),
    (
      GameMode.interval,
      Icons.music_note_outlined,
      'Intervalo (2 notas)',
      'Identifica dos notas simultaneas',
      false,
    ),
    (
      GameMode.chord,
      Icons.piano_rounded,
      'Acorde (3 notas)',
      'Identifica tres notas simultaneas',
      true,
    ),
    (
      GameMode.random,
      Icons.casino_rounded,
      'Aleatorio (1-5 notas)',
      'Numero aleatorio de notas',
      true,
    ),
    (
      GameMode.sharpsOnly,
      Icons.tag_rounded,
      'Solo sostenidos',
      'C#, D#, F#, G#, A#',
      false,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(practiceRecommendationsProvider);
    final lastPractice = ref.watch(lastPracticeSessionProvider).valueOrNull;
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

    return TogescScaffold(
      title: 'Entrenador de Oido Absoluto',
      actions: [
        if (!hasPro)
          IconButton(
            icon: const Icon(Icons.workspace_premium_outlined),
            tooltip: 'TOGESC Pro',
            onPressed: () => context.push(AppRoutes.paywall),
          ),
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Ajustes',
          onPressed: () => context.push(AppRoutes.settings),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline_rounded),
          tooltip: 'Cuenta',
          onPressed: () => context.push(AppRoutes.account),
        ),
        IconButton(
          icon: const Icon(Icons.info_outline_rounded),
          tooltip: 'Acerca de',
          onPressed: () => context.push(AppRoutes.about),
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart_rounded),
          tooltip: 'Estadisticas',
          onPressed: () => context.push(AppRoutes.statistics),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.marginMobile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (lastPractice != null && lastPractice.mode != null) ...[
              ContinuePracticeCard(
                session: lastPractice,
                subscriptionStatus: effectiveStatus,
                onContinue: () {
                  ref.read(audioPlayerServiceProvider).captureUserGesture();
                  openLastPracticeSession(
                    context: context,
                    session: lastPractice,
                    subscriptionStatus: effectiveStatus,
                    onOpenRoute: (route) => context.push(route),
                  );
                },
              ),
              const SizedBox(height: DesignTokens.spacingLg),
            ],
            if (recommendations.isNotEmpty) ...[
              const HomeSectionHeader(
                title: 'Enfoque diario',
                subtitle: 'Recomendaciones segun tu progreso SRS',
              ),
              RecommendationCard(recommendations: recommendations),
              const SizedBox(height: DesignTokens.spacingLg),
            ],
            const HomeSectionHeader(title: 'Modos de Juego'),
            for (final (mode, icon, title, subtitle, isPro) in _modes)
              HomeModeOptionCard(
                title: title,
                subtitle: subtitle,
                icon: icon,
                isPro: isPro,
                locked: isPro &&
                    !SubscriptionAccess.canPlayMode(effectiveStatus, mode),
                onTap: () => openGame(
                  '${AppRoutes.game}/${mode.id}',
                  mode,
                ),
              ),
            HomeModeOptionCard(
              title: 'Entrenamiento de velocidad',
              subtitle: 'Responde antes de que se agote el tiempo',
              icon: Icons.speed_rounded,
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
