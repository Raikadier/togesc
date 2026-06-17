import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/app/router.dart';
import 'package:togesc/constants/notes.dart';
import 'package:togesc/models/subscription_status.dart';
import 'package:togesc/providers/srs_provider.dart';
import 'package:togesc/providers/subscription_provider.dart';
import 'package:togesc/screens/note_progress_screen.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/services/srs_system.dart';

void main() {
  late SRSSystem srs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    srs = SRSSystem(
      repository: InMemoryProgressRepository(),
      random: Random(42),
      clock: () => DateTime(2026, 1, 1),
    );
    await srs.loadProgress();
  });

  Widget buildApp({SubscriptionStatus status = const SubscriptionStatus.free()}) {
    final router = GoRouter(
      initialLocation: AppRoutes.statisticsNotes,
      routes: [
        GoRoute(
          path: AppRoutes.statisticsNotes,
          builder: (_, _) => const NoteProgressScreen(),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(InMemoryProgressRepository()),
        srsSystemProvider.overrideWith(() => _FakeSRSNotifier(srs)),
        subscriptionStatusProvider.overrideWith(
          () => _TestSubscriptionNotifier(status),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('muestra las 12 notas', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Progreso por nota'), findsOneWidget);
    for (final note in notes.keys) {
      await tester.scrollUntilVisible(
        find.text(note).first,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(note), findsWidgets);
    }
  });

  testWidgets('muestra acciones de practica por nota', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.play_arrow_rounded), findsNWidgets(12));
  });

  testWidgets('pro muestra metricas detalladas', (tester) async {
    await tester.pumpWidget(
      buildApp(
        status: const SubscriptionStatus(plan: 'pro', status: 'active'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Practicar '), findsWidgets);
    expect(find.text('Precision'), findsWidgets);
  });
}

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

class _TestSubscriptionNotifier extends SubscriptionNotifier {
  final SubscriptionStatus _status;
  _TestSubscriptionNotifier(this._status);

  @override
  Future<SubscriptionStatus> build() async => _status;
}
