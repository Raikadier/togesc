import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio_generator.dart';
import '../services/audio_player_service.dart';

/// Provider para el servicio de audio.
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  return AudioPlayerService();
});

/// Provider para el generador de audio (acceso directo para testing).
final audioGeneratorProvider = Provider<AudioGenerator>((ref) {
  return AudioGenerator();
});

/// Provider para el estado de disponibilidad de audio.
final audioAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(audioPlayerServiceProvider);
  return service.initialize();
});
