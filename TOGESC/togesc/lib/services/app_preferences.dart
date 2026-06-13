import 'package:shared_preferences/shared_preferences.dart';

const String onboardingCompleteKey = 'togesc_onboarding_complete';

/// Preferencias de la aplicacion (onboarding, etc.).
class AppPreferences {
  final SharedPreferences _prefs;

  AppPreferences(this._prefs);

  bool get onboardingComplete =>
      _prefs.getBool(onboardingCompleteKey) ?? false;

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(onboardingCompleteKey, value);
  }
}
