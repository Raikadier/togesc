import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/subscription_config.dart';
import '../config/supabase_config.dart';
import '../services/subscription_access.dart';
import 'subscription_provider.dart';

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

/// Si el email del usuario esta verificado.
final emailVerifiedProvider = Provider<bool>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = client?.auth.currentUser;
  if (user == null) return false;
  return user.emailConfirmedAt != null;
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

/// Sync en nube disponible (Supabase + cuenta + Pro si monetizacion activa).
final cloudSyncAvailableProvider = Provider<bool>((ref) {
  if (!SupabaseConfig.isConfigured) return false;
  if (ref.watch(currentUserIdProvider) == null) return false;
  final status = ref.watch(subscriptionStatusProvider);
  return status.when(
    data: SubscriptionAccess.canUseCloudSync,
    loading: () => !SubscriptionConfig.isActive,
    error: (_, _) => false,
  );
});
