import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/game_constants.dart';
import 'app_preferences_provider.dart';

/// Clave de la mejor racha de velocidad por dificultad (v2.1, SPEC §2.4).
String speedBestStreakKey(SpeedDifficulty difficulty) =>
    'togesc_speed_best_streak_${difficulty.name}';

/// Mejor racha guardada por dificultad (Fácil / Pro / Elite).
///
/// Una dificultad sin ráfagas registradas no aparece en el mapa: la UI
/// muestra «—» en lugar de un 0 inventado (D10).
final speedBestStreakProvider =
    AsyncNotifierProvider<SpeedBestStreakNotifier, Map<SpeedDifficulty, int>>(
      SpeedBestStreakNotifier.new,
    );

class SpeedBestStreakNotifier extends AsyncNotifier<Map<SpeedDifficulty, int>> {
  @override
  Future<Map<SpeedDifficulty, int>> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return {
      for (final d in SpeedDifficulty.values)
        if (prefs.getInt(speedBestStreakKey(d)) case final int best) d: best,
    };
  }

  /// Registra la racha final de una ráfaga. Devuelve `true` si es un
  /// récord personal (supera la mejor racha anterior y es mayor que 0).
  Future<bool> submit(SpeedDifficulty difficulty, int streak) async {
    final current = await future;
    if (streak <= 0 || streak <= (current[difficulty] ?? 0)) return false;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setInt(speedBestStreakKey(difficulty), streak);
    state = AsyncData({...current, difficulty: streak});
    return true;
  }
}
