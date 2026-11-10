import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/models/last_practice_session.dart';
import 'package:togesc/models/practice_session_preferences.dart';
import 'package:togesc/providers/clock_provider.dart';
import 'package:togesc/providers/practice_session_preferences_provider.dart';
import 'package:togesc/providers/session_history_provider.dart';
import 'package:togesc/providers/srs_provider.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/providers/today_session_provider.dart';
import 'package:togesc/utils/calendar_week.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 9, 18)),
        progressRepositoryProvider.overrideWithValue(
          InMemoryProgressRepository(),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('plan de hoy: 12 rondas y 6 min estimados por defecto', () async {
    await container.read(practiceSessionPreferencesProvider.future);
    await container.read(srsSystemProvider.future);
    final plan = container.read(todaySessionPlanProvider);
    // Sin datos SRS: foco de fallback con tres notas naturales.
    expect(plan.focusNoteNames, ['C', 'D', 'E']);
    expect(plan.roundGoal, SessionRoundGoal.twelve);
    expect(plan.rounds, 12);
    expect(plan.estimatedMinutes, 6);
  });

  test('semana y delta usan el reloj inyectado y el historial', () async {
    await container.read(sessionHistoryProvider.future);
    await container.read(practiceSessionPreferencesProvider.future);
    await container.read(sessionHistoryProvider.notifier).record(
          mode: GameMode.singleNote,
          kind: PracticeKind.game,
          roundsCompleted: 12,
          correctRounds: 9,
          endedAt: DateTime(2026, 10, 8, 10),
        );

    final week = container.read(calendarWeekProvider);
    expect(week.monday, DateTime(2026, 10, 5));
    expect(week.days[3].status, WeekDayStatus.completed);
    expect(week.practicedDays, 1);

    final delta = container.read(weeklyAccuracyDeltaProvider);
    expect(delta.currentPercent, closeTo(75, 0.001));
    expect(delta.deltaPoints, isNull);
  });

  test('retomar sin practica previa es null', () async {
    await container.read(sessionHistoryProvider.future);
    expect(container.read(resumeSessionProvider), isNull);
  });
}
