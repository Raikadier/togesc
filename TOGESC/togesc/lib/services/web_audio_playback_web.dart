import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

/// Reproduccion WAV en navegador via HTMLAudioElement (fiable con autoplay).
class WebAudioPlayback {
  bool _unlocked = false;

  /// Debe llamarse sincronicamente desde onPressed/onTap (sin await previo).
  void unlockForUserGesture() {
    if (_unlocked) return;
    final audio = HTMLAudioElement()
      ..src = _silentWavDataUrl
      ..volume = 0.01;
    audio.play(); // ignore: discarded_futures
    _unlocked = true;
  }

  Future<void> playWav(Uint8List wavBytes) async {
    if (!_unlocked) unlockForUserGesture();

    final blob = Blob([wavBytes.toJS].toJS);
    final url = URL.createObjectURL(blob);
    final audio = HTMLAudioElement()..src = url;

    final completer = Completer<void>();
    void finish(Event _) {
      URL.revokeObjectURL(url);
      if (!completer.isCompleted) completer.complete();
    }

    audio.onended = finish.toJS;
    audio.onerror = finish.toJS;

    try {
      await audio.play().toDart;
      await completer.future;
    } catch (_) {
      URL.revokeObjectURL(url);
      rethrow;
    }
  }

  void dispose() {
    _unlocked = false;
  }
}

/// WAV silencioso minimo (16-bit mono, ~10 ms).
const _silentWavDataUrl =
    'data:audio/wav;base64,UklGRigAAABXQVZFZm10IBIAAAABAAEARKwAAIhYAQACABAAAABkYXRhAgAAAAEA';
