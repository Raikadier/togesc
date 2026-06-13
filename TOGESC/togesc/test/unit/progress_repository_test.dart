import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:togesc/models/note_data.dart';
import 'package:togesc/services/progress_repository.dart';

void main() {
  group('InMemoryProgressRepository', () {
    late InMemoryProgressRepository repo;

    setUp(() {
      repo = InMemoryProgressRepository();
    });

    test('load retorna null cuando no hay datos', () async {
      expect(await repo.load(), isNull);
    });

    test('save y load roundtrip preserva datos', () async {
      final data = {
        'C': NoteData(weight: 5.0, consecutiveCorrect: 3),
        'D': NoteData(weight: 8.0, isLearning: false),
      };

      await repo.save(data);
      final loaded = await repo.load();

      expect(loaded, isNotNull);
      expect(loaded!.length, 2);
      expect(loaded['C']!.weight, 5.0);
      expect(loaded['C']!.consecutiveCorrect, 3);
      expect(loaded['D']!.weight, 8.0);
      expect(loaded['D']!.isLearning, isFalse);
    });

    test('save incluye version y last_session en raw data', () async {
      await repo.save({'C': NoteData()});
      final raw = repo.rawData!;

      expect(raw['version'], '3.0.0');
      expect(raw['last_session'], isNotNull);
    });

    test('multiples saves sobreescriben datos anteriores', () async {
      await repo.save({'C': NoteData(weight: 5.0)});
      await repo.save({'C': NoteData(weight: 8.0)});

      final loaded = await repo.load();
      expect(loaded!['C']!.weight, 8.0);
    });

    test('load con formato legacy migra weights a NoteData', () async {
      repo.loadLegacyFormat({'C': 5.0, 'D': 8.0});
      final loaded = await repo.load();

      expect(loaded, isNotNull);
      expect(loaded!['C']!.weight, 5.0);
      expect(loaded['D']!.weight, 8.0);
    });
  });

  group('SharedPreferencesProgressRepository', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('load retorna null sin datos guardados', () async {
      final repo = SharedPreferencesProgressRepository(prefs: prefs);
      expect(await repo.load(), isNull);
    });

    test('save y load roundtrip', () async {
      final repo = SharedPreferencesProgressRepository(prefs: prefs);
      await repo.save({
        'G': NoteData(weight: 12.0, consecutiveCorrect: 2),
      });

      final loaded = await repo.load();
      expect(loaded!['G']!.weight, 12.0);
      expect(loaded['G']!.consecutiveCorrect, 2);
    });

    test('migra formato legacy desde SharedPreferences', () async {
      await prefs.setString(
        progressStorageKey,
        '{"weights":{"C":7.5,"F":9.0}}',
      );
      final repo = SharedPreferencesProgressRepository(prefs: prefs);
      final loaded = await repo.load();

      expect(loaded!['C']!.weight, 7.5);
      expect(loaded['F']!.weight, 9.0);
    });
  });

  group('parseProgressPayload', () {
    test('retorna null con mapa vacio', () {
      expect(parseProgressPayload({}), isNull);
    });
  });
}
