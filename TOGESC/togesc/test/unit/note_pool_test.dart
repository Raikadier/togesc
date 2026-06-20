import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/constants/notes.dart';
import 'package:togesc/models/last_practice_session.dart';
import 'package:togesc/models/practice_session_log.dart';
import 'package:togesc/utils/note_pool.dart';

void main() {
  group('resolvePracticeNotePool', () {
    test('sharpsOnly ignora pool configurado', () {
      expect(
        resolvePracticeNotePool(
          mode: GameMode.sharpsOnly,
          configuredPool: ['C', 'D'],
        ),
        sharpNotes,
      );
    });

    test('nota enfocada tiene prioridad', () {
      expect(
        resolvePracticeNotePool(
          mode: GameMode.singleNote,
          configuredPool: ['C', 'D', 'E'],
          focusNote: 'G',
        ),
        ['G'],
      );
    });

    test('pool parcial restringe seleccion SRS', () {
      expect(
        resolvePracticeNotePool(
          mode: GameMode.singleNote,
          configuredPool: ['C', 'E', 'G'],
        ),
        ['C', 'E', 'G'],
      );
    });

    test('pool completo devuelve null (todas las notas)', () {
      expect(
        resolvePracticeNotePool(
          mode: GameMode.singleNote,
          configuredPool: chromaticNotes,
        ),
        isNull,
      );
    });
  });

  group('PracticeSessionLog', () {
    test('serializa y restaura JSON', () {
      final log = PracticeSessionLog(
        modeId: 1,
        kind: PracticeKind.game,
        roundsCompleted: 10,
        correctRounds: 8,
        endedAt: DateTime(2026, 6, 20, 12, 30),
      );
      final restored = PracticeSessionLog.fromJson(log.toJson());
      expect(restored.modeId, 1);
      expect(restored.roundsCompleted, 10);
      expect(restored.correctRounds, 8);
      expect(restored.accuracyPercent, 80);
    });
  });
}
