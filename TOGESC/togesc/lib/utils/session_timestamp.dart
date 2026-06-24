/// Comparacion de marcas de sesion ISO (local sin offset vs Postgres +00:00).
abstract final class SessionTimestamp {
  static DateTime? parseUtc(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    final hasOffset =
        iso.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(iso);
    if (!hasOffset) {
      return DateTime.utc(
        dt.year,
        dt.month,
        dt.day,
        dt.hour,
        dt.minute,
        dt.second,
        dt.millisecond,
        dt.microsecond,
      );
    }
    return dt.toUtc();
  }

  static bool match(String? a, String? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a == b) return true;
    final local = parseUtc(a);
    final remote = parseUtc(b);
    if (local == null || remote == null) return false;
    return local.isAtSameMomentAs(remote);
  }

  /// True si [remoteIso] es estrictamente posterior a [localIso].
  static bool isRemoteNewer(String? localIso, String? remoteIso) {
    if (match(localIso, remoteIso)) return false;
    final local = parseUtc(localIso);
    final remote = parseUtc(remoteIso);
    if (remote == null) return false;
    if (local == null) return true;
    return remote.isAfter(local);
  }
}
