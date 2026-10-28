import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/note_naming.dart';
import '../models/audio_preferences.dart';
import '../models/last_practice_session.dart';
import '../models/practice_session_log.dart';
import '../models/practice_session_preferences.dart';
import '../models/srs_intensity_profile.dart';
import '../models/ui_preferences.dart';

const String onboardingCompleteKey = 'togesc_onboarding_complete';

/// Paso actual del onboarding v2.1 (0–3), para retomarlo al volver.
const String onboardingStepKey = 'togesc_onboarding_step';
const String sessionCountKey = 'togesc_session_count';
const String csatLastSubmittedKey = 'togesc_csat_last_submitted';
const String csatLastDismissedKey = 'togesc_csat_last_dismissed';
const String noteNamingModeKey = 'togesc_note_naming_mode';
const String practiceRemindersEnabledKey = 'togesc_practice_reminders';
const String instrumentModeKey = 'togesc_instrument_mode';
const String fixedInstrumentIdKey = 'togesc_fixed_instrument_id';
const String masterVolumeKey = 'togesc_master_volume';
const String clusterEnabledKey = 'togesc_cluster_enabled';
const String clusterDurationKey = 'togesc_cluster_duration_sec';
const String lastPracticeModeIdKey = 'togesc_last_practice_mode_id';
const String lastPracticeKindKey = 'togesc_last_practice_kind';
const String lastPracticeAtKey = 'togesc_last_practice_at';
const String sessionRoundGoalKey = 'togesc_session_round_goal';
const String autoAdvanceAfterResultKey = 'togesc_auto_advance_after_result';
const String gameInputModeKey = 'togesc_game_input_mode';
const String confirmBeforeSubmitKey = 'togesc_confirm_before_submit';

// Claves v2 (rediseño v2, D1/D2/D3/D6). Las claves legacy de arriba se leen
// solo como respaldo de migración; las escrituras van a las claves v2.
// Motivo: `setUiPreferences` y `setPracticeSessionPreferences` escriben TODOS
// los campos a la vez, así que un valor legacy igual al default antiguo no
// distingue «nunca lo tocó» de «lo eligió». Regla de migración
// ([migrateLegacyPreference]): un valor legacy distinto del default antiguo
// es una elección explícita y se conserva; uno igual al default antiguo (o
// ausente) recibe el default nuevo.
const String sessionRoundGoalV2Key = 'togesc_session_round_goal_v2';
const String autoAdvanceAfterResultV2Key =
    'togesc_auto_advance_after_result_v2';
const String gameInputModeV2Key = 'togesc_game_input_mode_v2';
const String confirmBeforeSubmitV2Key = 'togesc_confirm_before_submit_v2';

/// Defaults anteriores al rediseño v2 (solo para migrar valores legacy).
const bool legacyDefaultConfirmBeforeSubmit = true;
const bool legacyDefaultAutoAdvanceAfterResult = false;
const String legacyDefaultGameInputModeId = 'both';
const int legacyDefaultSessionRoundGoalRounds = 0;

/// Resuelve una preferencia migrada a v2.
///
/// - Si existe valor v2 ([v2Value]), manda siempre.
/// - Si no, un valor legacy distinto de [legacyDefault] es una elección
///   explícita del usuario y se conserva.
/// - En otro caso (sin valor o igual al default antiguo) se usa [newDefault].
T migrateLegacyPreference<T>({
  required T? v2Value,
  required T? legacyValue,
  required T legacyDefault,
  required T newDefault,
}) {
  if (v2Value != null) return v2Value;
  if (legacyValue != null && legacyValue != legacyDefault) return legacyValue;
  return newDefault;
}
const String hidePianoLabelsKey = 'togesc_hide_piano_labels';
const String largePianoKey = 'togesc_large_piano';
const String reduceAnimationsKey = 'togesc_reduce_animations';
const String largeTextKey = 'togesc_large_text';
const String themePreferenceKey = 'togesc_theme_preference';
const String octaveVariationKey = 'togesc_octave_variation';
const String toneDurationKey = 'togesc_tone_duration_sec';
const String practiceNotePoolKey = 'togesc_practice_note_pool';
const String sessionHistoryKey = 'togesc_session_history';
const String srsIntensityProfileKey = 'togesc_srs_intensity_profile';
const String totalXpKey = 'togesc_total_xp';

/// Preferencias de la aplicacion (onboarding, Fase 6, etc.).
class AppPreferences {
  final SharedPreferences _prefs;

  AppPreferences(this._prefs);

