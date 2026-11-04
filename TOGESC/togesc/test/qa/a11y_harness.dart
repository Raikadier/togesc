// Arnés compartido de las pruebas de accesibilidad (`test/qa/a11y_*`).
//
// Monta la app real (`TogescApp`, con su `builder` que vuelca
// `reduceAnimations` y `largeText` en `MediaQuery`) sobre el router real
// (`createAppRouter`) y con los mismos dobles que los widget tests
// existentes: SRS en memoria y audio sin hardware.
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:togesc/app/router.dart';
import 'package:togesc/main.dart';
import 'package:togesc/models/subscription_status.dart';
import 'package:togesc/providers/audio_provider.dart';
import 'package:togesc/providers/clock_provider.dart';
import 'package:togesc/providers/router_provider.dart';
import 'package:togesc/providers/srs_provider.dart';
import 'package:togesc/providers/subscription_provider.dart';
import 'package:togesc/providers/ui_preferences_provider.dart';
import 'package:togesc/services/app_preferences.dart';
import 'package:togesc/services/audio_generator.dart';
import 'package:togesc/services/audio_player_service.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/services/srs_system.dart';

/// Pantalla auditada: ruta real, nombre para el informe y si va siempre
/// con el tema de sesión oscuro forzado (`AppTheme.session`).
class A11yScreen {
  const A11yScreen(
    this.name,
    this.route, {
    this.sessionTheme = false,
    this.onboarding = false,
  });

  final String name;
  final String route;
  final bool sessionTheme;
  final bool onboarding;
}

/// Las 9 pantallas principales del encargo (+ Velocidad en sesión).
const a11yScreens = [
  A11yScreen('Home', AppRoutes.home),
  A11yScreen('Juego', '${AppRoutes.game}/1', sessionTheme: true),
  A11yScreen('Velocidad (selector)', AppRoutes.speedSelect),
  A11yScreen(
    'Velocidad (sesión)',
    '${AppRoutes.speedGame}/1',
    sessionTheme: true,
  ),
  A11yScreen('Estadísticas', AppRoutes.statistics),
  A11yScreen('Progreso por nota', AppRoutes.statisticsNotes),
  A11yScreen('Perfil/Cuenta', AppRoutes.account),
  A11yScreen('Ajustes', AppRoutes.settings),
  A11yScreen('Paywall', AppRoutes.paywall),
  A11yScreen('Onboarding', AppRoutes.onboarding, onboarding: true),
];

class _FakeSRSNotifier extends AsyncNotifier<SRSSystem> implements SRSNotifier {
  _FakeSRSNotifier(this._srs);
  final SRSSystem _srs;

  @override
  Future<SRSSystem> build() async => _srs;

  @override
  Future<void> saveProgress() async => _srs.saveProgress();

  @override
  Future<void> resetProgress() async {
    await _srs.resetProgress();
    ref.invalidateSelf();
  }
}

class _ProSubscriptionNotifier extends SubscriptionNotifier {
  @override
  Future<SubscriptionStatus> build() async {
    lastKnown = const SubscriptionStatus(plan: 'pro', status: 'active');
    return lastKnown!;
  }
}

/// Audio sin hardware: mismo contrato que [AudioPlayerService].
class _SilentAudio extends AudioPlayerService {
  _SilentAudio() : super(generator: AudioGenerator(random: Random(7)));

  @override
  bool get isInitialized => true;

  @override
  void captureUserGesture() {}

  @override
  Future<bool> waitUntilReady() async => true;

  @override
  Future<void> playBuffer(Float64List samples, {int? sampleRate}) async {}
}

/// `google_fonts` intenta descargar Hanken Grotesk. El cliente HTTP falso
/// de `flutter_test` responde 400 y, cuando una prueba suelta el reloj
/// falso (`runAsync`, como hace `textContrastGuideline`), el fallo llega
/// como excepción no capturada. Este cliente deja la descarga pendiente
/// para siempre: el texto se pinta con la fuente de pruebas, igual que en
/// el resto de widget tests.
class _PendingHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _PendingHttpClient();
}

class _PendingHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      Completer<HttpClientRequest>().future;

  @override
  Future<HttpClientRequest> getUrl(Uri url) =>
      Completer<HttpClientRequest>().future;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Monta [screen] en la app real.
