import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/app/router.dart';
import 'package:togesc/constants/note_naming.dart';
import 'package:togesc/providers/audio_provider.dart';
import 'package:togesc/screens/onboarding_screen.dart';
import 'package:togesc/services/app_preferences.dart';
import 'package:togesc/services/audio_generator.dart';
import 'package:togesc/services/audio_player_service.dart';
import 'dart:math';

/// El ListView del onboarding tiene un único hijo (una Column), así que todo
/// está construido desde el inicio y `scrollUntilVisible` no desplaza nada:
/// el finder "existe" aunque esté fuera de pantalla. `ensureVisible` sí
/// desplaza hasta el widget antes de tocarlo.
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

final _startButton = find.widgetWithText(FilledButton, 'Entendido, empezar');

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Un tap fuera de pantalla debe fallar, no solo avisar (fue la causa
    // silenciosa de que la preferencia nunca se guardara).
    WidgetController.hitTestWarningShouldBeFatal = true;
  });
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets('muestra las tres secciones pedagogicas', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(
            AudioPlayerService(generator: AudioGenerator(random: Random(42))),
          ),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Bento de tres pilares del rediseño Stitch.
    expect(find.text('Algoritmo SRS'), findsOneWidget);
    expect(find.text('Timbre universal'), findsOneWidget);
    expect(find.text('Neutralidad tonal'), findsOneWidget);

    await tester.ensureVisible(_startButton);
    await tester.pumpAndSettle();
    expect(_startButton, findsOneWidget);
    expect(find.text('Probar sonido'), findsOneWidget);
    expect(find.text('Notación Do/Re/Mi'), findsOneWidget);
  });

  testWidgets('completar onboarding guarda preferencia', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
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
          audioPlayerServiceProvider.overrideWithValue(
            AudioPlayerService(generator: AudioGenerator(random: Random(42))),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, _startButton);

    final prefs = AppPreferences(await SharedPreferences.getInstance());
    expect(prefs.onboardingComplete, isTrue);
    expect(prefs.noteNamingMode, NoteNamingMode.letter);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('completar onboarding con solfeo activado', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
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
          audioPlayerServiceProvider.overrideWithValue(
            AudioPlayerService(generator: AudioGenerator(random: Random(42))),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.byType(Switch));
    await _tapVisible(tester, _startButton);

    final prefs = AppPreferences(await SharedPreferences.getInstance());
    expect(prefs.noteNamingMode, NoteNamingMode.solfege);
    expect(prefs.onboardingComplete, isTrue);
  });
}
