import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../constants/game_constants.dart';
import '../constants/subscription_constants.dart';
import '../providers/audio_provider.dart';
import '../providers/clock_provider.dart';
import '../providers/engagement_stats_provider.dart';
import '../providers/practice_focus_provider.dart';
import '../providers/today_session_provider.dart';
import '../utils/relative_time.dart';
import '../widgets/home_v2/free_practice_tiles.dart';
import '../widgets/home_v2/home_app_bar.dart';
import '../widgets/home_v2/home_mode_access.dart';
import '../widgets/home_v2/resume_row.dart';
import '../widgets/home_v2/today_session_hero.dart';
import '../widgets/home_v2/week_strip.dart';

/// Ancho máximo del contenido del Home en web ancho (el rail lo pone el shell).
const double homeContentMaxWidth = 720;

/// Home v2 «una sola decisión» (spec 1a): la sesión de hoy primero; retomar,
/// práctica libre y la semana después.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _modeCatalog = [
    (
      GameMode.singleNote,
      Icons.music_note_rounded,
      'Una nota',
      'Identifica notas individuales',
    ),
    (
      GameMode.interval,
      Icons.queue_music_rounded,
      'Intervalo',
      'Dos notas simultáneas',
    ),
    (
      GameMode.chord,
      Icons.piano_rounded,
      'Acorde',
      'Tres notas simultáneas',
    ),
    (
      GameMode.random,
      Icons.shuffle_rounded,
      'Aleatorio',
      'De 1 a 5 notas',
    ),
    (
      GameMode.sharpsOnly,
      Icons.tag_rounded,
      'Solo sostenidos',
      'C#, D#, F#, G#, A#',
    ),
    (
      GameMode.speedTraining,
      Icons.speed_rounded,
      'Velocidad',
      'Responde antes de que se agote el tiempo',
    ),
  ];

  static const _freeTileModes = {
    GameMode.singleNote,
    GameMode.interval,
    GameMode.chord,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final plan = ref.watch(todaySessionPlanProvider);
    final resume = ref.watch(resumeSessionProvider);
    final week = ref.watch(calendarWeekProvider);
    final engagement = ref.watch(engagementStatsProvider);
    final canPlay = ref.watch(homeModeAccessProvider);
    final desktop =
        MediaQuery.sizeOf(context).width >= DesignTokens.desktopBreakpoint;

    void captureGesture() =>
        ref.read(audioPlayerServiceProvider).captureUserGesture();

    void openMode(GameMode mode) {
      captureGesture();
      if (!canPlay(mode)) {
        context.push(paywallRouteFor(mode));
        return;
      }
      // La práctica libre no hereda el foco de la sesión de hoy.
      clearPracticeFocusNote(ref);
      if (mode == GameMode.speedTraining) {
        context.push(AppRoutes.speedSelect);
      } else {
        context.push('${AppRoutes.game}/${mode.id}');
      }
    }

    void startTodaySession() {
      captureGesture();
      ref.read(practiceFocusNoteProvider.notifier).state = null;
      setPracticeFocusNotes(ref, plan.focusNoteNames);
      context.push('${AppRoutes.game}/${GameMode.singleNote.id}');
    }

    final entries = [
      for (final (mode, icon, title, subtitle) in _modeCatalog)
        HomeModeEntry(
          mode: mode,
          title: title,
          subtitle: subtitle,
          icon: icon,
          isPro: !SubscriptionConstants.isModeFree(mode),
          locked: !canPlay(mode),
          mastery: engagement.masteryFor(mode),
          onTap: () => openMode(mode),
        ),
    ];

    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: homeContentMaxWidth),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.marginMobile,
                  0,
                  DesignTokens.marginMobile,
                  DesignTokens.marginDesktop,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // En móvil el shell ya pinta logo y avatar en su app
                    // bar; el Home añade la racha junto a la fecha. En
                    // escritorio (rail, sin app bar) el Home pinta la suya.
                    if (desktop) ...[
                      HomeAppBar(
                        streakDays: engagement.currentStreakDays,
                        onAvatarTap: () => context.go(AppRoutes.account),
                      ),
                      HomeOverline(formatLongDateEs(now)),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(
                          top: DesignTokens.spacingSm,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: HomeOverline(formatLongDateEs(now)),
                            ),
                            StreakChip(
                              streakDays: engagement.currentStreakDays,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: DesignTokens.spacingMd),
                    TodaySessionHero(
                      plan: plan,
                      onStart: startTodaySession,
                      onAdjust: () => context.push(AppRoutes.settings),
                    ),
                    if (resume != null) ...[
                      const SizedBox(height: DesignTokens.spacingLg),
                      ResumeRow(
                        info: resume,
                        now: now,
                        locked: !canOpenLastPracticeSession(
                          session: resume.session,
                          canPlay: canPlay,
                        ),
                        onTap: () {
                          captureGesture();
                          clearPracticeFocusNote(ref);
                          openLastPracticeSession(
                            context: context,
                            session: resume.session,
                            canPlay: canPlay,
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: DesignTokens.spacingLg + 8),
                    HomeV2SectionHeader(
                      title: 'Práctica libre',
                      trailing: TextButton(
                        key: const ValueKey('home-see-all-modes'),
                        onPressed: () => showAllModesSheet(context, entries),
                        style: TextButton.styleFrom(
                          foregroundColor: DesignTokens.primary,
                          minimumSize: const Size(
                            DesignTokens.touchTargetMin,
                            DesignTokens.touchTargetMin,
                          ),
                        ),
                        child: const Text('Ver todos'),
                      ),
                    ),
                    FreePracticeTiles(
                      entries: [
                        for (final e in entries)
                          if (_freeTileModes.contains(e.mode)) e,
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spacingLg + 8),
                    HomeV2SectionHeader(
                      title:
                          'Esta semana · ${week.practicedDays} de 7 días',
                    ),
                    WeekStrip(week: week),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
