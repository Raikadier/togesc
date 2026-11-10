import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/togesc_colors.dart';
import '../app/router.dart';
import '../constants/game_constants.dart';
import '../constants/note_naming.dart';
import '../constants/subscription_constants.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/clock_provider.dart';
import '../providers/engagement_stats_provider.dart';
import '../providers/practice_focus_provider.dart';
import '../providers/srs_provider.dart';
import '../providers/today_session_provider.dart';
import '../utils/relative_time.dart';
import '../widgets/home_v2/ear_map_card.dart';
import '../widgets/home_v2/free_practice_tiles.dart';
import '../widgets/home_v2/home_app_bar.dart';
import '../widgets/home_v2/home_mode_access.dart';
import '../widgets/home_v2/resume_row.dart';
import '../widgets/home_v2/today_adjust_sheet.dart';
import '../widgets/home_v2/today_session_hero.dart';
import '../widgets/home_v2/week_strip.dart';
import '../widgets/staggered_entrance.dart';

/// Ancho máximo del contenido del Home en móvil y tableta.
const double homeContentMaxWidth = 720;

/// Ancho máximo del Home de escritorio en dos columnas (≥ 1024).
const double homeDesktopMaxWidth = 1120;

/// Proporción de las columnas de escritorio (1,25 fr / 1 fr).
const int homeDesktopLeftFlex = 125;
const int homeDesktopRightFlex = 100;

/// Home v2.1 «una sola decisión» (SPEC v2.1 §2.1): la sesión de hoy
/// primero; retomar, práctica libre, el mapa del oído y los últimos 7 días
/// después. En escritorio, dos columnas y la derecha fija (*sticky*): cada
/// columna se desplaza por su cuenta.
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
    final recent = ref.watch(recentDaysProvider);
    final streak = ref.watch(homeStreakStatusProvider);
    final summaries = ref.watch(noteProgressSummariesProvider);
    final namingMode =
        ref.watch(noteNamingModeProvider).valueOrNull ?? NoteNamingMode.letter;
    final learningThreshold = ref.watch(srsLearningThresholdProvider);
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

    void practiceNote(String note) {
      captureGesture();
      // Sesión de una sola nota: la nota única manda sobre el foco.
      ref.read(practiceFocusNotesProvider.notifier).state = const [];
      ref.read(practiceFocusNoteProvider.notifier).state = note;
      context.push('${AppRoutes.game}/${GameMode.singleNote.id}');
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

    final header = <Widget>[
      // En móvil el shell ya pinta logo y avatar en su app bar; el Home
      // añade la racha junto a la fecha. En escritorio (rail, sin app bar)
      // el Home pinta la suya.
      if (desktop) ...[
        HomeAppBar(
          streakDays: engagement.currentStreakDays,
          onAvatarTap: () => context.go(AppRoutes.account),
        ),
        HomeOverline(formatLongDateEs(now)),
      ] else
        Padding(
          padding: const EdgeInsets.only(top: DesignTokens.spacingSm),
          child: Row(
            children: [
              Expanded(child: HomeOverline(formatLongDateEs(now))),
              StreakChip(streakDays: engagement.currentStreakDays),
            ],
          ),
        ),
      const SizedBox(height: DesignTokens.spacingMd),
    ];

    final hero = TodaySessionHero(
      plan: plan,
      onStart: startTodaySession,
      onAdjust: () => showTodayAdjustSheet(context, ref),
    );

    final resumeRow = resume == null
        ? null
        : ResumeRow(
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
          );

    final freePractice = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeV2SectionHeader(
          title: 'Práctica libre',
          trailing: TextButton(
            key: const ValueKey('home-see-all-modes'),
            onPressed: () => showAllModesSheet(context, entries),
            style: TextButton.styleFrom(
              foregroundColor: TogescColors.of(context).brand,
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
      ],
    );

    final earMap = EarMapCard(
      summaries: summaries,
      namingMode: namingMode,
      learningThreshold: learningThreshold,
      onPractice: practiceNote,
      onOpenProgress: () => context.go(AppRoutes.statistics),
    );

    final recentDays = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeV2SectionHeader(
          title: 'Últimos 7 días',
          trailing: Text(
            '${recent.practicedDays} de 7 días',
            key: const ValueKey('home-recent-days-count'),
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: TogescColors.of(context).textSecondary)
                .merge(DesignTokens.tabularNumbers),
          ),
        ),
        WeekStrip(week: recent),
        const SizedBox(height: DesignTokens.spacingSm + 2),
        Text(
          weekStreakCopy(streak),
          key: const ValueKey('week-streak-copy'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TogescColors.of(context).textSecondary,
              ),
        ),
      ],
    );

    // Bloques con entrada escalonada (sube 12 px con fade, 60 ms por índice).
    var index = 0;
    Widget rise(Widget child) =>
        StaggeredEntrance(index: index++, child: child);

    final left = <Widget>[
      rise(hero),
      if (resumeRow != null) ...[
        const SizedBox(height: DesignTokens.spacingLg),
        rise(resumeRow),
      ],
      const SizedBox(height: DesignTokens.spacingLg + 8),
      rise(freePractice),
    ];
    final right = <Widget>[
      rise(earMap),
      const SizedBox(height: DesignTokens.spacingLg + 8),
      rise(recentDays),
    ];

    const padding = EdgeInsets.fromLTRB(
      DesignTokens.marginMobile,
      0,
      DesignTokens.marginMobile,
      DesignTokens.marginDesktop,
    );

    if (!desktop) {
      return Scaffold(
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: homeContentMaxWidth),
                child: Padding(
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...header,
                      ...left,
                      const SizedBox(height: DesignTokens.spacingLg + 8),
                      ...right,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: homeDesktopMaxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.marginDesktop,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...header,
                  Expanded(
                    child: Row(
                      key: const ValueKey('home-desktop-columns'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: homeDesktopLeftFlex,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(
                              bottom: DesignTokens.marginDesktop,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: left,
                            ),
                          ),
                        ),
                        const SizedBox(width: 28),
                        Expanded(
                          flex: homeDesktopRightFlex,
                          child: SingleChildScrollView(
                            key: const ValueKey('home-desktop-right'),
                            padding: const EdgeInsets.only(
                              bottom: DesignTokens.marginDesktop,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: right,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
