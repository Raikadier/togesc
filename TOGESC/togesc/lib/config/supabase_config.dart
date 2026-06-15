/// Credenciales Supabase inyectadas en build (--dart-define).
///
/// [anonKey]: clave anon JWT legacy o publishable (`sb_publishable_...`).
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
