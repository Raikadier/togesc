import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:togesc/app/router.dart';
import 'package:togesc/widgets/togesc_ui.dart';

void main() {
  testWidgets('un estado vacío lleva a practicar (lote F, punto 6)', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/vacio',
      routes: [
        GoRoute(
          path: '/vacio',
          builder: (_, _) => const Scaffold(
            body: TogescEmptyState(message: 'Aún no hay sesiones.'),
          ),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.text('Aún no hay sesiones.'), findsOneWidget);
    await tester.tap(find.text('Empezar a practicar'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('un error de carga se anuncia y deja reintentar', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TogescLoadError(
            message: 'No se pudo cargar el historial.',
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    final live = tester.getSemantics(
      find.ancestor(
        of: find.text('No se pudo cargar el historial.'),
        matching: find.byType(Semantics),
      ).first,
    );
    expect(live.flagsCollection.isLiveRegion, isTrue);

    await tester.tap(find.text('Reintentar'));
    expect(retries, 1);
  });
}
