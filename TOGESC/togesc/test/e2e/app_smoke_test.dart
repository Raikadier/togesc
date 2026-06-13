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
  group('E2E: Smoke test de la aplicacion completa', () {
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
      await container.read(srsSystemProvider.future);
    });

    tearDown(() => container.dispose());

    Widget buildApp() {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: buildTestRouter()),
      );
    }

    testWidgets('app inicia y renderiza HomeScreen sin errores',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Entrenador de Oido Absoluto'), findsOneWidget);
      expect(find.text('Modos de Juego'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('navegacion a todos los modos basicos sin errores',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final modos = [
        'Una sola nota',
        'Intervalo (2 notas)',
        'Acorde (3 notas)',
        'Aleatorio (1-5 notas)',
        'Solo sostenidos',
      ];

      for (final modo in modos) {
        await tester.scrollUntilVisible(find.text(modo), 100,
            scrollable: find.byType(Scrollable).first);
        await tester.tap(find.text(modo));
        await tester.pumpAndSettle();
        expect(find.text('Reproducir'), findsOneWidget,
            reason: 'Modo $modo deberia mostrar boton Reproducir');
        // Volver a home
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('navegacion a entrenamiento de velocidad', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
          find.text('Entrenamiento de velocidad'), 100,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Entrenamiento de velocidad'));
      await tester.pumpAndSettle();

      expect(find.text('Velocidad - Elige modo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('navegacion a estadisticas', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Estadisticas'));
      await tester.pumpAndSettle();

      expect(find.text('Estadisticas'), findsAtLeast(1));
      expect(tester.takeException(), isNull);
    });
  });
}
