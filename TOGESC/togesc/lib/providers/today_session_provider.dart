import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/srs_constants.dart';
import '../models/practice_session_log.dart';
import '../models/practice_session_preferences.dart';
import '../services/engagement_stats_service.dart';
import '../utils/calendar_week.dart';
import '../utils/today_session.dart';
import 'app_preferences_provider.dart';
import 'clock_provider.dart';
import 'last_practice_provider.dart';
import 'practice_session_preferences_provider.dart';
import 'session_history_provider.dart';
import 'srs_intensity_provider.dart';
import 'srs_provider.dart';

/// Umbral de graduación del perfil SRS activo (para `srsLevel`).
final srsLearningThresholdProvider = Provider<int>((ref) {
  return ref.watch(srsIntensityProfileProvider).valueOrNull?.learningThreshold ??
      learningPhaseThreshold;
});

/// Notas foco elegidas a mano en «Ajustar enfoque y duración» para un día.
/// Solo valen ese día: al día siguiente vuelve la propuesta del SRS.
class TodayFocusOverride {
  final DateTime day;
  final List<String> notes;

  const TodayFocusOverride({required this.day, required this.notes});

  bool appliesTo(DateTime now) =>
      day.year == now.year && day.month == now.month && day.day == now.day;
}

/// Enfoque elegido a mano (en memoria; `null` = propuesta del SRS).
final todayFocusOverrideProvider =
    StateProvider<TodayFocusOverride?>((ref) => null);

/// Notas de foco de la «Sesión de hoy»: las elegidas hoy a mano (1–4) o,
/// si no hay, hasta 3 propuestas por el SRS (D11), deterministas.
/// Vacía mientras el SRS carga. Ver `selectTodayFocusNotes`.
final todayFocusNotesProvider = Provider<List<TodayFocusNote>>((ref) {
  final summaries = ref.watch(noteProgressSummariesProvider);
  final recommendations = ref.watch(practiceRecommendationsProvider);
  final override = ref.watch(todayFocusOverrideProvider);
  final now = ref.watch(clockProvider)();
  if (override != null && override.appliesTo(now)) {
    final chosen = buildChosenFocusNotes(
      notes: override.notes,
      summaries: summaries,
      criticalNotes: criticalNotesFromRecommendations(recommendations),
      learningThreshold: ref.watch(srsLearningThresholdProvider),
    );
    if (chosen.isNotEmpty) return chosen;
  }
  final pool =
      ref.watch(appPreferencesProvider).valueOrNull?.practiceNotePool ??
          const <String>[];
  return selectTodayFocusNotes(
    summaries: summaries,
    criticalNotes: criticalNotesFromRecommendations(recommendations),
    allowedNotes: pool,
    learningThreshold: ref.watch(srsLearningThresholdProvider),
  );
});

/// Plan de la «Sesión de hoy» para el hero del Home.
class TodaySessionPlan {
  final List<TodayFocusNote> focusNotes;

  /// Meta de rondas de la sesión (preferencia; por defecto 12).
  final SessionRoundGoal roundGoal;

  /// El usuario eligió hoy las notas foco a mano.
  final bool isCustomFocus;

  const TodaySessionPlan({
    required this.focusNotes,
    required this.roundGoal,
    this.isCustomFocus = false,
  });

  /// Rondas de la sesión; 0 = «Sin límite».
  int get rounds => roundGoal.rounds;

  /// ESTIMACIÓN (rondas × `estimatedSecondsPerRound`); `null` sin límite.
  Duration? get estimatedDuration => roundGoal.estimatedDuration;

  /// Minutos ESTIMADOS («12 rondas · 6 min»); `null` sin límite.
  int? get estimatedMinutes => roundGoal.estimatedMinutes;

  /// Notas para `setPracticeFocusNotes` al pulsar «Empezar sesión».
  List<String> get focusNoteNames => [for (final f in focusNotes) f.note];
}

/// Plan de hoy: foco + meta de rondas. Mientras cargan las preferencias usa
/// la meta por defecto ([defaultSessionRoundGoal]).
final todaySessionPlanProvider = Provider<TodaySessionPlan>((ref) {
  final prefs = ref.watch(practiceSessionPreferencesProvider).valueOrNull ??
      const PracticeSessionPreferences();
  final override = ref.watch(todayFocusOverrideProvider);
  final now = ref.watch(clockProvider)();
  return TodaySessionPlan(
    focusNotes: ref.watch(todayFocusNotesProvider),
    roundGoal: prefs.roundGoal,
    isCustomFocus: override != null && override.appliesTo(now),
  );
});

