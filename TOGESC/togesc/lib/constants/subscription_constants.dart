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

  /// Clave de `/paywall?feature=` que usa Estadísticas para el historial.
  static const historyFeatureKey = 'historial';

  /// Valores de `feature` que la app genera hoy, con el texto que se muestra.
  ///
  /// PT-10: el parámetro llega por URL (deep link), así que solo se pinta si
  /// está en esta lista; cualquier otro valor cae al título genérico.
  static final Map<String, String> paywallFeatureTitles = {
    for (final mode in proGameModes) modeProLabel(mode): modeProLabel(mode),
    historyFeatureKey: historyFeatureKey,
  };

  /// Texto seguro para [feature], o `null` si no es una función Pro conocida.
  static String? paywallFeatureTitle(String? feature) =>
      feature == null ? null : paywallFeatureTitles[feature];
}
