import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';

final routerRefreshListenable = ValueNotifier<int>(0);

/// Router con ubicacion inicial segun onboarding (llamar desde main tras leer prefs).
GoRouter buildAppRouter({required bool onboardingComplete}) {
  return createAppRouter(
    refreshListenable: routerRefreshListenable,
    initialLocation:
        onboardingComplete ? AppRoutes.home : AppRoutes.onboarding,
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  ref.onDispose(routerRefreshListenable.dispose);
  return createAppRouter(refreshListenable: routerRefreshListenable);
});

/// Notifica al router que debe reevaluar redirects (p. ej. tras onboarding).
void refreshAppRouter() {
  routerRefreshListenable.value++;
}
