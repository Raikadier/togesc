import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import '../utils/frequency_to_note.dart';
import '../utils/pitch_estimation.dart';

/// Deteccion experimental de pitch en Android/iOS/desktop (Fase 7E-3).
abstract final class MicrophonePitchService {
  static const _sampleRateInt = 44100;
  static const _sampleRate = 44100.0;

  static final AudioRecorder _recorder = AudioRecorder();
  static StreamSubscription<Uint8List>? _subscription;
  static void Function(String note)? _onNote;
  static String? _lastNote;
  static int _stableCount = 0;

  static bool get isSupported => true;

  static Future<bool> startListening({
    required void Function(String note) onNoteDetected,
    void Function(String message)? onStatus,
  }) async {
    await stopListening();
    _onNote = onNoteDetected;
    _lastNote = null;
    _stableCount = 0;

    try {
      if (!await _recorder.hasPermission()) {
        onStatus?.call('Permiso de microfono denegado.');
        return false;
      }

      final stream = await _recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRateInt,
          numChannels: 1,
        ),
      );

      _subscription = stream.listen(
        (chunk) => _handleChunk(chunk, onStatus),
        onError: (_) {
          onStatus?.call('Error al leer el microfono.');
        },
      );

      onStatus?.call('Escuchando... canta o tararea la nota.');
      return true;
    } catch (_) {
      onStatus?.call('No se pudo acceder al microfono.');
      await stopListening();
      return false;
    }
  }

  static void _handleChunk(
    Uint8List chunk,
    void Function(String message)? onStatus,
  ) {
    if (chunk.isEmpty) return;

    final samples = pcm16BytesToFloat32(chunk);
    final frequency = estimatePitchFrequency(
      samples,
      sampleRate: _sampleRate,
    );
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

  static Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    _onNote = null;
    _lastNote = null;
    _stableCount = 0;
  }
}
