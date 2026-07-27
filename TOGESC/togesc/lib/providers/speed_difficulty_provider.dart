import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/game_constants.dart';

/// Dificultad elegida en el selector de velocidad (Fácil / Pro / Elite).
final speedDifficultyProvider = StateProvider<SpeedDifficulty>(
  (ref) => SpeedDifficulty.pro,
);
