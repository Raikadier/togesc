import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/providers/srs_provider.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/services/srs_system.dart';

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
  group('Integracion: Persistencia de progreso entre sesiones', () {
    test('SRS guarda y otra instancia carga el mismo estado', () async {
      final repo = InMemoryProgressRepository();

      // Sesion 1: actualizar varias notas y guardar
      final srs1 = SRSSystem(
        repository: repo,
        random: Random(42),
        clock: () => DateTime(2026, 1, 1),
      );
      await srs1.loadProgress();

      srs1.updateAfterResponse(
        notes: ['C'],
        correctNotes: ['C'],
        wrongNotes: <String>{},
        responseTime: 1.5,
      );
      srs1.updateAfterResponse(
        notes: ['D'],
        correctNotes: <String>[],
        wrongNotes: {'D'},
        responseTime: 4.0,
      );
      await srs1.saveProgress();

      // Sesion 2: nueva instancia carga del mismo repo
      final srs2 = SRSSystem(
        repository: repo,
        clock: () => DateTime(2026, 1, 1),
      );
      await srs2.loadProgress();

      final cData = srs2.noteData['C']!;
      final dData = srs2.noteData['D']!;

      // C tuvo un acierto: streak >= 1
      expect(cData.consecutiveCorrect, greaterThanOrEqualTo(1));
      // D tuvo un fallo: streak roto y peso elevado
      expect(dData.consecutiveCorrect, equals(0));
      expect(dData.weight, greaterThan(1.0));
    });

    test('Provider de Riverpod persiste a traves de saveProgress', () async {
      final repo = InMemoryProgressRepository();
      final srs = SRSSystem(
        repository: repo,
        random: Random(42),
        clock: () => DateTime(2026, 1, 1),
      );
      await srs.loadProgress();

      final container = ProviderContainer(
        overrides: [
          progressRepositoryProvider.overrideWithValue(repo),
          srsSystemProvider.overrideWith(() => _TestSRSNotifier(srs)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(srsSystemProvider.future);

      // Modificar via provider y guardar
      srs.updateAfterResponse(
        notes: ['E'],
        correctNotes: ['E'],
        wrongNotes: <String>{},
        responseTime: 2.0,
      );
      await container.read(srsSystemProvider.notifier).saveProgress();

      // Verificar que el repo tiene los datos
      expect(repo.rawData, isNotNull);
      final loaded = await repo.load();
      expect(loaded, isNotNull);
      expect(loaded!['E']!.consecutiveCorrect, greaterThanOrEqualTo(1));
    });

    test('multiples rondas se acumulan correctamente', () async {
      final repo = InMemoryProgressRepository();
      final srs1 = SRSSystem(
        repository: repo,
        random: Random(42),
        clock: () => DateTime(2026, 1, 1),
      );
      await srs1.loadProgress();

      // 5 aciertos consecutivos en C
      for (var i = 0; i < 5; i++) {
        srs1.updateAfterResponse(
          notes: ['C'],
          correctNotes: ['C'],
          wrongNotes: <String>{},
          responseTime: 1.0,
        );
      }
      await srs1.saveProgress();

      // Recargar
      final srs2 = SRSSystem(
        repository: repo,
        clock: () => DateTime(2026, 1, 1),
      );
      await srs2.loadProgress();

      // Tras 5 aciertos C debe haber salido de fase de aprendizaje
      expect(srs2.noteData['C']!.isLearning, isFalse);
    });
  });
}
