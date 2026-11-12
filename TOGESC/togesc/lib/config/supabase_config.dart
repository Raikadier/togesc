import 'package:flutter/foundation.dart';

/// Credenciales Supabase inyectadas en build (--dart-define).
///
/// [anonKey]: clave anon JWT legacy o publishable (`sb_publishable_...`).
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  /// Vuelta de los enlaces de Auth en Android e iOS (esquema propio del
  /// manifiesto y de `Info.plist`). Debe estar en las Redirect URLs.
  static const mobileAuthRedirect = 'com.raikadier.togesc://login-callback';

  /// Adónde vuelven los enlaces de los emails de Auth. En web, al mismo
  /// origen; fuera de web `Uri.base` es `file:///` y `origin` lanza.
  static String authRedirect({bool isWeb = kIsWeb, Uri? base}) =>
      isWeb ? (base ?? Uri.base).origin : mobileAuthRedirect;
}
