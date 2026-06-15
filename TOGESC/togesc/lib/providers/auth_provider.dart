import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Cliente Supabase cuando el proyecto esta configurado en build.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  return Supabase.instance.client;
});

/// ID del usuario autenticado, o null si no hay sesion.
final currentUserIdProvider = Provider<String?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client?.auth.currentUser?.id;
});

/// Email del usuario autenticado.
final currentUserEmailProvider = Provider<String?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client?.auth.currentUser?.email;
});

/// Cambios de sesion (login, logout, refresh).
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return Stream.value(const AuthState(AuthChangeEvent.initialSession, null));
  }
  return client.auth.onAuthStateChange;
});

final supabaseAvailableProvider = Provider<bool>((ref) {
  return SupabaseConfig.isConfigured;
});
