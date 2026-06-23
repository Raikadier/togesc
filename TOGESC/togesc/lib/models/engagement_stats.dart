import '../constants/game_constants.dart';

/// Estadisticas de dominio por modo de juego (agregado desde historial).
class ModeMasteryStats {
  final GameMode mode;
  final int sessionsCount;
  final int totalRounds;
  final int correctRounds;

  const ModeMasteryStats({
    required this.mode,
    required this.sessionsCount,
    required this.totalRounds,
    required this.correctRounds,
  });

  double get accuracyPercent =>
      totalRounds > 0 ? (correctRounds / totalRounds) * 100 : 0;

  String get masteryLabel {
    if (sessionsCount == 0) return 'Nuevo';
    final acc = accuracyPercent;
    if (acc >= 85) return '${acc.round()}% dominio';
    if (acc >= 60) return 'Nivel ${(acc / 20).floor().clamp(1, 4)}';
    return 'En progreso';
  }
}

/// Metricas de engagement para UI Stitch (racha, XP, mastery).
class EngagementStats {
  final int currentStreakDays;
  final int totalXp;
  final int xpTowardNextMilestone;
  final int xpMilestoneSize;
  final List<ModeMasteryStats> modeMastery;

  const EngagementStats({
    required this.currentStreakDays,
    required this.totalXp,
    required this.xpTowardNextMilestone,
    this.xpMilestoneSize = 100,
    required this.modeMastery,
  });

  double get milestoneProgress =>
      xpMilestoneSize > 0 ? xpTowardNextMilestone / xpMilestoneSize : 0;

  ModeMasteryStats? masteryFor(GameMode mode) {
    for (final item in modeMastery) {
      if (item.mode == mode) return item;
    }
    return null;
  }
}
