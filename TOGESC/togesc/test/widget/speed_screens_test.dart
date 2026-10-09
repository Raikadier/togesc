import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/app/app_theme.dart';
import 'package:togesc/app/design_tokens.dart';
import 'package:togesc/app/togesc_colors.dart';
import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/providers/audio_provider.dart';
import 'package:togesc/providers/srs_provider.dart';
import 'package:togesc/screens/speed_game_screen.dart';
import 'package:togesc/screens/speed_mode_select_screen.dart';
import 'package:togesc/services/audio_generator.dart';
import 'package:togesc/services/audio_player_service.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/services/srs_system.dart';
import 'package:togesc/widgets/speed_session_views.dart';

class _FakeSRSNotifier extends AsyncNotifier<SRSSystem> implements SRSNotifier {
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

/// Lote 3: velocidad adopta los tokens v2 y la sesión oscura.
void main() {
  late SRSSystem srs;
  late InMemoryProgressRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = InMemoryProgressRepository();
    srs = SRSSystem(
      repository: repo,
      random: Random(42),
      clock: () => DateTime(2026, 1, 1),
    );
    await srs.loadProgress();
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repo),
        srsSystemProvider.overrideWith(() => _FakeSRSNotifier(srs)),
        audioPlayerServiceProvider.overrideWithValue(
          AudioPlayerService(generator: AudioGenerator(random: Random(42))),
        ),
        audioGeneratorProvider.overrideWithValue(
          AudioGenerator(random: Random(42)),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light, home: child),
    );
  }

  group('Contraste de los tokens de velocidad', () {
    test('acento claro AA como relleno y como texto', () {
      const light = TogescColors.light;
      expect(
        contrastRatio(light.onSpeedAccent, light.speedAccent),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(light.speedAccent, DesignTokens.background),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(light.speedAccent, DesignTokens.speedContainer),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('acento oscuro y de sesión AA', () {
      for (final c in [TogescColors.dark, TogescColors.session]) {
        expect(c.speedAccent, DesignTokens.speedAccentOnDark);
        expect(
          contrastRatio(c.onSpeedAccent, c.speedAccent),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrastRatio(c.speedAccent, DesignTokens.sessionBackground),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('card «Teclas negras» sobre hero', () {
      expect(
        contrastRatio(DesignTokens.onHero, DesignTokens.hero),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(DesignTokens.speedAccentOnDark, DesignTokens.hero),
        greaterThanOrEqualTo(3),
      );
    });
  });

  testWidgets('SpeedGameScreen usa el tema oscuro de sesión', (tester) async {
    await tester.pumpWidget(
      wrap(const SpeedGameScreen(targetMode: GameMode.singleNote)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Listo para el desafío'), findsOneWidget);
    final context = tester.element(find.text('Listo para el desafío'));
    final theme = Theme.of(context);
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, DesignTokens.sessionBackground);
    expect(TogescColors.of(context).speedAccent, DesignTokens.speedAccentOnDark);
  });

  testWidgets('resumen de velocidad usa onSpeedAccent y cifras tabulares', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.session,
        home: const Scaffold(
          body: SpeedSessionSummaryCard(
            responses: 7,
            streak: 3,
            averageTime: 1.5,
            bestTime: 0.9,
            timeLimit: 4,
          ),
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('Resumen de velocidad'));
    expect(title.style?.color, TogescColors.session.onSpeedAccent);
    final value = tester.widget<Text>(find.text('1.50s'));
    expect(value.style?.color, TogescColors.session.onSpeedAccent);
    expect(
      value.style?.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  testWidgets('selector de velocidad muestra los 5 modos y la dificultad', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const SpeedModeSelectScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(SpeedModeOptionCard), findsNWidgets(5));
    expect(find.text('TIEMPO INICIAL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
