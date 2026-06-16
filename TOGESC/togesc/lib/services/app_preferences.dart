import 'package:shared_preferences/shared_preferences.dart';

import '../constants/note_naming.dart';

const String onboardingCompleteKey = 'togesc_onboarding_complete';
const String sessionCountKey = 'togesc_session_count';
const String csatLastSubmittedKey = 'togesc_csat_last_submitted';
const String csatLastDismissedKey = 'togesc_csat_last_dismissed';
const String noteNamingModeKey = 'togesc_note_naming_mode';
const String practiceRemindersEnabledKey = 'togesc_practice_reminders';

/// Preferencias de la aplicacion (onboarding, Fase 6, etc.).
class AppPreferences {
  final SharedPreferences _prefs;

  AppPreferences(this._prefs);

  bool get onboardingComplete =>
      _prefs.getBool(onboardingCompleteKey) ?? false;

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(onboardingCompleteKey, value);
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
