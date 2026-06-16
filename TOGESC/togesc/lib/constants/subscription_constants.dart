import 'game_constants.dart';

/// Planes Free vs Pro (Fase 5).
abstract final class SubscriptionConstants {
  static const proEntitlementId = 'pro';
  static const trialDays = 14;

  /// Modos incluidos en plan Free.
  static const freeGameModes = {
    GameMode.singleNote,
    GameMode.interval,
    GameMode.sharpsOnly,
  };

  /// Modos exclusivos Pro.
  static const proGameModes = {
    GameMode.chord,
    GameMode.random,
    GameMode.speedTraining,
  };

  static bool isModeFree(GameMode mode) => freeGameModes.contains(mode);

  static bool isModePro(GameMode mode) => proGameModes.contains(mode);

  static String modeProLabel(GameMode mode) => switch (mode) {
        GameMode.chord => 'Acordes',
        GameMode.random => 'Modo aleatorio',
        GameMode.speedTraining => 'Entrenamiento de velocidad',
        _ => mode.displayName,
      };
}
