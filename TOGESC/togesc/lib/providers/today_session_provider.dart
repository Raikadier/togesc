import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/srs_constants.dart';
import '../models/practice_session_preferences.dart';
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

/// Hasta 3 notas de foco de la «Sesión de hoy» (D11), deterministas.
/// Vacía mientras el SRS carga. Ver `selectTodayFocusNotes`.
final todayFocusNotesProvider = Provider<List<TodayFocusNote>>((ref) {
  final summaries = ref.watch(noteProgressSummariesProvider);
  final recommendations = ref.watch(practiceRecommendationsProvider);
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

  const TodaySessionPlan({required this.focusNotes, required this.roundGoal});

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
  return TodaySessionPlan(
    focusNotes: ref.watch(todayFocusNotesProvider),
    roundGoal: prefs.roundGoal,
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

/// Delta de precisión por rondas: últimos 7 días frente a los 7 anteriores.
final weeklyAccuracyDeltaProvider = Provider<WeeklyAccuracyDelta>((ref) {
  final history = ref.watch(sessionHistoryProvider).valueOrNull ?? const [];
  final now = ref.watch(clockProvider)();
  return buildWeeklyAccuracyDelta(history, now: now);
});
