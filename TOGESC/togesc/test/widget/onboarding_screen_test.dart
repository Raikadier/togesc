import 'dart:math';
import 'dart:typed_data';

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

/// El AudioPlayerService real no termina en tests: este no suena.
class _SilentAudio extends AudioPlayerService {
  _SilentAudio() : super(generator: AudioGenerator(random: Random(42)));

  int plays = 0;

  @override
  bool get isInitialized => true;

  @override
  void captureUserGesture() {}

  @override
  Future<bool> waitUntilReady() async => true;

  @override
  Future<void> playBuffer(Float64List samples, {int? sampleRate}) async {
    plays++;
  }
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

final _next = find.byKey(const ValueKey('onboarding-next'));

/// Detector de la tecla: el `RenderTransform` del feedback no siempre está en
/// la ruta de hit test (Flutter 3.41 del CI), pero el toque llega al detector.
Finder _key(String note) => find
    .ancestor(
      of: find.byKey(ValueKey('piano-key-$note')),
      matching: find.byType(GestureDetector),
    )
    .first;
final _start = find.widgetWithText(FilledButton, 'Entendido, empezar');

Future<_SilentAudio> _pump(
  WidgetTester tester, {
  Size? size,
  bool settle = true,
}) async {
  await tester.binding.setSurfaceSize(size ?? const Size(800, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final audio = _SilentAudio();
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
      overrides: [audioPlayerServiceProvider.overrideWithValue(audio)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return audio;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Un tap fuera de pantalla debe fallar, no solo avisar.
    WidgetController.hitTestWarningShouldBeFatal = true;
  });
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets('4 pasos con indicador «Paso N de 4»', (tester) async {
    await _pump(tester);

    expect(find.bySemanticsLabel('Paso 1 de 4'), findsOneWidget);
    expect(find.text('Entrenador de oído absoluto'), findsOneWidget);
    expect(find.text('SRS · variación · limpieza tonal'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-back')), findsNothing);

    await _tapVisible(tester, _next);
    expect(find.bySemanticsLabel('Paso 2 de 4'), findsOneWidget);
    expect(find.text('Cómo funciona'), findsOneWidget);
    expect(find.text('Algoritmo SRS'), findsOneWidget);
    expect(find.text('Timbre universal'), findsOneWidget);
    expect(find.text('Neutralidad tonal'), findsOneWidget);

    await _tapVisible(tester, find.byKey(const ValueKey('onboarding-back')));
    expect(find.bySemanticsLabel('Paso 1 de 4'), findsOneWidget);
  });

  testWidgets('paso 3: «Seguir sin probar» hasta responder; acierto con '
      'feedback y estado anunciado', (tester) async {
    final audio = await _pump(tester);
    await _tapVisible(tester, _next);
    await _tapVisible(tester, _next);

    expect(find.text('Una ronda de prueba'), findsOneWidget);
    expect(find.text('Seguir sin probar'), findsOneWidget);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('onboarding-try-play')),
    );
    expect(audio.plays, 1);

    await _tapVisible(tester, _key('A'));
    final status = find.byKey(const ValueKey('onboarding-try-status'));
    expect(
      find.descendant(of: status, matching: find.text('Correcto')),
      findsOneWidget,
    );
    expect(tester.getSemantics(status), isSemantics(isLiveRegion: true));
    expect(find.text('Siguiente'), findsOneWidget);
    expect(find.text('Seguir sin probar'), findsNothing);
  });

  testWidgets('paso 3: un fallo dice la nota correcta', (tester) async {
    await _pump(tester);
    await _tapVisible(tester, _next);
    await _tapVisible(tester, _next);

    await _tapVisible(tester, _key('C'));
    expect(find.text('Era La'), findsNothing);
    expect(find.text('Era A'), findsOneWidget);
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('onboarding-try-again')),
    );
    expect(find.text('Seguir sin probar'), findsOneWidget);
  });

  testWidgets('completar onboarding guarda preferencia y resetea el paso', (
    tester,
  ) async {
    await _pump(tester);
    for (var i = 0; i < 3; i++) {
      await _tapVisible(tester, _next);
    }
    expect(find.bySemanticsLabel('Paso 4 de 4'), findsOneWidget);
    await _tapVisible(tester, _start);

    final prefs = AppPreferences(await SharedPreferences.getInstance());
    expect(prefs.onboardingComplete, isTrue);
    expect(prefs.onboardingStep, 0);
    expect(prefs.noteNamingMode, NoteNamingMode.letter);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('paso 4: solfeo, texto más grande y reducir animaciones', (
    tester,
  ) async {
    await _pump(tester);
    for (var i = 0; i < 3; i++) {
      await _tapVisible(tester, _next);
    }

    expect(find.text('C'), findsOneWidget);
    await _tapVisible(tester, find.text('Do · Re · Mi'));
    expect(find.text('Sol'), findsOneWidget);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('onboarding-large-text')),
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('onboarding-reduce-motion')),
    );
    await _tapVisible(tester, _start);

    final raw = await SharedPreferences.getInstance();
    final prefs = AppPreferences(raw);
    expect(prefs.noteNamingMode, NoteNamingMode.solfege);
    expect(prefs.onboardingComplete, isTrue);
    expect(prefs.uiPreferences.largeText, isTrue);
    expect(prefs.uiPreferences.reduceAnimations, isTrue);
  });

  testWidgets('«Saltar» completa el onboarding desde cualquier paso', (
    tester,
  ) async {
    await _pump(tester);
    await _tapVisible(tester, _next);
    await _tapVisible(tester, find.byKey(const ValueKey('onboarding-skip')));

    final prefs = AppPreferences(await SharedPreferences.getInstance());
    expect(prefs.onboardingComplete, isTrue);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('retoma el paso guardado', (tester) async {
    SharedPreferences.setMockInitialValues({onboardingStepKey: 2});
    await _pump(tester);
    expect(find.bySemanticsLabel('Paso 3 de 4'), findsOneWidget);
    expect(find.text('Una ronda de prueba'), findsOneWidget);
  });

  testWidgets('el ecualizador anima un número limitado de ciclos', (
    tester,
  ) async {
    await _pump(tester, settle: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);
    // 3 ciclos de 1,2 s: quieto antes de 5 s (WCAG 2.2.2).
    await tester.pump(const Duration(seconds: 4));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('con movimiento reducido el ecualizador no anima', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _pump(tester, settle: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isFalse);
  });
}
