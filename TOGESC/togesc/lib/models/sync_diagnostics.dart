import '../utils/session_timestamp.dart';

/// Estado de sincronizacion local vs nube.
class SyncDiagnostics {
  const SyncDiagnostics({
    required this.cloudSyncEnabled,
    required this.hasSession,
    this.localSession,
    this.remoteSession,
    this.pendingUpload = false,
    this.remoteReachable = false,
  });

  final bool cloudSyncEnabled;
  final bool hasSession;
  final String? localSession;
  final String? remoteSession;
  final bool pendingUpload;
  final bool remoteReachable;

  static bool sessionsMatch(String? a, String? b) =>
      SessionTimestamp.match(a, b);

  bool get isInSync {
    if (!cloudSyncEnabled || !hasSession) return true;
    if (pendingUpload) return false;
    if (localSession == null && remoteSession == null) return true;
    return sessionsMatch(localSession, remoteSession);
  }

  String get statusLabel {
    if (!cloudSyncEnabled) {
      return 'Sync en nube requiere plan Pro (o monetizacion desactivada).';
    }
    if (!hasSession) return 'Inicia sesion para sincronizar.';
    if (pendingUpload) return 'Cambios locales pendientes de subir.';
    if (!remoteReachable) return 'No se pudo contactar la nube.';
    if (isInSync) return 'Local y nube alineados.';
    if (localSession != null &&
        remoteSession != null &&
        !sessionsMatch(localSession, remoteSession)) {
      return 'Local y nube difieren; pulsa Sincronizar.';
    }
    return 'Listo para sincronizar.';
  }
}