/// Fila «Retomar»: último modo con sus rondas y su hora. `null` si no hay
/// ninguna práctica previa.
final resumeSessionProvider = Provider<ResumeSessionInfo?>((ref) {
  final last = ref.watch(lastPracticeSessionProvider).valueOrNull;
  final history = ref.watch(sessionHistoryProvider).valueOrNull ?? const [];
  return buildResumeSessionInfo(last: last, history: history);
});

/// Semana natural L–D con el estado de cada día. La meta diaria es la meta de
/// rondas del usuario si tiene una (> 0), o [defaultDailyGoalRounds] (12).
final calendarWeekProvider = Provider<CalendarWeek>((ref) {
  final history = ref.watch(sessionHistoryProvider).valueOrNull ?? const [];
  final target = ref
          .watch(practiceSessionPreferencesProvider)
          .valueOrNull
          ?.targetRounds ??
      0;
  final now = ref.watch(clockProvider)();
  return buildCalendarWeek(
    history,
    now: now,
    dailyGoalRounds: target > 0 ? target : defaultDailyGoalRounds,
  );
});

/// Meta diaria de la tira de días: la meta de rondas del usuario si tiene
/// una (> 0), o [defaultDailyGoalRounds] (12).
final dailyGoalRoundsProvider = Provider<int>((ref) {
  final target = ref
          .watch(practiceSessionPreferencesProvider)
          .valueOrNull
          ?.targetRounds ??
      0;
  return target > 0 ? target : defaultDailyGoalRounds;
});

/// «Últimos 7 días» del Home v2.1: de hace 6 días a hoy.
final recentDaysProvider = Provider<CalendarWeek>((ref) {
  final history = ref.watch(sessionHistoryProvider).valueOrNull ?? const [];
  return buildRecentDays(
    history,
    now: ref.watch(clockProvider)(),
    dailyGoalRounds: ref.watch(dailyGoalRoundsProvider),
  );
});

/// Estado de la racha para la frase bajo la tira de días.
class HomeStreakStatus {
  /// Hoy hay al menos una ronda registrada.
  final bool practicedToday;

  /// Con [practicedToday], días seguidos incluido hoy. Sin practicar hoy,
  /// la racha que se alcanzaría practicando hoy (racha hasta ayer + 1).
  final int days;

  const HomeStreakStatus({required this.practicedToday, required this.days});

  /// Calcula el estado con `EngagementStatsService.computeStreakDays`,
  /// que solo cuenta la racha si se practicó hoy.
  factory HomeStreakStatus.fromHistory(
    List<PracticeSessionLog> history, {
    required DateTime now,
  }) {
    final played = history.where((e) => e.roundsCompleted > 0).toList();
    final today = DateTime(now.year, now.month, now.day);
    final practicedToday = played.any((e) {
      final d = e.endedAt.toLocal();
      return DateTime(d.year, d.month, d.day) == today;
    });
    if (practicedToday) {
      return HomeStreakStatus(
        practicedToday: true,
        days: EngagementStatsService.computeStreakDays(played, now: now),
      );
    }
    final yesterday = DateTime(now.year, now.month, now.day - 1, 12);
    return HomeStreakStatus(
      practicedToday: false,
      days: EngagementStatsService.computeStreakDays(played, now: yesterday) +
          1,
    );
  }
}

final homeStreakStatusProvider = Provider<HomeStreakStatus>((ref) {
  final history = ref.watch(sessionHistoryProvider).valueOrNull ?? const [];
  return HomeStreakStatus.fromHistory(
    history,
    now: ref.watch(clockProvider)(),
  );
});

/// Delta de precisión por rondas: últimos 7 días frente a los 7 anteriores.
final weeklyAccuracyDeltaProvider = Provider<WeeklyAccuracyDelta>((ref) {
  final history = ref.watch(sessionHistoryProvider).valueOrNull ?? const [];
  final now = ref.watch(clockProvider)();
  return buildWeeklyAccuracyDelta(history, now: now);
});
