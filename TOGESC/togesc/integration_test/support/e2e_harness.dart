import 'dart:math';
import 'dart:ui' as ui;

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

/// Tecla física de un atajo y sus datos de evento web (`KeyboardEvent`).
class _ShortcutKey {
  const _ShortcutKey(
    this.logical,
    this.physical,
    this.code,
    this.key,
    this.keyCode,
  );

  final LogicalKeyboardKey logical;
  final PhysicalKeyboardKey physical;
  final String code;
  final String key;
  final int keyCode;
}

const _shortcutKeys = <String, _ShortcutKey>{
  'A': _ShortcutKey(
    LogicalKeyboardKey.keyA,
    PhysicalKeyboardKey.keyA,
    'KeyA',
    'a',
    65,
  ),
  'B': _ShortcutKey(
    LogicalKeyboardKey.keyB,
    PhysicalKeyboardKey.keyB,
    'KeyB',
    'b',
    66,
  ),
  'C': _ShortcutKey(
    LogicalKeyboardKey.keyC,
    PhysicalKeyboardKey.keyC,
    'KeyC',
    'c',
    67,
  ),
  'D': _ShortcutKey(
    LogicalKeyboardKey.keyD,
    PhysicalKeyboardKey.keyD,
    'KeyD',
    'd',
    68,
  ),
  'E': _ShortcutKey(
    LogicalKeyboardKey.keyE,
    PhysicalKeyboardKey.keyE,
    'KeyE',
    'e',
    69,
  ),
  'F': _ShortcutKey(
    LogicalKeyboardKey.keyF,
    PhysicalKeyboardKey.keyF,
    'KeyF',
    'f',
    70,
  ),
  'G': _ShortcutKey(
    LogicalKeyboardKey.keyG,
    PhysicalKeyboardKey.keyG,
    'KeyG',
    'g',
    71,
  ),
  'R': _ShortcutKey(
    LogicalKeyboardKey.keyR,
    PhysicalKeyboardKey.keyR,
    'KeyR',
    'r',
    82,
  ),
  ' ': _ShortcutKey(
    LogicalKeyboardKey.space,
    PhysicalKeyboardKey.space,
    'Space',
    ' ',
    32,
  ),
};

const _shift = _ShortcutKey(
  LogicalKeyboardKey.shiftLeft,
  PhysicalKeyboardKey.shiftLeft,
  'ShiftLeft',
  'Shift',
  16,
);

/// Modificador ⇧ en `metaState` del mensaje web (`RawKeyEventDataWeb`).
const _webMetaShift = 0x01;

/// Envía un evento de tecla como lo hace el motor web: primero `KeyData`
/// y después el mensaje crudo de `flutter/keyevent` con keymap `web`.
///
/// Motivo: en web release `simulateKeyDownEvent` busca la tecla en los
/// mapas de teclado de flutter_test, que dart2js elimina por tree-shaking,
/// y falla con «Null check operator used on a null value» (limitación del
/// arnés, no de la app: la tecla física funciona en la build release).
Future<void> _sendWebKey(
  _ShortcutKey k, {
  required bool down,
  bool shift = false,
  String? character,
}) async {
  // Es la entrada que usa el propio motor (y flutter_test al simular);
  // no hay API pública sustituta para inyectar eventos de hardware.
  // ignore: deprecated_member_use
  ServicesBinding.instance.keyEventManager.handleKeyData(
    ui.KeyData(
      type: down ? ui.KeyEventType.down : ui.KeyEventType.up,
      physical: k.physical.usbHidUsage,
      logical: k.logical.keyId,
      timeStamp: Duration.zero,
      character: down ? character : null,
      synthesized: false,
    ),
  );
  final message = <String, Object?>{
    'type': down ? 'keydown' : 'keyup',
    'keymap': 'web',
    'code': k.code,
    'key': character ?? k.key,
    'location': k == _shift ? 1 : 0,
    'metaState': shift ? _webMetaShift : 0,
    'keyCode': k.keyCode,
  };
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(message),
        (ByteData? _) {},
      );
}

/// Pulsa y suelta un atajo (`'A'`–`'G'`, `'R'` o `' '`), con ⇧ si [shift].
Future<void> sendShortcut(
  WidgetTester tester,
  String id, {
  bool shift = false,
  @visibleForTesting bool webPath = kIsWeb,
}) async {
  final k = _shortcutKeys[id];
  if (k == null) throw ArgumentError.value(id, 'id', 'atajo no soportado');
  if (!webPath) {
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(k.logical);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    return;
  }
  final character = id == ' ' ? ' ' : (shift ? k.key.toUpperCase() : k.key);
  if (shift) await _sendWebKey(_shift, down: true, shift: true);
  await _sendWebKey(k, down: true, shift: shift, character: character);
  await _sendWebKey(k, down: false, shift: shift, character: null);
  if (shift) await _sendWebKey(_shift, down: false);
  await tester.pump();
}

/// Envía la nota con el atajo físico de la sesión (A–G, ⇧ para sostenidos).
Future<void> sendNoteShortcut(WidgetTester tester, String note) =>
    sendShortcut(tester, note[0], shift: note.endsWith('#'));

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

/// Migas de pan para depurar desde los artefactos: `flutter drive` en web
/// release puede devolver `details` vacío, pero `reportData` siempre llega
/// en la respuesta del driver (campo `data`).
void e2eStep(IntegrationTestWidgetsFlutterBinding binding, String step) {
  final data = binding.reportData ??= <String, dynamic>{};
  (data['steps'] ??= <dynamic>[]) as List<dynamic>;
  (data['steps'] as List<dynamic>).add(step);
}

/// Ejecuta [body] y, si falla, deja el tipo y el mensaje del error en
/// `reportData['error']` antes de relanzarlo.
Future<void> traced(
  IntegrationTestWidgetsFlutterBinding binding,
  Future<void> Function() body,
) async {
  try {
    await body();
  } catch (e, st) {
    final data = binding.reportData ??= <String, dynamic>{};
    data['error'] = '${e.runtimeType}: $e\n$st';
    rethrow;
  }
}
