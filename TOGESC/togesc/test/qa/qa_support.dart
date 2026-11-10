// Soporte compartido de los tests QA (`test/qa/qa_*_test.dart`).
//
// Reutiliza los patrones de `test/widget/game_screen_test.dart` y
// `test/widget/speed_screens_test.dart`: SRS en memoria con reloj y semilla
// fijos, y audio sin hardware.
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/providers/audio_provider.dart';
import 'package:togesc/providers/practice_focus_provider.dart';
import 'package:togesc/providers/srs_provider.dart';
import 'package:togesc/screens/game_screen.dart';
import 'package:togesc/services/app_preferences.dart';
import 'package:togesc/services/audio_generator.dart';
import 'package:togesc/services/audio_player_service.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/services/srs_system.dart';

/// SRS ya cargado, sin tocar disco.
class QaFakeSrsNotifier extends AsyncNotifier<SRSSystem>
    implements SRSNotifier {
  QaFakeSrsNotifier(this._srs);

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

/// Audio sin hardware: mismo contrato que [AudioPlayerService].
class QaSilentAudio extends AudioPlayerService {
  QaSilentAudio() : super(generator: AudioGenerator(random: Random(7)));

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

/// SRS determinista (semilla 42, 1-ene-2026).
Future<SRSSystem> qaLoadedSrs() async {
  final srs = SRSSystem(
    repository: InMemoryProgressRepository(),
    random: Random(42),
    clock: () => DateTime(2026, 1, 1),
  );
  await srs.loadProgress();
  return srs;
}

/// Overrides con SRS y audio de prueba; fija antes las preferencias.
Future<(List<Override>, SRSSystem)> qaGameOverrides({
  Map<String, Object> prefs = const {},
  bool silentAudio = false,
}) async {
  SharedPreferences.setMockInitialValues({clusterEnabledKey: false, ...prefs});
  final srs = await qaLoadedSrs();
  return (
    <Override>[
      progressRepositoryProvider.overrideWithValue(
        InMemoryProgressRepository(),
      ),
      srsSystemProvider.overrideWith(() => QaFakeSrsNotifier(srs)),
      audioPlayerServiceProvider.overrideWithValue(
        silentAudio
            ? QaSilentAudio()
            : AudioPlayerService(generator: AudioGenerator(random: Random(42))),
      ),
      audioGeneratorProvider.overrideWithValue(
        AudioGenerator(random: Random(42)),
      ),
    ],
    srs,
  );
}

/// Contenedor con el SRS ya cargado (como en la app, donde lo carga el
/// Home) y, opcionalmente, una nota de foco para rondas deterministas.
///
/// Registra su propio desmontaje: primero se desmonta el árbol (para que el
/// `deactivate` de las pantallas escriba en un contenedor vivo) y después se
/// desecha el contenedor. Así un test que falla no contamina al siguiente.
Future<(ProviderContainer, SRSSystem)> qaGameContainer(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  bool silentAudio = false,
  String? focusNote,
}) async {
  final (overrides, srs) = await qaGameOverrides(
    prefs: prefs,
    silentAudio: silentAudio,
  );
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  await container.read(srsSystemProvider.future);
  if (focusNote != null) {
    container.read(practiceFocusNoteProvider.notifier).state = focusNote;
  }
  return (container, srs);
}

/// Monta [GameScreen] con `autoStart` y llega a `RESPONDE`.
Future<void> qaPumpGameToAnswer(
  WidgetTester tester, {
  required ProviderContainer container,
  GameMode mode = GameMode.singleNote,
  Size size = const Size(390, 844),
}) async {
  qaSetViewSize(tester, size);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: GameScreen(mode: mode, autoStart: true)),
    ),
  );
  await qaPumpFor(tester, const Duration(milliseconds: 2000));
  expect(find.text('RESPONDE'), findsOneWidget);
}

/// Contenedor del `ProviderScope` que envuelve a [finder].
ProviderContainer qaContainerOf(WidgetTester tester, Finder finder) =>
    ProviderScope.containerOf(tester.element(finder));

/// Avanza el reloj de prueba en pasos de 100 ms (sin `pumpAndSettle`, que
/// no termina con animaciones infinitas).
Future<void> qaPumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 100);
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}

/// Fija el tamaño lógico de la vista (dpr 1) y lo restaura al terminar.
void qaSetViewSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Con `--dart-define=QA_RUN_BUGS=true` los tests marcados como BUG se
/// ejecutan (y fallan mientras el bug siga vivo). Por defecto se saltan para
/// no romper la CI.
const bool qaRunBugs = bool.fromEnvironment('QA_RUN_BUGS');

/// `testWidgets` solo admite `skip: bool`: la descripción del bug va en el
/// nombre del test (`'… [BUG: …]'`) y la regla de salto en esta constante.
const bool qaSkipBug = !qaRunBugs;
