import '../models/note_data.dart';
import '../models/sync_diagnostics.dart';
import 'hybrid_progress_repository.dart';
import 'progress_repository.dart';

/// Inspecciona y fuerza sincronizacion local/remoto.
class SyncCoordinator {
  SyncCoordinator({
    required HybridProgressRepository hybrid,
    required ProgressRepository local,
    required Future<ProgressRepository?> Function() remoteFactory,
    required bool cloudSyncEnabled,
    required bool hasSession,
  })  : _hybrid = hybrid,
        _local = local,
        _remoteFactory = remoteFactory,
        _cloudSyncEnabled = cloudSyncEnabled,
        _hasSession = hasSession;

  final HybridProgressRepository _hybrid;
  final ProgressRepository _local;
  final Future<ProgressRepository?> Function() _remoteFactory;
  final bool _cloudSyncEnabled;
  final bool _hasSession;

  Future<SyncDiagnostics> diagnose() async {
    final localSession = await _local.loadLastSessionIso();
    final pending = await _hybrid.hasPendingSync;

    if (!_cloudSyncEnabled || !_hasSession) {
      return SyncDiagnostics(
        cloudSyncEnabled: _cloudSyncEnabled,
        hasSession: _hasSession,
        localSession: localSession,
        pendingUpload: pending,
      );
    }

    try {
      final remote = await _remoteFactory();
      if (remote == null) {
        return SyncDiagnostics(
          cloudSyncEnabled: _cloudSyncEnabled,
          hasSession: _hasSession,
          localSession: localSession,
          pendingUpload: pending,
        );
      }

      final remoteSession = await remote.loadLastSessionIso();
      return SyncDiagnostics(
        cloudSyncEnabled: true,
        hasSession: true,
        localSession: localSession,
        remoteSession: remoteSession,
        pendingUpload: pending,
        remoteReachable: true,
      );
    } catch (_) {
      return SyncDiagnostics(
        cloudSyncEnabled: true,
        hasSession: true,
        localSession: localSession,
        pendingUpload: pending,
      );
    }
  }

  /// Fuerza merge bidireccional (login, boton sync, resume app).
  Future<SyncDiagnostics> syncNow() async {
    await _hybrid.mergeOnSignIn();
    await _hybrid.flushPendingSync();
    return diagnose();
  }

  /// Tras guardar progreso en una ronda.
  Future<void> afterLocalSave() async {
    if (!_cloudSyncEnabled || !_hasSession) return;
    await _hybrid.flushPendingSync();
  }
}

/// Expuesto para tests de escenario multi-dispositivo.
Future<Map<String, NoteData>?> loadRemoteProgress(
  Future<ProgressRepository?> Function() remoteFactory,
) async {
  final remote = await remoteFactory();
  if (remote == null) return null;
  return remote.load();
}
