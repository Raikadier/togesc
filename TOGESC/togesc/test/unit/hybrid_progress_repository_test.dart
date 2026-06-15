import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/models/note_data.dart';
import 'package:togesc/services/hybrid_progress_repository.dart';
import 'package:togesc/services/progress_repository.dart';

void main() {
  group('HybridProgressRepository', () {
    late InMemoryProgressRepository local;
    InMemoryProgressRepository? remote;
    late HybridProgressRepository hybrid;

    setUp(() {
      local = InMemoryProgressRepository();
      remote = InMemoryProgressRepository();
      hybrid = HybridProgressRepository(
        local: local,
        remoteFactory: () async => remote,
      );
    });

    test('sin remoto delega en local', () async {
      final offline = HybridProgressRepository(
        local: local,
        remoteFactory: () async => null,
      );
      await offline.save({'C': NoteData(weight: 3.0)});
      final loaded = await offline.load();
      expect(loaded!['C']!.weight, 3.0);
    });

    test('save escribe local y remoto', () async {
      await hybrid.save({'D': NoteData(weight: 5.0)});
      expect(await local.load(), isNotNull);
      expect(await remote!.load(), isNotNull);
      expect((await remote!.load())!['D']!.weight, 5.0);
    });

    test('load prefiere remoto si last_session es mas reciente', () async {
      await local.save(
        {'C': NoteData(weight: 1.0)},
        lastSession: '2026-01-01T10:00:00.000',
      );
      await remote!.save(
        {'C': NoteData(weight: 9.0)},
        lastSession: '2026-06-01T10:00:00.000',
      );

      final loaded = await hybrid.load();
      expect(loaded!['C']!.weight, 9.0);
      expect((await local.load())!['C']!.weight, 9.0);
    });

    test('mergeOnSignIn sube local si remoto vacio', () async {
      await local.save({'E': NoteData(weight: 4.0)});
      await hybrid.mergeOnSignIn();
      expect(await remote!.load(), isNotNull);
    });
  });
}
