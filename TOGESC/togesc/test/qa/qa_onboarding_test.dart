import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/app/router.dart';
import 'package:togesc/providers/audio_provider.dart';
import 'package:togesc/screens/onboarding_screen.dart';
import 'package:togesc/services/app_preferences.dart';
import 'package:togesc/widgets/togesc_ui.dart';

import 'qa_support.dart';

/// Escenario real: un usuario que ya usa solfeo pulsa «Revisar onboarding»
/// (Acerca de) y vuelve a ver el onboarding con su notación guardada.
Future<void> _pumpOnboarding(
  WidgetTester tester, {
  required Map<String, Object> prefs,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  await tester.binding.setSurfaceSize(const Size(800, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: AppRoutes.onboarding,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const Scaffold(body: Text('Home')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(QaSilentAudio()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<String?> _savedNaming() async =>
    (await SharedPreferences.getInstance()).getString(noteNamingModeKey);

void main() {
  testWidgets('con letras guardadas, «Saltar» conserva letras (control)', (
    tester,
  ) async {
    await _pumpOnboarding(tester, prefs: {noteNamingModeKey: 'letter'});
    await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(await _savedNaming(), 'letter');
  });

  testWidgets('con solfeo guardado, «Saltar» no lo cambia a C/D/E '
      '[BUG: onboarding_screen.dart:39 inicia _useSolfege en false sin leer '
      'la preferencia y _complete (l.399) la sobrescribe]', (tester) async {
    await _pumpOnboarding(tester, prefs: {noteNamingModeKey: 'solfege'});
    await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(await _savedNaming(), 'solfege');
  }, skip: qaSkipBug);

  testWidgets('con solfeo guardado, el paso 4 abre con «Do · Re · Mi» '
      'seleccionado [BUG: onboarding_screen.dart:39, mismo origen]', (
    tester,
  ) async {
    await _pumpOnboarding(
      tester,
      prefs: {noteNamingModeKey: 'solfege', onboardingStepKey: 3},
    );
    final selector = tester.widget<TogescSegmented<bool>>(
      find.byKey(const ValueKey('onboarding-notation')),
    );
    expect(selector.selected, isTrue);
  }, skip: qaSkipBug);
}
