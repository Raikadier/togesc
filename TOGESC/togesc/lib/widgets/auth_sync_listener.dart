import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/srs_provider.dart';

/// Fusiona progreso local/remoto cuando hay sesion Supabase activa.
class AuthSyncListener extends ConsumerWidget {
  const AuthSyncListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<AuthState>>(authStateChangesProvider, (prev, next) {
      next.whenData((state) {
        if (state.session == null) return;
        if (state.event == AuthChangeEvent.signedIn ||
            state.event == AuthChangeEvent.initialSession) {
          ref.read(progressSyncOnSignInProvider)();
        }
      });
    });
    return child;
  }
}
