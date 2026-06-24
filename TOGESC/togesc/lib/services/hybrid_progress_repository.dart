import '../models/note_data.dart';
import '../utils/progress_merge.dart';
import 'progress_repository.dart';
import 'sync_pending_store.dart';

/// Local primero; sincroniza con remoto cuando hay sesion autenticada.
class HybridProgressRepository implements ProgressRepository {
  HybridProgressRepository({
    required ProgressRepository local,
    required Future<ProgressRepository?> Function() remoteFactory,
    SyncPendingStore? syncPendingStore,
  })  : _local = local,
        _remoteFactory = remoteFactory,
        _syncPending = syncPendingStore ?? SyncPendingStore();

  final ProgressRepository _local;
  final Future<ProgressRepository?> Function() _remoteFactory;
  final SyncPendingStore _syncPending;

  /// Repositorio local interno (SharedPreferences).
  ProgressRepository get local => _local;

  Future<ProgressRepository?> _remote() => _remoteFactory();

  /// Hay cambios locales pendientes de subir a la nube.
  Future<bool> get hasPendingSync => _syncPending.isPending;

  Future<void> _persistMerged({
    required Map<String, NoteData> merged,
    required String? mergedSession,
    required ProgressRepository remote,
  }) async {
    await _local.save(merged, lastSession: mergedSession);
    try {
      await remote.save(merged, lastSession: mergedSession);
      await _syncPending.clear();
    } catch (_) {
      await _syncPending.markPending();
    }
  }

  @override
  Future<Map<String, NoteData>?> load() async {
    final localData = await _local.load();
    final localSession = await _local.loadLastSessionIso();
    final remote = await _remote();
    if (remote == null) return localData;

    final remoteData = await remote.load();
    final remoteSession = await remote.loadLastSessionIso();

    if (remoteData == null) return localData;
    if (localData == null) {
      await _local.save(remoteData, lastSession: remoteSession);
      await _syncPending.clear();
      return remoteData;
    }

    final merged = ProgressMerge.mergeMaps(localData, remoteData);
    final mergedSession =
        ProgressMerge.pickNewerSession(localSession, remoteSession);
    await _persistMerged(
      merged: merged,
      mergedSession: mergedSession,
      remote: remote,
    );
    return merged;
  }

  @override
  Future<String?> loadLastSessionIso() async {
    final localSession = await _local.loadLastSessionIso();
    final remote = await _remote();
    if (remote == null) return localSession;

    final remoteSession = await remote.loadLastSessionIso();
    return ProgressMerge.pickNewerSession(localSession, remoteSession);
  }

  @override
  Future<void> save(Map<String, NoteData> noteData, {String? lastSession}) async {
    final session = lastSession ?? DateTime.now().toIso8601String();
    await _local.save(noteData, lastSession: session);

    final remote = await _remote();
    if (remote == null) return;

    try {
      await remote.save(noteData, lastSession: session);
      await _syncPending.clear();
    } catch (_) {
      await _syncPending.markPending();
    }
  }

  /// Sube progreso local pendiente cuando hay conexion y sesion.
  Future<bool> flushPendingSync() async {
    if (!await _syncPending.isPending) return true;

    final remote = await _remote();
    if (remote == null) return false;

    final localData = await _local.load();
    if (localData == null) {
      await _syncPending.clear();
      return true;
    }

    try {
      final localSession = await _local.loadLastSessionIso();
      final remoteData = await remote.load();
      final remoteSession = await remote.loadLastSessionIso();

      final merged = remoteData != null
          ? ProgressMerge.mergeMaps(localData, remoteData)
          : localData;
      final mergedSession =
          ProgressMerge.pickNewerSession(localSession, remoteSession);

      await _persistMerged(
        merged: merged,
        mergedSession: mergedSession,
        remote: remote,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Tras iniciar sesion: fusiona progreso local y remoto por nota.
  Future<void> mergeOnSignIn() async {
    final remote = await _remote();
    if (remote == null) return;

    final localData = await _local.load();
    if (localData == null) {
      final remoteData = await remote.load();
      if (remoteData != null) {
        final remoteSession = await remote.loadLastSessionIso();
        await _local.save(remoteData, lastSession: remoteSession);
      }
      await _syncPending.clear();
      return;
    }

    final localSession = await _local.loadLastSessionIso();
    final remoteData = await remote.load();
    if (remoteData == null) {
      try {
        await remote.save(localData, lastSession: localSession);
        await _syncPending.clear();
      } catch (_) {
        await _syncPending.markPending();
      }
      return;
    }

    final remoteSession = await remote.loadLastSessionIso();
    final merged = ProgressMerge.mergeMaps(localData, remoteData);
    final mergedSession =
        ProgressMerge.pickNewerSession(localSession, remoteSession);
    await _persistMerged(
      merged: merged,
      mergedSession: mergedSession,
      remote: remote,
    );
  }
}
