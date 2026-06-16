import '../models/note_data.dart';
import 'progress_repository.dart';
import 'sync_pending_store.dart';

DateTime? _parseSession(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  return DateTime.tryParse(iso);
}

bool _isRemoteNewer(String? localIso, String? remoteIso) {
  final local = _parseSession(localIso);
  final remote = _parseSession(remoteIso);
  if (remote == null) return false;
  if (local == null) return true;
  return remote.isAfter(local);
}

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

    if (_isRemoteNewer(localSession, remoteSession)) {
      await _local.save(remoteData, lastSession: remoteSession);
      await _syncPending.clear();
      return remoteData;
    }

    return localData;
  }

  @override
  Future<String?> loadLastSessionIso() async {
    final localSession = await _local.loadLastSessionIso();
    final remote = await _remote();
    if (remote == null) return localSession;

    final remoteSession = await remote.loadLastSessionIso();
    if (_isRemoteNewer(localSession, remoteSession)) {
      return remoteSession;
    }
    return localSession;
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
      final session = await _local.loadLastSessionIso();
      await remote.save(localData, lastSession: session);
      await _syncPending.clear();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Tras iniciar sesion: sube progreso local si la nube esta vacia o es mas antigua.
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
    if (_isRemoteNewer(localSession, remoteSession)) {
      await _local.save(remoteData, lastSession: remoteSession);
      await _syncPending.clear();
    } else {
      try {
        await remote.save(localData, lastSession: localSession);
        await _syncPending.clear();
      } catch (_) {
        await _syncPending.markPending();
      }
    }
  }
}
