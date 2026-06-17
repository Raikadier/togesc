import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/models/last_practice_session.dart';
import 'package:togesc/providers/srs_provider.dart';
import 'package:togesc/providers/subscription_provider.dart';
import 'package:togesc/models/subscription_status.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/services/srs_system.dart';
import 'package:togesc/services/app_preferences.dart';
import '../helpers/test_app_router.dart';

void main() {
  late SRSSystem srs;

  setUp(() async {
    markOnboardingCompleteForTests();
    srs = SRSSystem(random: Random(42), clock: () => DateTime(2026, 1, 1));
    await srs.loadProgress();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(InMemoryProgressRepository()),
        srsSystemProvider.overrideWith(() => _FakeSRSNotifier(srs)),
        subscriptionStatusProvider.overrideWith(
          () => _TestSubscriptionNotifier(),
        ),
      ],
      child: MaterialApp.router(routerConfig: buildTestRouter()),
    );
  }

  group('HomeScreen', () {
    testWidgets('muestra titulo', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Entrenador de Oido Absoluto'), findsOneWidget);
    });

    testWidgets('muestra 6 opciones de modo de juego', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Una sola nota'), findsOneWidget);
      expect(find.text('Intervalo (2 notas)'), findsOneWidget);
      expect(find.text('Acorde (3 notas)'), findsOneWidget);
      expect(find.text('Aleatorio (1-5 notas)'), findsOneWidget);
      expect(find.text('Solo sostenidos'), findsOneWidget);
      expect(find.text('Entrenamiento de velocidad'), findsOneWidget);
    });

    testWidgets('muestra boton de estadisticas en appbar', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Estadisticas'), findsOneWidget);
      expect(find.byTooltip('Acerca de'), findsOneWidget);
    });

    testWidgets('muestra panel de recomendaciones', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Recomendaciones'), findsOneWidget);
    });

    testWidgets('muestra continuar practica tras guardar ultimo modo',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        lastPracticeModeIdKey: GameMode.interval.id,
        lastPracticeKindKey: PracticeKind.game.name,
        lastPracticeAtKey: DateTime(2026, 6, 15).toIso8601String(),
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Continuar practica'), findsOneWidget);
      expect(find.text('Intervalo (2 notas)'), findsWidgets);
    });

    testWidgets('tap en continuar navega al ultimo modo', (tester) async {
      SharedPreferences.setMockInitialValues({
        lastPracticeModeIdKey: GameMode.singleNote.id,
        lastPracticeKindKey: PracticeKind.game.name,
        lastPracticeAtKey: DateTime(2026, 6, 15).toIso8601String(),
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Reproducir'), findsOneWidget);
    });

    testWidgets('tap en modo navega a game screen', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Una sola nota'));
      await tester.pumpAndSettle();

      expect(find.text('Reproducir'), findsOneWidget);
    });
  });
}

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

class _TestSubscriptionNotifier extends SubscriptionNotifier {
  @override
  Future<SubscriptionStatus> build() async {
    return const SubscriptionStatus(
      plan: 'pro',
      status: 'active',
    );
  }
}
