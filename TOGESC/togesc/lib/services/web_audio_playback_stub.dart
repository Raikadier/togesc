import 'dart:typed_data';

/// Implementacion vacia para plataformas que no son web.
class WebAudioPlayback {
  void unlockForUserGesture() {}

  Future<void> playWav(Uint8List wavBytes) async {}

  void dispose() {}
}
