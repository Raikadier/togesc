/// Objetivo de rondas por sesion de practica (Fase 7B-2).
enum SessionRoundGoal {
  unlimited(0, 'Sin limite'),
  five(5, '5 rondas'),
  ten(10, '10 rondas'),
  twenty(20, '20 rondas');

  const SessionRoundGoal(this.rounds, this.label);

  final int rounds;
  final String label;

  static SessionRoundGoal fromRounds(int? value) {
    if (value == null || value <= 0) return unlimited;
    for (final goal in SessionRoundGoal.values) {
      if (goal.rounds == value) return goal;
    }
    return unlimited;
  }
}

/// Preferencias de flujo de sesion (Fase 7B).
class PracticeSessionPreferences {
  final SessionRoundGoal roundGoal;
  final bool autoAdvanceAfterResult;

  const PracticeSessionPreferences({
    this.roundGoal = SessionRoundGoal.unlimited,
    this.autoAdvanceAfterResult = false,
  });

  int get targetRounds => roundGoal.rounds;

  bool get hasRoundGoal => roundGoal != SessionRoundGoal.unlimited;

  PracticeSessionPreferences copyWith({
    SessionRoundGoal? roundGoal,
    bool? autoAdvanceAfterResult,
  }) {
    return PracticeSessionPreferences(
      roundGoal: roundGoal ?? this.roundGoal,
      autoAdvanceAfterResult:
          autoAdvanceAfterResult ?? this.autoAdvanceAfterResult,
    );
  }
}
