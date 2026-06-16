import 'package:shared_preferences/shared_preferences.dart';

const String syncPendingKey = 'togesc_sync_pending';

/// Marca si hay progreso local pendiente de subir a Supabase.
class SyncPendingStore {
  SyncPendingStore({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<bool> get isPending async {
    final prefs = await _instance;
    return prefs.getBool(syncPendingKey) ?? false;
  }

  Future<void> markPending() async {
    final prefs = await _instance;
    await prefs.setBool(syncPendingKey, true);
  }

  Future<void> clear() async {
    final prefs = await _instance;
    await prefs.remove(syncPendingKey);
  }
}
