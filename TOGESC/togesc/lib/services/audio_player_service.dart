import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'audio_generator.dart';
import 'web_audio_playback.dart';

/// Servicio de reproduccion de audio.
///
/// En web usa [WebAudioPlayback] (HTMLAudioElement). En desktop/movil usa
/// flutter_soloud. Se inicializa con [initialize] y se limpia con [dispose].
class AudioPlayerService {
  final AudioGenerator generator;
  SoLoud? _soloud;
  WebAudioPlayback? _webPlayer;
  bool _initialized = false;
  bool _unlockedByUserGesture = false;
  Future<bool>? _initFuture;
  int _playCounter = 0;
  double _masterVolume = 1.0;

  bool get isInitialized => _initialized;
  bool get isAvailable => _initialized;
  double get masterVolume => _masterVolume;

  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
  }

  AudioPlayerService({
    AudioGenerator? generator,
    SoLoud? soloud,
  })  : generator = generator ?? AudioGenerator(),
        _soloud = soloud;

  /// En web, llamar sincronicamente desde onPressed/onTap antes de cualquier await.
  void captureUserGesture() {
    if (kIsWeb) {
      _unlockedByUserGesture = true;
      _webPlayer ??= WebAudioPlayback();
      _webPlayer!.unlockForUserGesture();
      _kickInit();
      return;
    }
    _kickInit();
  }

  /// Espera a que el motor de audio este listo (precalentamiento en web).
  Future<bool> waitUntilReady() async {
    _kickInit();
    if (_initialized) return true;
    final pending = _initFuture;
    if (pending != null) return pending;
    return initialize();
  }

  void _kickInit() {
    if (_initialized || _initFuture != null) return;
    if (kIsWeb && !_unlockedByUserGesture) return;

    _initFuture = initialize().whenComplete(() {
      _initFuture = null;
    });
  }

  /// Inicializa el motor de audio.
  Future<bool> initialize() async {
    if (_initialized) return true;
    if (kIsWeb && !_unlockedByUserGesture) return false;

    if (kIsWeb) {
      _webPlayer ??= WebAudioPlayback();
      _webPlayer!.unlockForUserGesture();
      _initialized = true;
      return true;
    }

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

  Future<bool> _ensureInitialized() async {
    if (kIsWeb && _initialized && !_unlockedByUserGesture) {
      await dispose();
    }
    return waitUntilReady();
  }

  /// Reproduce un buffer de audio.
  Future<void> playBuffer(Float64List samples, {int? sampleRate}) async {
    if (!await _ensureInitialized()) return;

    final scaled = _masterVolume >= 0.999
        ? samples
        : Float64List.fromList(
            samples.map((s) => s * _masterVolume).toList(),
          );

    final wavBytes = Uint8List.fromList(
      generator.float64ListToWavBytes(
        scaled,
        sr: sampleRate ?? generator.sampleRate,
      ),
    );

    if (kIsWeb) {
      try {
        await _webPlayer?.playWav(wavBytes);
      } catch (_) {
        // Reproduccion fallida: no interrumpir el flujo del juego
      }
      return;
    }

    if (_soloud == null) return;

    AudioSource? source;
    try {
      final key = 'tone_${_playCounter++}.wav';
      source = await _soloud!.loadMem(
        key,
        wavBytes,
        mode: LoadMode.memory,
      );
      final finished = source.allInstancesFinished.first;
      await _soloud!.play(source, volume: 1.0);
      await finished;
    } catch (_) {
      // Reproduccion fallida: no interrumpir el flujo del juego
    } finally {
      if (source != null) {
        try {
          await _soloud!.disposeSource(source);
        } catch (_) {}
      }
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
    if (!await _ensureInitialized()) return false;
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
    if (kIsWeb) {
      _webPlayer?.dispose();
      _webPlayer = null;
    } else if (_initialized && _soloud != null) {
      try {
        _soloud!.deinit();
      } catch (_) {}
    }
    _initialized = false;
    _initFuture = null;
    if (kIsWeb) _unlockedByUserGesture = false;
  }
}
