import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';

final _routerRefresh = ValueNotifier<int>(0);

final goRouterProvider = Provider<GoRouter>((ref) {
  ref.onDispose(_routerRefresh.dispose);
  return createAppRouter(refreshListenable: _routerRefresh);
});

/// Notifica al router que debe reevaluar redirects (p. ej. tras onboarding).
void refreshAppRouter() {
  _routerRefresh.value++;
}
