import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:togesc/app/router.dart';
import 'package:togesc/providers/auth_provider.dart';
import 'package:togesc/providers/router_provider.dart';
import 'package:togesc/widgets/auth_sync_listener.dart';

void main() {
  testWidgets(
    'el enlace de nueva contraseña abre Cuenta aunque la app arranque en Home',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final auth = StreamController<AuthState>();
      addTearDown(auth.close);
      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: AppRoutes.account,
            builder: (_, _) => Consumer(
              builder: (_, ref, _) => Scaffold(
                body: Text(
                  ref.watch(passwordRecoveryProvider)
                      ? 'Nueva contraseña'
                      : 'Cuenta',
                ),
              ),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith((ref) => auth.stream),
            goRouterProvider.overrideWithValue(router),
          ],
          child: AuthSyncListener(
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);

      auth.add(const AuthState(AuthChangeEvent.passwordRecovery, null));
      await tester.pumpAndSettle();

      expect(find.text('Nueva contraseña'), findsOneWidget);
    },
  );
}
