import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/providers/audio_provider.dart';
import 'package:togesc/providers/srs_provider.dart';
import 'package:togesc/services/audio_generator.dart';
import 'package:togesc/services/audio_player_service.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/services/srs_system.dart';
import '../helpers/test_app_router.dart';

class _TestSRSNotifier extends AsyncNotifier<SRSSystem>
    implements SRSNotifier {
  final SRSSystem _srs;
  _TestSRSNotifier(this._srs);

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

void main() {
  group('Integracion: Flujo completo HomeScreen -> GameScreen -> Resultado', () {
    late ProviderContainer container;
    late SRSSystem srs;

    setUp(() async {
      markOnboardingCompleteForTests();
      srs = SRSSystem(
        repository: InMemoryProgressRepository(),
        random: Random(42),
        clock: () => DateTime(2026, 1, 1),
      );
      await srs.loadProgress();

      container = ProviderContainer(
        overrides: [
          progressRepositoryProvider
              .overrideWithValue(InMemoryProgressRepository()),
          srsSystemProvider.overrideWith(() => _TestSRSNotifier(srs)),
          audioPlayerServiceProvider.overrideWithValue(
            AudioPlayerService(generator: AudioGenerator(random: Random(42))),
          ),
          audioGeneratorProvider
              .overrideWithValue(AudioGenerator(random: Random(42))),
        ],
      );
      // Pre-cargar el AsyncNotifier
      await container.read(srsSystemProvider.future);
    });

    tearDown(() => container.dispose());

    Widget buildApp() {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: buildTestRouter()),
      );
    }

    testWidgets('navega de HomeScreen a GameScreen al tocar un modo',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Modos de Juego'), findsOneWidget);
      expect(find.text('Una sola nota'), findsOneWidget);

      await tester.tap(find.text('Una sola nota').first);
      await tester.pumpAndSettle();
      expect(find.text('Reproducir'), findsOneWidget);
    });

    testWidgets('flujo completo: navegar -> reproducir -> responder -> resultado',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // 1. Ir a modo "Una sola nota"
      await tester.tap(find.text('Una sola nota').first);
      await tester.pumpAndSettle();

      // 2. Tap Reproducir
      await tester.tap(find.text('Reproducir'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // 3. Estamos en vista de respuesta
      expect(find.text('Confirmar'), findsOneWidget);

      // 4. Escribir respuesta via campo de texto y enviar
      await tester.enterText(find.byType(TextField), 'C');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // 5. Vista de resultado: aparece boton Siguiente
      expect(find.text('Siguiente'), findsOneWidget);

      // Volver a home para que record() en deactivate termine antes del dispose.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    });

    testWidgets('boton de estadisticas navega a StatisticsScreen',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Estadisticas'), findsAtLeast(1));
    });
  });
}
