import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/models/sync_diagnostics.dart';
import 'package:togesc/utils/session_timestamp.dart';

void main() {
  group('SessionTimestamp', () {
    test('match acepta mismo instante con distinto formato ISO', () {
      expect(
        SessionTimestamp.match(
          '2026-06-23T15:08:11.868',
          '2026-06-23T15:08:11.868+00:00',
        ),
        isTrue,
      );
    });

    test('isRemoteNewer es false para el mismo instante', () {
      expect(
        SessionTimestamp.isRemoteNewer(
          '2026-06-23T15:08:11.868',
          '2026-06-23T15:08:11.868+00:00',
        ),
        isFalse,
      );
    });

    test('isRemoteNewer detecta remoto posterior', () {
      expect(
        SessionTimestamp.isRemoteNewer(
          '2026-06-23T15:08:11.868',
          '2026-06-23T16:00:00.000+00:00',
        ),
        isTrue,
      );
    });
  });

  group('SyncDiagnostics', () {
    test('isInSync es true cuando local y remoto son el mismo instante', () {
      const diag = SyncDiagnostics(
        cloudSyncEnabled: true,
        hasSession: true,
        localSession: '2026-06-23T15:08:11.868',
        remoteSession: '2026-06-23T15:08:11.868+00:00',
        remoteReachable: true,
      );

      expect(diag.isInSync, isTrue);
      expect(diag.statusLabel, 'Local y nube alineados.');
    });

    test('isInSync es false cuando los instantes difieren', () {
      const diag = SyncDiagnostics(
        cloudSyncEnabled: true,
        hasSession: true,
        localSession: '2026-06-23T15:08:11.868',
        remoteSession: '2026-06-23T16:00:00.000+00:00',
        remoteReachable: true,
      );

      expect(diag.isInSync, isFalse);
    });
  });
}
