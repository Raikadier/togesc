import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:togesc/models/note_data.dart';
import 'package:togesc/services/hybrid_progress_repository.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/services/sync_coordinator.dart';
import 'package:togesc/services/sync_pending_store.dart';

/// Simula dispositivo A (movil) y B (web) compartiendo remoto Supabase.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sync multi-dispositivo', () {
    late InMemoryProgressRepository deviceA;
    late InMemoryProgressRepository deviceB;
    late InMemoryProgressRepository cloud;
    late SyncPendingStore pendingStore;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      pendingStore = SyncPendingStore();
      deviceA = InMemoryProgressRepository();
      deviceB = InMemoryProgressRepository();
      cloud = InMemoryProgressRepository();
    });

    HybridProgressRepository hybridFor(InMemoryProgressRepository local) {
      return HybridProgressRepository(
        local: local,
        remoteFactory: () async => cloud,
        syncPendingStore: pendingStore,
      );
    }

    SyncCoordinator coordinatorFor(InMemoryProgressRepository local) {
      return SyncCoordinator(
        hybrid: hybridFor(local),
        local: local,
        remoteFactory: () async => cloud,
        cloudSyncEnabled: true,
        hasSession: true,
      );
    }

    test('A entrena y B recibe progreso tras sync', () async {
      await deviceA.save(
        {'C': NoteData(weight: 8.0)},
        lastSession: '2026-06-17T10:00:00.000',
      );

      final coordA = coordinatorFor(deviceA);
      await coordA.syncNow();

      final coordB = coordinatorFor(deviceB);
      final diag = await coordB.syncNow();

      expect(diag.isInSync, isTrue);
      final onB = await deviceB.load();
      expect(onB!['C']!.weight, 8.0);
    });

    test('conflicto en misma nota: gana lastSeen mas reciente', () async {
      await cloud.save(
        {
          'D': NoteData(weight: 2.0, lastSeen: '2026-06-17T08:00:00.000'),
        },
        lastSession: '2026-06-17T08:00:00.000',
      );
      await deviceA.save(
        {
          'D': NoteData(weight: 9.0, lastSeen: '2026-06-17T12:00:00.000'),
        },
        lastSession: '2026-06-17T12:00:00.000',
      );

      await coordinatorFor(deviceA).syncNow();

      await deviceB.save(
        {
          'D': NoteData(weight: 1.0, lastSeen: '2026-06-17T09:00:00.000'),
        },
        lastSession: '2026-06-17T09:00:00.000',
      );

      await coordinatorFor(deviceB).syncNow();

      final remote = await cloud.load();
      expect(remote!['D']!.weight, 9.0);
    });

    test('A y B avanzan notas distintas y ambos conservan el progreso', () async {
      await deviceA.save(
        {
          'C': NoteData(weight: 8.0, lastSeen: '2026-06-20T10:00:00.000'),
          'D': NoteData(weight: 7.0, lastSeen: '2026-06-20T11:00:00.000'),
        },
        lastSession: '2026-06-20T11:00:00.000',
      );
      await coordinatorFor(deviceA).syncNow();

      await deviceB.save(
        {
          'F': NoteData(weight: 5.0, lastSeen: '2026-06-21T10:00:00.000'),
          'G': NoteData(weight: 4.0, lastSeen: '2026-06-21T11:00:00.000'),
        },
        lastSession: '2026-06-21T11:00:00.000',
      );
      await coordinatorFor(deviceB).syncNow();

      await coordinatorFor(deviceA).syncNow();

      final onA = await deviceA.load();
      final onB = await deviceB.load();
      final onCloud = await cloud.load();

      for (final map in [onA!, onB!, onCloud!]) {
        expect(map.keys, containsAll(['C', 'D', 'F', 'G']));
        expect(map['C']!.weight, 8.0);
        expect(map['G']!.weight, 4.0);
      }
    });
  });
}
