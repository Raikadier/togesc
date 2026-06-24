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

/// Cambios de sesion (login, logout, refresh). Los providers de usuario
/// escuchan este stream para refrescar la UI sin recargar la pagina.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return Stream.value(const AuthState(AuthChangeEvent.initialSession, null));
  }
  return client.auth.onAuthStateChange;
});

User? _sessionUser(Ref ref) {
  final authAsync = ref.watch(authStateChangesProvider);
  return authAsync.when(
    data: (state) => state.session?.user,
    loading: () => ref.watch(supabaseClientProvider)?.auth.currentUser,
    error: (e, _) => ref.watch(supabaseClientProvider)?.auth.currentUser,
  );
}

/// ID del usuario autenticado, o null si no hay sesion.
final currentUserIdProvider = Provider<String?>((ref) {
  return _sessionUser(ref)?.id;
});

/// Email del usuario autenticado.
final currentUserEmailProvider = Provider<String?>((ref) {
  return _sessionUser(ref)?.email;
});

/// Si el email del usuario esta verificado.
final emailVerifiedProvider = Provider<bool>((ref) {
  final user = _sessionUser(ref);
  if (user == null) return false;
  return user.emailConfirmedAt != null;
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
