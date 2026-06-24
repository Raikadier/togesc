import '../models/note_data.dart';
import 'session_timestamp.dart';

/// Fusiona progreso SRS por nota (no last-write-wins global).
abstract final class ProgressMerge {
  static Map<String, NoteData> mergeMaps(
    Map<String, NoteData> local,
    Map<String, NoteData> remote,
  ) {
    final keys = {...local.keys, ...remote.keys};
    return {
      for (final k in keys)
        k: pickNewer(local[k], remote[k]),
    };
  }

  /// Gana la nota con [lastSeen] mas reciente; empate por [timesSeen].
  static NoteData pickNewer(NoteData? local, NoteData? remote) {
    if (local == null) return remote ?? NoteData();
    if (remote == null) return local;

    final localSeen = SessionTimestamp.parseUtc(local.lastSeen);
    final remoteSeen = SessionTimestamp.parseUtc(remote.lastSeen);

    if (localSeen != null && remoteSeen != null) {
      if (remoteSeen.isAfter(localSeen)) return remote;
      if (localSeen.isAfter(remoteSeen)) return local;
    } else if (remoteSeen != null) {
      return remote;
    } else if (localSeen != null) {
      return local;
    }

    if (remote.timesSeen > local.timesSeen) return remote;
    if (local.timesSeen > remote.timesSeen) return local;
    if (remote.timesCorrect > local.timesCorrect) return remote;
    if (local.timesCorrect > remote.timesCorrect) return local;

    return local;
  }

  static String? pickNewerSession(String? localIso, String? remoteIso) {
    if (SessionTimestamp.isRemoteNewer(localIso, remoteIso)) return remoteIso;
    if (SessionTimestamp.isRemoteNewer(remoteIso, localIso)) return localIso;
    return localIso ?? remoteIso;
  }
}