///
/// - [textScale]: escalado del sistema (`textScaleFactorTestValue`).
/// - [largeText]: preferencia «Texto más grande» (×1,125 encima).
/// - [disableAnimations]: accesibilidad del sistema.
/// - [reduceAnimations]: preferencia de la app.
/// - [settle]: si es `false` solo bombea un par de frames (lo usa la prueba
///   de movimiento, que mide ella misma cuánto tarda en asentarse).
Future<void> pumpA11yScreen(
  WidgetTester tester,
  A11yScreen screen, {
  Size size = const Size(360, 800),
  ThemeMode mode = ThemeMode.light,
  double textScale = 1.0,
  bool largeText = false,
  bool disableAnimations = false,
  bool reduceAnimations = false,
  bool settle = true,
}) async {
  HttpOverrides.global = _PendingHttpOverrides();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  if (textScale != 1.0) {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  if (disableAnimations) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  SharedPreferences.setMockInitialValues({
    if (!screen.onboarding) onboardingCompleteKey: true,
    clusterEnabledKey: false,
    reduceAnimationsKey: reduceAnimations,
    largeTextKey: largeText,
  });

  final srs = SRSSystem(
    repository: InMemoryProgressRepository(),
    random: Random(42),
    clock: () => DateTime(2026, 10, 7, 18),
  );
  await srs.loadProgress();

  final router = createAppRouter(
    refreshListenable: ValueNotifier(0),
    initialLocation: screen.route,
  );
  _currentRouter = router;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        goRouterProvider.overrideWithValue(router),
        appThemeModeProvider.overrideWithValue(mode),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 7, 18)),
        progressRepositoryProvider.overrideWithValue(
          InMemoryProgressRepository(),
        ),
        srsSystemProvider.overrideWith(() => _FakeSRSNotifier(srs)),
        subscriptionStatusProvider.overrideWith(_ProSubscriptionNotifier.new),
        audioPlayerServiceProvider.overrideWithValue(_SilentAudio()),
        audioGeneratorProvider.overrideWithValue(
          AudioGenerator(random: Random(42)),
        ),
      ],
      child: const TogescApp(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
}

GoRouter? _currentRouter;

/// Sale a Home antes de que el test desmonte el `ProviderScope`.
///
/// `GameScreen.deactivate` (lib/screens/game_screen.dart:179) programa una
/// escritura en providers; si la pantalla se desmonta junto con el scope
/// (solo pasa al terminar un test) Riverpod lanza `StateError`. En la app
/// real el scope nunca se desmonta, así que no es una barrera.
///
/// Antes de salir se quita el escalado de texto de prueba para que los
/// desbordes de Home no se atribuyan a la pantalla auditada.
///
/// Con `reduceAnimations` se desactiva antes la preferencia: con ella
/// activa la transición de salida se congela (barrera documentada en
/// `a11y_reduced_motion_test.dart`) y la pantalla no llegaría a desmontarse.
Future<void> leaveA11yScreen(WidgetTester tester) async {
  tester.platformDispatcher.clearTextScaleFactorTestValue();
  final app = find.byType(TogescApp);
  if (app.evaluate().isNotEmpty) {
    final container = ProviderScope.containerOf(tester.element(app));
    if (container.read(uiPreferencesProvider).valueOrNull?.reduceAnimations ??
        false) {
      await container
          .read(uiPreferencesProvider.notifier)
          .setReduceAnimations(false);
      await tester.pump();
    }
  }
  _currentRouter?.go(AppRoutes.home);
  await pumpFor(tester, const Duration(seconds: 2));
}

/// Con un deep link directo a la sesión nadie ha leído aún el SRS (en la
/// app lo hace Home); sin esto «Estoy listo» vuelve a «Preparado».
Future<void> _loadSrs(WidgetTester tester) async {
  ProviderScope.containerOf(
    tester.element(find.byType(TogescApp)),
  ).read(srsSystemProvider);
  await tester.pump();
  await tester.pump();
}

/// Juego: pulsa «Estoy listo» y espera a la fase «Responde» (teclado
/// visible y activo).
Future<void> startGameSession(WidgetTester tester) async {
  await _loadSrs(tester);
  final start = find.byKey(const ValueKey('session-start'));
  await tester.ensureVisible(start);
  await tester.tap(start);
  await pumpFor(tester, const Duration(milliseconds: 2500));
}

/// Velocidad: pulsa «Comenzar» y pasa la cuenta atrás 3-2-1 hasta que el
/// temporizador corre.
Future<void> startSpeedSession(WidgetTester tester) async {
  await _loadSrs(tester);
  final start = find.text('Comenzar');
  await tester.ensureVisible(start);
  await tester.tap(start);
  await pumpFor(tester, const Duration(milliseconds: 2900));
}

/// Avanza [total] en pasos de 100 ms (las sesiones tienen temporizadores
/// y no siempre se pueden asentar con `pumpAndSettle`).
Future<void> pumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 100);
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}

/// `--dart-define=A11Y_RUN_KNOWN=true` ejecuta también las pruebas de las
/// barreras conocidas (para comprobar un arreglo antes de quitar el skip).
const bool _runKnownBarriers = bool.fromEnvironment('A11Y_RUN_KNOWN');

/// `testWidgets` que, si [barrier] no es nulo, queda en `skip` con ese
/// motivo (`testWidgets` solo acepta `bool`; `group` sí imprime el texto).
void a11yTestWidgets(
  String description,
  WidgetTesterCallback body, {
  String? barrier,
}) {
  if (barrier == null || _runKnownBarriers) {
    testWidgets(description, body);
    return;
  }
  group(
    description,
    () => testWidgets('barrera conocida', body),
    skip: barrier,
  );
}
