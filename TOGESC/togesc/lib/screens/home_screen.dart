import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../constants/game_constants.dart';
import '../constants/subscription_constants.dart';
import '../models/practice_session_log.dart';
import '../models/subscription_status.dart';
import '../providers/audio_provider.dart';
import '../providers/engagement_stats_provider.dart';
import '../providers/last_practice_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/subscription_access.dart';
import '../widgets/continue_practice_card.dart';
import '../widgets/daily_focus_section.dart';
import '../widgets/home_hub_views.dart';
import '../widgets/mode_bento_card.dart';
import '../widgets/session_evolution_chart.dart';
import '../widgets/togesc_ui.dart';
import '../providers/session_history_provider.dart';
import '../utils/session_history_stats.dart';

/// Pantalla principal: enfoque académico (qué practicar hoy) antes que gamificación.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _modesGridKey = GlobalKey<ModeBentoGridState>();
  bool _modesExpanded = false;
  List<PracticeSessionLog>? _cachedHistory;
  List<DayPracticeSummary>? _cachedWeekly;

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
      'Identifica dos notas simultáneas',
      false,
    ),
    (
      GameMode.chord,
      Icons.piano_rounded,
      'Acorde (3 notas)',
      'Identifica tres notas simultáneas',
      true,
    ),
    (
      GameMode.random,
      Icons.shuffle_rounded,
      'Aleatorio (1-5 notas)',
      'Número aleatorio de notas',
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
  Widget build(BuildContext context) {
    final lastPractice = ref.watch(lastPracticeSessionProvider).valueOrNull;
    final status = ref.watch(subscriptionStatusProvider).valueOrNull;
    final effectiveStatus = status ?? const SubscriptionStatus.free();
    final engagement = ref.watch(engagementStatsProvider);
    final history = ref.watch(sessionHistoryProvider).valueOrNull ?? [];
    if (!identical(history, _cachedHistory)) {
      _cachedHistory = history;
      _cachedWeekly = buildDailyPracticeSummaries(history);
    }
    final weeklySummaries = _cachedWeekly ?? const <DayPracticeSummary>[];
    final hasWeeklyActivity = weeklySummaries.any((d) => d.hasActivity);

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

    final bentoModes = [
      for (final (mode, icon, title, subtitle, isPro) in _modes)
        (
          mode: mode,
          icon: icon,
          title: title,
          subtitle: subtitle,
          isPro: isPro,
          locked:
              isPro && !SubscriptionAccess.canPlayMode(effectiveStatus, mode),
          mastery: engagement.masteryFor(mode),
          onTap: () => openGame('${AppRoutes.game}/${mode.id}', mode),
        ),
      (
        mode: GameMode.speedTraining,
        icon: Icons.speed_rounded,
        title: 'Entrenamiento de velocidad',
        subtitle: 'Responde antes de que se agote el tiempo',
        isPro: true,
        locked: !SubscriptionAccess.canPlayMode(
          effectiveStatus,
          GameMode.speedTraining,
        ),
        mastery: engagement.masteryFor(GameMode.speedTraining),
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
    ];

    final hiddenProCount = bentoModes.where((m) => m.isPro).length;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: TogescPageBody(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Entrenador de Oído Absoluto',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const PracticeStreakLabel(),
            const SizedBox(height: DesignTokens.spacingLg),
            const DailyFocusSection(),
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
            HomeSectionHeader(
              title: 'Modos de juego',
              subtitle: _modesExpanded
                  ? 'Todos los ejercicios, con free primero y Pro después.'
                  : 'Empieza por los ejercicios básicos. Los modos Pro están en Ver todos.',
              trailing: hiddenProCount > 0
                  ? TextButton(
                      onPressed: () {
                        final state = _modesGridKey.currentState;
                        if (state == null) return;
                        state.toggle();
                        setState(() => _modesExpanded = state.expanded);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingSm,
                        ),
                        minimumSize: const Size(
                          DesignTokens.touchTargetMin,
                          DesignTokens.touchTargetMin,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _modesExpanded
                                ? 'Ver menos'
                                : 'Ver todos ($hiddenProCount)',
                          ),
                          Icon(
                            _modesExpanded
                                ? Icons.expand_less_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
            ModeBentoGrid(
              key: _modesGridKey,
              modes: bentoModes,
              onExpandedChanged: (expanded) {
                setState(() => _modesExpanded = expanded);
              },
            ),
            if (hasWeeklyActivity) ...[
              const SizedBox(height: DesignTokens.spacingLg),
              SessionEvolutionChart(summaries: weeklySummaries),
            ],
          ],
          ),
        ),
      ),
    );
  }
}
