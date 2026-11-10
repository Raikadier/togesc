import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/screens/account_screen.dart';

/// Perfil v2.1 (SPEC §2.5) sin cuenta: en tests no hay Supabase.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AccountScreen())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('cabecera sin cuenta: el progreso vive en el dispositivo', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Entrenando sin cuenta'), findsOneWidget);
    expect(find.text('Tu progreso vive en este dispositivo'), findsOneWidget);
    // Sin backend de cuentas no se ofrece entrar.
    expect(find.byKey(const ValueKey('profile-sign-in')), findsNothing);
  });

  testWidgets('«Tu oído en cifras» con datos reales (0 sin historial)', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Tu oído en cifras'), findsOneWidget);
    expect(find.bySemanticsLabel('Días de racha: 0'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Notas consolidadas: 0 de 12'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Sesiones: 0'), findsOneWidget);
  });

  testWidgets('card del plan con 3 beneficios y la entrada a Pro', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('PLAN ACTUAL'), findsOneWidget);
    final entry = find.byKey(const ValueKey('account-pro-entry'));
    expect(entry, findsOneWidget);
    expect(tester.getSize(entry).height, greaterThanOrEqualTo(48));
  });

  testWidgets('estado de sincronización con icono y texto', (tester) async {
    await pump(tester);
    final status = find.byKey(const ValueKey('profile-sync-status'));
    expect(
      find.descendant(
        of: status,
        matching: find.text('Solo en este dispositivo'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: status, matching: find.byType(Icon)),
      findsOneWidget,
    );
  });

  testWidgets('preferencias en línea y exportar mi progreso', (tester) async {
    await pump(tester);
    expect(find.text('Notación Do/Re/Mi'), findsOneWidget);
    expect(find.text('Recordatorios diarios'), findsOneWidget);
    expect(find.text('Exportar mi progreso (JSON)'), findsOneWidget);
  });
}