  bool get onboardingComplete =>
      _prefs.getBool(onboardingCompleteKey) ?? false;

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(onboardingCompleteKey, value);
  }

  int get onboardingStep => _prefs.getInt(onboardingStepKey) ?? 0;

  Future<void> setOnboardingStep(int step) async {
    await _prefs.setInt(onboardingStepKey, step);
  }

  int get sessionCount => _prefs.getInt(sessionCountKey) ?? 0;

  Future<int> incrementSessionCount() async {
    final next = sessionCount + 1;
    await _prefs.setInt(sessionCountKey, next);
    return next;
  }

  DateTime? get csatLastSubmitted {
    final raw = _prefs.getString(csatLastSubmittedKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setCsatLastSubmitted(DateTime value) async {
    await _prefs.setString(csatLastSubmittedKey, value.toIso8601String());
  }

  DateTime? get csatLastDismissed {
    final raw = _prefs.getString(csatLastDismissedKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setCsatLastDismissed(DateTime value) async {
    await _prefs.setString(csatLastDismissedKey, value.toIso8601String());
  }

  NoteNamingMode get noteNamingMode {
    final raw = _prefs.getString(noteNamingModeKey);
    if (raw == NoteNamingMode.solfege.name) {
      return NoteNamingMode.solfege;
    }
    return NoteNamingMode.letter;
  }

  Future<void> setNoteNamingMode(NoteNamingMode mode) async {
    await _prefs.setString(noteNamingModeKey, mode.name);
  }

  bool get practiceRemindersEnabled =>
      _prefs.getBool(practiceRemindersEnabledKey) ?? false;

  Future<void> setPracticeRemindersEnabled(bool value) async {
    await _prefs.setBool(practiceRemindersEnabledKey, value);
  }

  AudioPreferences get audioPreferences {
    final modeRaw = _prefs.getString(instrumentModeKey);
    final mode = modeRaw == InstrumentMode.fixed.name
        ? InstrumentMode.fixed
        : InstrumentMode.random;

    final fixedId = _prefs.getString(fixedInstrumentIdKey) ?? 'sine';
    final volume = _prefs.getDouble(masterVolumeKey) ?? 1.0;
    final clusterOn = _prefs.getBool(clusterEnabledKey) ?? true;
    final clusterDur = _prefs.getDouble(clusterDurationKey) ?? 3.0;

    return AudioPreferences(
      instrumentMode: mode,
      fixedInstrumentId: fixedId,
      masterVolume: volume.clamp(0.0, 1.0),
      clusterEnabled: clusterOn,
      clusterDurationSec: _normalizeClusterDuration(clusterDur),
      octaveVariationEnabled: _prefs.getBool(octaveVariationKey) ?? true,
      toneDurationSec: _normalizeToneDuration(
        _prefs.getDouble(toneDurationKey) ?? 1.0,
      ),
    );
  }

  Future<void> setAudioPreferences(AudioPreferences value) async {
    await _prefs.setString(instrumentModeKey, value.instrumentMode.name);
    await _prefs.setString(fixedInstrumentIdKey, value.fixedInstrumentId);
    await _prefs.setDouble(masterVolumeKey, value.masterVolume.clamp(0.0, 1.0));
    await _prefs.setBool(clusterEnabledKey, value.clusterEnabled);
    await _prefs.setDouble(
      clusterDurationKey,
      _normalizeClusterDuration(value.clusterDurationSec),
    );
    await _prefs.setBool(octaveVariationKey, value.octaveVariationEnabled);
    await _prefs.setDouble(
      toneDurationKey,
      _normalizeToneDuration(value.toneDurationSec),
    );
  }

  static double _normalizeToneDuration(double seconds) {
    if (seconds <= 0.75) return 0.5;
    if (seconds <= 1.25) return 1.0;
    return 1.5;
  }

  static double _normalizeClusterDuration(double seconds) {
    if (seconds <= 2.5) return 2.0;
    if (seconds <= 4.0) return 3.0;
    return 5.0;
  }

  LastPracticeSession? get lastPracticeSession {
    final modeId = _prefs.getInt(lastPracticeModeIdKey);
    final atRaw = _prefs.getString(lastPracticeAtKey);
    if (modeId == null || atRaw == null) return null;

    final kindRaw = _prefs.getString(lastPracticeKindKey) ?? PracticeKind.game.name;
    final kind = kindRaw == PracticeKind.speed.name
        ? PracticeKind.speed
        : PracticeKind.game;
    final at = DateTime.tryParse(atRaw);
    if (at == null) return null;

    return LastPracticeSession(modeId: modeId, kind: kind, practicedAt: at);
  }

  Future<void> setLastPracticeSession(LastPracticeSession session) async {
    await _prefs.setInt(lastPracticeModeIdKey, session.modeId);
    await _prefs.setString(lastPracticeKindKey, session.kind.name);
    await _prefs.setString(
      lastPracticeAtKey,
      session.practicedAt.toIso8601String(),
    );
  }

  PracticeSessionPreferences get practiceSessionPreferences {
    final goalRounds = migrateLegacyPreference<int>(
      v2Value: _prefs.getInt(sessionRoundGoalV2Key),
      legacyValue: _prefs.getInt(sessionRoundGoalKey),
      legacyDefault: legacyDefaultSessionRoundGoalRounds,
      newDefault: defaultSessionRoundGoal.rounds,
    );
    return PracticeSessionPreferences(
      roundGoal: SessionRoundGoal.fromRounds(goalRounds),
      autoAdvanceAfterResult: migrateLegacyPreference<bool>(
        v2Value: _prefs.getBool(autoAdvanceAfterResultV2Key),
        legacyValue: _prefs.getBool(autoAdvanceAfterResultKey),
        legacyDefault: legacyDefaultAutoAdvanceAfterResult,
        newDefault: defaultAutoAdvanceAfterResult,
      ),
    );
  }

  Future<void> setPracticeSessionPreferences(
    PracticeSessionPreferences value,
  ) async {
    await _prefs.setInt(sessionRoundGoalV2Key, value.roundGoal.rounds);
    await _prefs.setBool(
      autoAdvanceAfterResultV2Key,
      value.autoAdvanceAfterResult,
    );
  }

  UiPreferences get uiPreferences {
    final inputModeId = migrateLegacyPreference<String>(
      v2Value: _prefs.getString(gameInputModeV2Key),
      legacyValue: _prefs.getString(gameInputModeKey),
      legacyDefault: legacyDefaultGameInputModeId,
      newDefault: defaultGameInputMode.name,
    );
    return UiPreferences(
      inputMode: GameInputMode.fromId(inputModeId),
      confirmBeforeSubmit: migrateLegacyPreference<bool>(
        v2Value: _prefs.getBool(confirmBeforeSubmitV2Key),
        legacyValue: _prefs.getBool(confirmBeforeSubmitKey),
        legacyDefault: legacyDefaultConfirmBeforeSubmit,
        newDefault: defaultConfirmBeforeSubmit,
      ),
      hidePianoLabels: _prefs.getBool(hidePianoLabelsKey) ?? false,
      largePiano: _prefs.getBool(largePianoKey) ?? false,
      reduceAnimations: _prefs.getBool(reduceAnimationsKey) ?? false,
      largeText: _prefs.getBool(largeTextKey) ?? false,
      themePreference:
          AppThemePreference.fromId(_prefs.getString(themePreferenceKey)),
    );
  }

  Future<void> setUiPreferences(UiPreferences value) async {
    await _prefs.setString(gameInputModeV2Key, value.inputMode.name);
    await _prefs.setBool(confirmBeforeSubmitV2Key, value.confirmBeforeSubmit);
    await _prefs.setBool(hidePianoLabelsKey, value.hidePianoLabels);
    await _prefs.setBool(largePianoKey, value.largePiano);
    await _prefs.setBool(reduceAnimationsKey, value.reduceAnimations);
    await _prefs.setBool(largeTextKey, value.largeText);
    await _prefs.setString(themePreferenceKey, value.themePreference.name);
  }

  List<String> get practiceNotePool {
    final raw = _prefs.getStringList(practiceNotePoolKey);
    if (raw == null || raw.isEmpty) return List.from(chromaticNotes);
    final valid = raw.where(chromaticNotes.contains).toList();
    return valid.isEmpty ? List.from(chromaticNotes) : valid;
  }

  Future<void> setPracticeNotePool(List<String> notes) async {
    final valid = notes.where(chromaticNotes.contains).toList();
    if (valid.isEmpty) return;
    await _prefs.setStringList(practiceNotePoolKey, valid);
  }

  List<PracticeSessionLog> get sessionHistory {
    final raw = _prefs.getString(sessionHistoryKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = (jsonDecode(raw) as List<dynamic>)
          .map((e) => PracticeSessionLog.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
      return decoded;
    } catch (_) {
      return [];
    }
  }

  Future<List<PracticeSessionLog>> appendSessionLog(
    PracticeSessionLog entry,
  ) async {
    final current = List<PracticeSessionLog>.from(sessionHistory);
    current.insert(0, entry);
    if (current.length > maxSessionHistoryEntries) {
      current.removeRange(maxSessionHistoryEntries, current.length);
    }
    await _prefs.setString(
      sessionHistoryKey,
      jsonEncode(current.map((e) => e.toJson()).toList()),
    );
    return current;
  }

  Future<void> clearSessionHistory() async {
    await _prefs.remove(sessionHistoryKey);
  }

  SrsIntensityProfile get srsIntensityProfile {
    return SrsIntensityProfile.fromId(_prefs.getString(srsIntensityProfileKey));
  }

  Future<void> setSrsIntensityProfile(SrsIntensityProfile profile) async {
    await _prefs.setString(srsIntensityProfileKey, profile.name);
  }

  int get totalXp => _prefs.getInt(totalXpKey) ?? 0;

  Future<int> addXp(int amount) async {
    if (amount <= 0) return totalXp;
    final next = totalXp + amount;
    await _prefs.setInt(totalXpKey, next);
    return next;
  }

  Future<void> clearEngagementXp() async {
    await _prefs.remove(totalXpKey);
  }

  /// Encuesta CSAT ocasional: tras 10 sesiones y cada 30 dias.
  bool shouldShowCsatSurvey({DateTime? now}) {
    final clock = now ?? DateTime.now();
    if (sessionCount < 10) return false;

    final dismissed = csatLastDismissed;
    if (dismissed != null && clock.difference(dismissed).inDays < 7) {
      return false;
    }

    final submitted = csatLastSubmitted;
    if (submitted == null) return true;
    return clock.difference(submitted).inDays >= 30;
  }
}
