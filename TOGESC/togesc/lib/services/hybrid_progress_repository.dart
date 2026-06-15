import '../models/note_data.dart';
import 'progress_repository.dart';

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
  })  : _local = local,
        _remoteFactory = remoteFactory;

  final ProgressRepository _local;
  final Future<ProgressRepository?> Function() _remoteFactory;

  Future<ProgressRepository?> _remote() => _remoteFactory();

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
      return remoteData;
    }

    if (_isRemoteNewer(localSession, remoteSession)) {
      await _local.save(remoteData, lastSession: remoteSession);
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
    if (remote != null) {
      await remote.save(noteData, lastSession: session);
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
      return;
    }

    final localSession = await _local.loadLastSessionIso();
    final remoteData = await remote.load();
    if (remoteData == null) {
      await remote.save(localData, lastSession: localSession);
      return;
    }

    final remoteSession = await remote.loadLastSessionIso();
    if (_isRemoteNewer(localSession, remoteSession)) {
      await _local.save(remoteData, lastSession: remoteSession);
    } else {
      await remote.save(localData, lastSession: localSession);
    }
  }
}
