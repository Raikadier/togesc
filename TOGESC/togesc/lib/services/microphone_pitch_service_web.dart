import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data' as typed_data;

import 'package:web/web.dart';

import '../utils/frequency_to_note.dart';

/// Deteccion experimental de pitch en navegador (Fase 7E-3 spike).
abstract final class MicrophonePitchService {
  static bool get isSupported => true;

  static MediaStream? _stream;
  static AudioContext? _context;
  static AnalyserNode? _analyser;
  static Timer? _timer;
  static void Function(String note)? _onNote;
  static String? _lastNote;
  static int _stableCount = 0;

  static Future<bool> startListening({
    required void Function(String note) onNoteDetected,
    void Function(String message)? onStatus,
  }) async {
    await stopListening();
    _onNote = onNoteDetected;
    _lastNote = null;
    _stableCount = 0;

    try {
      _stream = await window.navigator.mediaDevices
          .getUserMedia(MediaStreamConstraints(audio: true.toJS))
          .toDart;

      _context = AudioContext();
      final source = _context!.createMediaStreamSource(_stream!);
      _analyser = _context!.createAnalyser();
      _analyser!.fftSize = 2048;
      source.connect(_analyser!);

      _timer = Timer.periodic(const Duration(milliseconds: 120), (_) {
        _pollAnalyser(onStatus);
      });
      onStatus?.call('Escuchando... canta o tararea la nota.');
      return true;
    } catch (_) {
      onStatus?.call('No se pudo acceder al microfono.');
      await stopListening();
      return false;
    }
  }

  static void _pollAnalyser(void Function(String message)? onStatus) {
    final analyser = _analyser;
    if (analyser == null) return;

    final buffer = typed_data.Float32List(analyser.fftSize);
    analyser.getFloatTimeDomainData(buffer.toJS);
    final frequency = _estimateFrequency(buffer);
    if (frequency == null) return;

    final note = frequencyToNote(frequency);
    if (note == null) return;

    if (note == _lastNote) {
      _stableCount += 1;
    } else {
      _lastNote = note;
      _stableCount = 1;
    }

    if (_stableCount >= 4) {
      _onNote?.call(note);
      _stableCount = 0;
      onStatus?.call('Nota detectada: $note');
    }
  }

  static double? _estimateFrequency(typed_data.Float32List samples) {
    if (samples.length < 64) return null;

    var peak = 0.0;
    for (var i = 0; i < samples.length; i++) {
      final abs = samples[i].abs();
      if (abs > peak) peak = abs;
    }
    if (peak < 0.02) return null;

    var bestLag = 0;
    var bestCorr = 0.0;
    const minLag = 32;
    final maxLag = samples.length ~/ 2;

    for (var lag = minLag; lag < maxLag; lag++) {
      var corr = 0.0;
      for (var i = 0; i < maxLag; i++) {
        corr += samples[i] * samples[i + lag];
      }
      if (corr > bestCorr) {
        bestCorr = corr;
        bestLag = lag;
      }
    }

    if (bestLag <= 0 || _context == null) return null;
    final frequency = _context!.sampleRate / bestLag;
    if (frequency < 80 || frequency > 1200) return null;
    return frequency;
  }

  static Future<void> stopListening() async {
    _timer?.cancel();
    _timer = null;
    _analyser = null;
    _context?.close();
    _context = null;
    for (final track in _stream?.getTracks().toDart ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    _stream = null;
    _onNote = null;
    _lastNote = null;
    _stableCount = 0;
  }
}
