/// Objetivo de rondas por sesion de practica (Fase 7B-2).
enum SessionRoundGoal {
  unlimited(0, 'Sin límite'),
  five(5, '5 rondas'),
  ten(10, '10 rondas'),
  twelve(12, '12 rondas'),
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

  /// Duración **estimada** de la sesión (no medida): rondas ×
  /// [estimatedSecondsPerRound]. `null` para «Sin límite».
  Duration? get estimatedDuration => estimateSessionDuration(rounds);

  /// Minutos **estimados**, redondeados hacia arriba. `null` si no hay meta.
  int? get estimatedMinutes => estimateSessionMinutes(rounds);
}

/// Meta de rondas por defecto (rediseño v2, D3): la «Sesión de hoy» son 12.
const SessionRoundGoal defaultSessionRoundGoal = SessionRoundGoal.twelve;

/// Avance automático tras el resultado por defecto (rediseño v2, D2).
/// Se puede desactivar en Ajustes por accesibilidad.
const bool defaultAutoAdvanceAfterResult = true;

/// Tiempo que se muestra el resultado antes de avanzar solo (v2: 2,2 s).
const Duration resultAutoAdvanceDelay = Duration(milliseconds: 2200);

/// Igual que [resultAutoAdvanceDelay] con movimiento reducido.
const Duration resultAutoAdvanceDelayReducedMotion =
    Duration(milliseconds: 400);

/// ESTIMACIÓN declarada de segundos por ronda (escucha + respuesta +
/// resultado). No se mide la duración real de las sesiones; este valor solo
/// sirve para el texto «12 rondas · 6 min». Si algún día se registra la
/// duración real, sustituir por la media medida.
const int estimatedSecondsPerRound = 30;

/// Duración estimada de [rounds] rondas; `null` si [rounds] <= 0.
Duration? estimateSessionDuration(int rounds) {
  if (rounds <= 0) return null;
  return Duration(seconds: rounds * estimatedSecondsPerRound);
}

/// Minutos estimados (techo) de [rounds] rondas; `null` si [rounds] <= 0.
int? estimateSessionMinutes(int rounds) {
  final duration = estimateSessionDuration(rounds);
  if (duration == null) return null;
  return (duration.inSeconds + 59) ~/ 60;
}

/// Preferencias de flujo de sesion (Fase 7B).
class PracticeSessionPreferences {
  final SessionRoundGoal roundGoal;
  final bool autoAdvanceAfterResult;

  const PracticeSessionPreferences({
    this.roundGoal = defaultSessionRoundGoal,
    this.autoAdvanceAfterResult = defaultAutoAdvanceAfterResult,
  });

  int get targetRounds => roundGoal.rounds;

  bool get hasRoundGoal => roundGoal != SessionRoundGoal.unlimited;

  /// Duración estimada de la sesión (ver [estimatedSecondsPerRound]).
  Duration? get estimatedDuration => roundGoal.estimatedDuration;

  /// Minutos estimados de la sesión (ver [estimatedSecondsPerRound]).
  int? get estimatedMinutes => roundGoal.estimatedMinutes;

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
