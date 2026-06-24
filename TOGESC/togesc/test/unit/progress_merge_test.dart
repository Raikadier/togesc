import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/models/note_data.dart';
import 'package:togesc/utils/progress_merge.dart';

void main() {
  group('ProgressMerge', () {
    test('pickNewer conserva notas de ambos lados sin solapamiento', () {
      final local = {
        'C': NoteData(weight: 8.0, lastSeen: '2026-06-20T10:00:00.000'),
        'D': NoteData(weight: 7.0, lastSeen: '2026-06-20T11:00:00.000'),
      };
      final remote = {
        'F': NoteData(weight: 5.0, lastSeen: '2026-06-21T10:00:00.000'),
        'G': NoteData(weight: 4.0, lastSeen: '2026-06-21T11:00:00.000'),
      };

      final merged = ProgressMerge.mergeMaps(local, remote);

      expect(merged.keys, containsAll(['C', 'D', 'F', 'G']));
      expect(merged['C']!.weight, 8.0);
      expect(merged['F']!.weight, 5.0);
    });

    test('pickNewer gana lastSeen mas reciente en la misma nota', () {
      final local = NoteData(weight: 1.0, lastSeen: '2026-06-17T08:00:00.000');
      final remote = NoteData(weight: 9.0, lastSeen: '2026-06-17T12:00:00.000');

      final picked = ProgressMerge.pickNewer(local, remote);
      expect(picked.weight, 9.0);
    });

    test('empate de lastSeen resuelve por timesSeen', () {
      final local = NoteData(
        weight: 1.0,
        lastSeen: '2026-06-17T10:00:00.000',
        timesSeen: 2,
      );
      final remote = NoteData(
        weight: 9.0,
        lastSeen: '2026-06-17T10:00:00.000',
        timesSeen: 5,
      );

      final picked = ProgressMerge.pickNewer(local, remote);
      expect(picked.weight, 9.0);
    });
  });
}
