import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

import 'audio_generator.dart';

/// Servicio de reproduccion de audio.
///
/// Abstraccion sobre flutter_soloud para reproducir buffers PCM generados
/// por [AudioGenerator]. Se inicializa con [initialize] y se limpia con [dispose].
class AudioPlayerService {
  final AudioGenerator generator;
  SoLoud? _soloud;
  bool _initialized = false;
  int _playCounter = 0;

  bool get isInitialized => _initialized;
  bool get isAvailable => _initialized;

  AudioPlayerService({
    AudioGenerator? generator,
    SoLoud? soloud,
  })  : generator = generator ?? AudioGenerator(),
        _soloud = soloud;

  /// Inicializa el motor de audio.
  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      _soloud ??= SoLoud.instance;
      await _soloud!.init(automaticCleanup: true);
      _initialized = true;
      return true;
    } catch (_) {
      _initialized = false;
      return false;
    }
  }

  /// Reproduce un buffer de audio.
  Future<void> playBuffer(Float64List samples, {int? sampleRate}) async {
    if (!_initialized || _soloud == null) return;

    final wavBytes = generator.float64ListToWavBytes(
      samples,
      sr: sampleRate ?? generator.sampleRate,
    );

    try {
      final key = 'tone_${_playCounter++}.wav';
      final source = await _soloud!.loadMem(
        key,
        Uint8List.fromList(wavBytes),
      );
      await _soloud!.play(source);
    } catch (_) {
      // Reproduccion fallida: no interrumpir el flujo del juego
    }
  }

  /// Reproduce tonos con frecuencias dadas.
  Future<String> playTones(
    List<double> frequencies, {
    double? duration,
    String? instrument,
  }) async {
    final (buffer, inst) = generator.mixTones(
      frequencies,
      duration: duration,
      instrument: instrument,
    );
    await playBuffer(buffer);
    return inst;
  }

  /// Reproduce cluster de limpieza.
  Future<void> playCluster({double? duration}) async {
    final buffer = generator.generateCluster(duration: duration ?? 3.0);
    await playBuffer(buffer);
  }

  /// Prueba rapida de audio.
  Future<bool> testAudio() async {
    if (!_initialized) return false;
    try {
      final tone = generator.generateTone(440, duration: 0.1);
      await playBuffer(tone);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Libera recursos.
  Future<void> dispose() async {
    if (_initialized && _soloud != null) {
      try {
        _soloud!.deinit();
      } catch (_) {}
    }
    _initialized = false;
  }
}
