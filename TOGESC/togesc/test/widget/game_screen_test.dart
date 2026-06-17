import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/providers/audio_provider.dart';
import 'package:togesc/providers/srs_provider.dart';
import 'package:togesc/screens/game_screen.dart';
import 'package:togesc/services/audio_generator.dart';
import 'package:togesc/services/audio_player_service.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/services/srs_system.dart';

class _FakeSRSNotifier extends AsyncNotifier<SRSSystem>
    implements SRSNotifier {
  final SRSSystem _srs;
  _FakeSRSNotifier(this._srs);

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
  late SRSSystem srs;
  late ProviderContainer container;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
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
        srsSystemProvider.overrideWith(() => _FakeSRSNotifier(srs)),
        audioPlayerServiceProvider.overrideWithValue(
          AudioPlayerService(generator: AudioGenerator(random: Random(42))),
        ),
        audioGeneratorProvider
            .overrideWithValue(AudioGenerator(random: Random(42))),
      ],
    );
    // Pre-cargar el AsyncNotifier para que valueOrNull no sea null en startRound
    await container.read(srsSystemProvider.future);
  });

  tearDown(() => container.dispose());

  Widget buildApp({GameMode mode = GameMode.singleNote}) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: GameScreen(mode: mode)),
    );
  }

  group('GameScreen', () {
    testWidgets('muestra vista idle inicial con boton Reproducir',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Preparate para escuchar'), findsOneWidget);
      expect(find.text('Reproducir'), findsOneWidget);
    });

    testWidgets('muestra titulo del modo en appbar', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text(GameMode.singleNote.displayName), findsOneWidget);
    });

    testWidgets('muestra boton de toggle instrumento', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Preferencias: aleatorio'), findsOneWidget);
    });

    testWidgets('tap en Reproducir transiciona a vista de respuesta',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reproducir'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Confirmar'), findsOneWidget);
    });

    testWidgets('piano keyboard se renderiza en vista de respuesta',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reproducir'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('C'), findsAtLeast(1));
      expect(find.text('D'), findsAtLeast(1));
      expect(find.text('E'), findsAtLeast(1));
    });

    testWidgets('boton Repetir esta disponible en vista de respuesta',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reproducir'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Repetir'), findsOneWidget);
    });

    testWidgets('campo de texto alternativo presente', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reproducir'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
