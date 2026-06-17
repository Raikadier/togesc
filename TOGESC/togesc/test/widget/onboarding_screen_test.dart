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
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

    expect(find.text('Repeticion espaciada (SRS)'), findsOneWidget);
    expect(find.text('Variacion de octavas y timbres'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Limpieza tonal'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Limpieza tonal'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Entendido, empezar'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Entendido, empezar'), findsOneWidget);
    expect(find.text('Probar sonido'), findsOneWidget);
    expect(find.text('Notacion Do/Re/Mi'), findsOneWidget);
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

    final button = find.text('Entendido, empezar');
    await tester.scrollUntilVisible(
      button,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(button);
    await tester.pumpAndSettle();

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

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Entendido, empezar'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Entendido, empezar'));
    await tester.pumpAndSettle();

    final prefs = AppPreferences(await SharedPreferences.getInstance());
    expect(prefs.noteNamingMode, NoteNamingMode.solfege);
    expect(prefs.onboardingComplete, isTrue);
  });
}
