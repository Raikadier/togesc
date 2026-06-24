import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/subscription_status.dart';

const String cachedSubscriptionKey = 'togesc_cached_subscription';

/// Ultimo entitlement conocido (offline / error de red).
class CachedSubscriptionStore {
  CachedSubscriptionStore({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<SubscriptionStatus?> load() async {
    final prefs = await _instance;
    final raw = prefs.getString(cachedSubscriptionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return SubscriptionStatus.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(SubscriptionStatus status) async {
    final prefs = await _instance;
    await prefs.setString(cachedSubscriptionKey, jsonEncode(status.toJson()));
  }

  Future<void> clear() async {
    final prefs = await _instance;
    await prefs.remove(cachedSubscriptionKey);
  }
}
