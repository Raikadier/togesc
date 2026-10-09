import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/app/router.dart';
import 'package:togesc/main.dart';
import 'package:togesc/models/subscription_status.dart';
import 'package:togesc/providers/audio_provider.dart';
import 'package:togesc/providers/game_session_provider.dart';
import 'package:togesc/providers/router_provider.dart';
import 'package:togesc/providers/srs_provider.dart';
import 'package:togesc/providers/subscription_provider.dart';
import 'package:togesc/services/app_preferences.dart';
import 'package:togesc/services/audio_generator.dart';
import 'package:togesc/services/audio_player_service.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/services/srs_system.dart';

/// Rondas de la sesión corta (la meta más pequeña que ofrece Ajustes).
const e2eTargetRounds = 5;

/// `--dart-define=E2E_REAL_AUDIO=true` usa el motor de audio real
/// (flutter_soloud / HTMLAudioElement) en lugar del silencioso. En web los
/// toques sintéticos del test no cuentan como gesto del navegador, así que
/// el audio real puede quedar bloqueado; el flujo no depende de ello porque
/// [AudioPlayerService] traga los fallos de reproducción.
const e2eRealAudio = bool.fromEnvironment('E2E_REAL_AUDIO');

/// Audio determinista para los tests de dispositivo: mismo contrato que
/// [AudioPlayerService] (gesto → listo → reproducir) sin tocar el hardware.
class SilentAudioPlayerService extends AudioPlayerService {
  SilentAudioPlayerService()
    : super(generator: AudioGenerator(random: Random(7)));

  int gestures = 0;
  int plays = 0;

  @override
  bool get isInitialized => true;

  @override
  bool get isAvailable => true;

  @override
  void captureUserGesture() => gestures++;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> waitUntilReady() async => true;

  @override
  Future<void> playBuffer(Float64List samples, {int? sampleRate}) async {
    plays++;
  }

  @override
  Future<void> dispose() async {}
}

class _SeededSRSNotifier extends AsyncNotifier<SRSSystem>
    implements SRSNotifier {
  _SeededSRSNotifier(this._srs);
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
  Future<SubscriptionStatus> build() async =>
      const SubscriptionStatus(plan: 'pro', status: 'active');
}

/// App real ([TogescApp] + router de producción) con datos propios del test:
/// preferencias en memoria, SRS vacío, Pro activo y audio silencioso.
class E2EApp {
  E2EApp._(this.container);

  final ProviderContainer container;

  /// Prepara el estado y monta la app. Cada test parte de cero: no depende
  /// de datos que haya dejado otro test ni del almacenamiento del dispositivo.
  static Future<E2EApp> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      onboardingCompleteKey: true,
      sessionRoundGoalV2Key: e2eTargetRounds,
      clusterEnabledKey: false,
    });
    final srs = SRSSystem(
      repository: InMemoryProgressRepository(),
      random: Random(42),
    );
    await srs.loadProgress();

    final router = createAppRouter(refreshListenable: ValueNotifier(0));
    final container = ProviderContainer(
      overrides: [
        goRouterProvider.overrideWithValue(router),
        progressRepositoryProvider.overrideWithValue(
          InMemoryProgressRepository(),
        ),
        srsSystemProvider.overrideWith(() => _SeededSRSNotifier(srs)),
        subscriptionStatusProvider.overrideWith(
          () => _ProSubscriptionNotifier(),
        ),
        if (!e2eRealAudio)
          audioPlayerServiceProvider.overrideWithValue(
            SilentAudioPlayerService(),
          ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(srsSystemProvider.future);
    await container.read(subscriptionStatusProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TogescApp()),
    );
    await tester.pumpAndSettle();
    return E2EApp._(container);
  }

  GameSessionState get session => container.read(gameSessionProvider);
}

/// Bombea frames hasta que [finder] encuentre algo (espera por condición,
/// nunca por reloj). Funciona igual con el reloj falso de la VM y con el
/// reloj real del dispositivo.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
  String? reason,
}) async {
  const step = Duration(milliseconds: 100);
  var waited = Duration.zero;
  while (finder.evaluate().isEmpty) {
    if (waited >= timeout) {
      fail(
        'Timeout (${timeout.inSeconds}s) esperando $finder'
        '${reason == null ? '' : ' — $reason'}',
      );
    }
    await tester.pump(step);
    waited += step;
  }
}

/// `ensureVisible` + asentar + tocar: los `ListView`/`SingleChildScrollView`
/// con un único hijo construyen todo de golpe y un `tap` fuera de pantalla
/// solo avisa (ver progreso del 2026-10-09).
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

/// Envía la nota con el atajo físico de la sesión (A–G, ⇧ para sostenidos).
Future<void> sendNoteShortcut(WidgetTester tester, String note) async {
  const letters = {
    'A': LogicalKeyboardKey.keyA,
    'B': LogicalKeyboardKey.keyB,
    'C': LogicalKeyboardKey.keyC,
    'D': LogicalKeyboardKey.keyD,
    'E': LogicalKeyboardKey.keyE,
    'F': LogicalKeyboardKey.keyF,
    'G': LogicalKeyboardKey.keyG,
  };
  final key = letters[note[0]]!;
  if (note.endsWith('#')) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  } else {
    await tester.sendKeyEvent(key);
  }
}

/// Capturas de evidencia por pantalla.
///
/// - Android: convierte la superficie de Flutter en imagen una vez por test
///   (con la app asentada) antes de la primera captura.
/// - Web / iOS: captura directa.
/// - VM (`flutter-tester`) o escritorio sin soporte: el canal no existe
///   (`MissingPluginException`) y las capturas se omiten sin fallar.
///
/// Con `flutter drive` las imágenes llegan a `test_driver/integration_test.dart`,
/// que las guarda en `build/evidence/<plataforma>/<nombre>.png`.
/// Separador plataforma/nombre en las capturas (ver test_driver).
const evidenceSeparator = '__';

class Evidence {
  Evidence(this.binding);

  final IntegrationTestWidgetsFlutterBinding binding;
  bool _ready = false;
  bool _unsupported = false;
  final taken = <String>[];

  static String get platform =>
      kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();

  /// Llamar con la app asentada (antes de entrar en la sesión).
  Future<void> prepare(WidgetTester tester) async {
    if (_ready || _unsupported) return;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await binding.convertFlutterSurfaceToImage();
      } on MissingPluginException {
        _unsupported = true;
        return;
      }
      await tester.pumpAndSettle();
    }
    _ready = true;
  }

  Future<void> shot(WidgetTester tester, String name) async {
    if (_unsupported) return;
    if (!_ready) await prepare(tester);
    if (_unsupported) return;
    await tester.pump();
    try {
      // Los `args` de takeScreenshot solo existen en web: la plataforma
      // viaja en el nombre («android__01_home») y el driver la separa.
      await binding.takeScreenshot('$platform$evidenceSeparator$name');
      taken.add(name);
    } on MissingPluginException {
      _unsupported = true;
    }
  }
}
