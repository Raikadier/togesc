import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:togesc/app/router.dart';
import 'package:togesc/screens/about_screen.dart';
import 'package:togesc/screens/privacy_policy_screen.dart';

void main() {
  Widget buildApp(GoRouter router) {
    return ProviderScope(
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('AboutScreen muestra contenido pedagogico', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.about,
      routes: [
        GoRoute(
          path: AppRoutes.about,
          builder: (_, _) => const AboutScreen(),
        ),
        GoRoute(
          path: AppRoutes.privacy,
          builder: (_, _) => const PrivacyPolicyScreen(),
        ),
      ],
    );

    await tester.pumpWidget(buildApp(router));
    await tester.pumpAndSettle();

    expect(find.text('Acerca de TOGESC'), findsOneWidget);
    expect(find.text('Repeticion espaciada (SRS)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Politica de privacidad'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Politica de privacidad'), findsOneWidget);
  });

  testWidgets('AboutScreen navega a politica de privacidad', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.about,
      routes: [
        GoRoute(
          path: AppRoutes.about,
          builder: (_, _) => const AboutScreen(),
        ),
        GoRoute(
          path: AppRoutes.privacy,
          builder: (_, _) => const PrivacyPolicyScreen(),
        ),
      ],
    );

    await tester.pumpWidget(buildApp(router));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Politica de privacidad'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Politica de privacidad'));
    await tester.pumpAndSettle();

    expect(find.text('Resumen'), findsOneWidget);
    expect(find.textContaining('no recopila datos personales'), findsOneWidget);
  });
}
