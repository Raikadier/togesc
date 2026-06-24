import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/subscription_config.dart';
import '../providers/auth_provider.dart';
import '../providers/srs_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/sync_provider.dart';

/// Fusiona progreso, sube pendientes y refresca suscripcion al reconectar.
class AuthSyncListener extends ConsumerStatefulWidget {
  const AuthSyncListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AuthSyncListener> createState() => _AuthSyncListenerState();
}

class _AuthSyncListenerState extends ConsumerState<AuthSyncListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refreshCloudState() async {
    await ref.read(syncNowProvider)();
    ref.invalidate(syncDiagnosticsProvider);
    ref.invalidate(syncPendingProvider);
    ref.invalidate(srsSystemProvider);
    if (SubscriptionConfig.isActive) {
      await ref.read(subscriptionStatusProvider.notifier).refresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshCloudState();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(authStateChangesProvider, (prev, next) {
      next.whenData((state) {
        if (state.event == AuthChangeEvent.signedOut) {
          ref.invalidate(progressRepositoryProvider);
          ref.invalidate(syncDiagnosticsProvider);
          ref.invalidate(syncPendingProvider);
          return;
        }
        if (state.session == null) return;
        if (state.event == AuthChangeEvent.signedIn ||
            state.event == AuthChangeEvent.initialSession ||
            state.event == AuthChangeEvent.tokenRefreshed) {
          _refreshCloudState();
        }
      });
    });

    ref.listen<bool>(hasProAccessProvider, (prev, next) {
      if (prev == false && next == true) {
        _refreshCloudState();
      }
    });

    return widget.child;
  }
}
