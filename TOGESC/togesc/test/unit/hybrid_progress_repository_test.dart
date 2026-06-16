import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:togesc/models/note_data.dart';
import 'package:togesc/services/hybrid_progress_repository.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/services/sync_pending_store.dart';

class _ThrowingRemoteRepository implements ProgressRepository {
  _ThrowingRemoteRepository(this._inner);

  final ProgressRepository _inner;
  var failNext = false;

  @override
  Future<Map<String, NoteData>?> load() => _inner.load();

  @override
  Future<String?> loadLastSessionIso() => _inner.loadLastSessionIso();

  @override
  Future<void> save(Map<String, NoteData> noteData, {String? lastSession}) async {
    if (failNext) throw StateError('offline');
    await _inner.save(noteData, lastSession: lastSession);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HybridProgressRepository', () {
    late InMemoryProgressRepository local;
    InMemoryProgressRepository? remoteInner;
    _ThrowingRemoteRepository? remote;
    late HybridProgressRepository hybrid;
    late SyncPendingStore pendingStore;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      local = InMemoryProgressRepository();
      remoteInner = InMemoryProgressRepository();
      remote = _ThrowingRemoteRepository(remoteInner!);
      pendingStore = SyncPendingStore();
      hybrid = HybridProgressRepository(
        local: local,
        remoteFactory: () async => remote,
        syncPendingStore: pendingStore,
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
      expect(await remoteInner!.load(), isNotNull);
      expect((await remoteInner!.load())!['D']!.weight, 5.0);
      expect(await pendingStore.isPending, isFalse);
    });

    test('load prefiere remoto si last_session es mas reciente', () async {
      await local.save(
        {'C': NoteData(weight: 1.0)},
        lastSession: '2026-01-01T10:00:00.000',
      );
      await remoteInner!.save(
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
      expect(await remoteInner!.load(), isNotNull);
    });

    test('marca sync pendiente si remoto falla', () async {
      remote!.failNext = true;
      await hybrid.save({'F': NoteData(weight: 2.0)});
      expect(await pendingStore.isPending, isTrue);
      expect(await local.load(), isNotNull);
    });

    test('flushPendingSync sube cambios pendientes', () async {
      remote!.failNext = true;
      await hybrid.save({'G': NoteData(weight: 7.0)});
      expect(await pendingStore.isPending, isTrue);

      remote!.failNext = false;
      final ok = await hybrid.flushPendingSync();
      expect(ok, isTrue);
      expect(await pendingStore.isPending, isFalse);
      expect((await remoteInner!.load())!['G']!.weight, 7.0);
    });
  });
}

