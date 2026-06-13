import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note_data.dart';

abstract class ProgressRepository {
  Future<Map<String, NoteData>?> load();
  Future<void> save(Map<String, NoteData> noteData, {String? lastSession});
}

const String progressStorageKey = 'togesc_progress_json';

/// Parsea JSON de progreso (formato nuevo o legacy).
Map<String, NoteData>? parseProgressPayload(Map<String, dynamic> data) {
  if (data.containsKey('note_data')) {
    final noteDataMap = data['note_data'] as Map<String, dynamic>;
    return noteDataMap.map(
      (k, v) => MapEntry(k, NoteData.fromJson(v as Map<String, dynamic>)),
    );
  }

  if (data.containsKey('weights')) {
    final weights = data['weights'] as Map<String, dynamic>;
    return weights.map(
      (k, v) => MapEntry(k, NoteData(weight: (v as num).toDouble())),
    );
  }

  return null;
}

Map<String, dynamic> encodeProgressPayload(
  Map<String, NoteData> noteData, {
  String? lastSession,
}) {
  return {
    'note_data': noteData.map((k, v) => MapEntry(k, v.toJson())),
    'version': '3.0.0',
    'last_session': lastSession ?? DateTime.now().toIso8601String(),
  };
}

/// Persistencia en SharedPreferences (web, movil y escritorio).
class SharedPreferencesProgressRepository implements ProgressRepository {
  final SharedPreferences? _prefs;
  final Future<SharedPreferences> Function()? _prefsFactory;

  SharedPreferencesProgressRepository({
    SharedPreferences? prefs,
    Future<SharedPreferences> Function()? prefsFactory,
  })  : _prefs = prefs,
        _prefsFactory = prefsFactory;

  Future<SharedPreferences> get _instance async {
    if (_prefs != null) return _prefs;
    final factory = _prefsFactory ?? SharedPreferences.getInstance;
    return factory();
  }

  @override
  Future<Map<String, NoteData>?> load() async {
    try {
      final prefs = await _instance;
      final raw = prefs.getString(progressStorageKey);
      if (raw == null || raw.isEmpty) return null;

      final data = json.decode(raw) as Map<String, dynamic>;
      return parseProgressPayload(data);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(Map<String, NoteData> noteData, {String? lastSession}) async {
    try {
      final prefs = await _instance;
      final payload = encodeProgressPayload(noteData, lastSession: lastSession);
      await prefs.setString(progressStorageKey, json.encode(payload));
    } catch (_) {
      // Silencioso, igual que la version CLI original
    }
  }
}

/// Implementacion en memoria para testing.
class InMemoryProgressRepository implements ProgressRepository {
  Map<String, dynamic>? _stored;

  @override
  Future<Map<String, NoteData>?> load() async {
    if (_stored == null) return null;
    return parseProgressPayload(_stored!);
  }

  @override
  Future<void> save(Map<String, NoteData> noteData, {String? lastSession}) async {
    _stored = encodeProgressPayload(noteData, lastSession: lastSession);
  }

  /// Acceso directo al raw data para testing.
  Map<String, dynamic>? get rawData => _stored;

  /// Carga datos legacy (formato antiguo solo con weights).
  void loadLegacyFormat(Map<String, double> weights) {
    _stored = {'weights': weights};
  }
}

/// Alias historico: persistencia local por archivo JSON en disco.
/// Preferir [SharedPreferencesProgressRepository] en produccion.
typedef JsonFileProgressRepository = SharedPreferencesProgressRepository;
