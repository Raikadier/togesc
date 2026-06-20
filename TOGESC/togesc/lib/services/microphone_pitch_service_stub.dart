/// Deteccion de pitch por microfono (stub fuera de web).
abstract final class MicrophonePitchService {
  static bool get isSupported => false;

  static Future<bool> startListening({
    required void Function(String note) onNoteDetected,
    void Function(String message)? onStatus,
  }) async {
    onStatus?.call('El modo canto solo esta disponible en web por ahora.');
    return false;
  }

  static Future<void> stopListening() async {}
}
