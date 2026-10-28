import 'dart:math';

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

  group('resolveFocusRoundPool', () {
    const focus = ['E', 'G', 'A'];

    test('ronda de foco usa solo las notas de foco', () {
      expect(
        resolveFocusRoundPool(
          mode: GameMode.singleNote,
          configuredPool: chromaticNotes,
          focusNotes: focus,
          numNotes: 1,
          random: _FixedRandom(0.0),
        ),
        focus,
      );
    });

    test('resto de rondas usa el pool configurado (no solo el foco)', () {
      expect(
        resolveFocusRoundPool(
          mode: GameMode.singleNote,
          configuredPool: chromaticNotes,
          focusNotes: focus,
          numNotes: 1,
          random: _FixedRandom(0.99),
        ),
        isNull,
      );
      expect(
        resolveFocusRoundPool(
          mode: GameMode.singleNote,
          configuredPool: ['C', 'D'],
          focusNotes: focus,
          numNotes: 1,
          random: _FixedRandom(0.99),
        ),
        ['C', 'D'],
      );
    });

    test('el umbral es focusRoundShare', () {
      List<String>? pool(double r) => resolveFocusRoundPool(
            mode: GameMode.singleNote,
            configuredPool: chromaticNotes,
            focusNotes: focus,
            numNotes: 1,
            random: _FixedRandom(r),
          );
      expect(pool(focusRoundShare - 0.01), focus);
      expect(pool(focusRoundShare), isNull);
    });

    test('sin suficientes notas de foco para el modo usa el pool base', () {
      expect(
        resolveFocusRoundPool(
          mode: GameMode.chord,
          configuredPool: chromaticNotes,
          focusNotes: const ['E', 'G'],
          numNotes: 3,
          random: _FixedRandom(0.0),
        ),
        isNull,
      );
    });

    test('notas invalidas y duplicadas se descartan', () {
      expect(
        resolveFocusRoundPool(
          mode: GameMode.singleNote,
          configuredPool: chromaticNotes,
          focusNotes: const ['X', 'E', 'E'],
          numNotes: 1,
          random: _FixedRandom(0.0),
        ),
        ['E'],
      );
    });

    test('sin foco o en sharpsOnly se comporta como resolvePracticeNotePool',
        () {
      expect(
        resolveFocusRoundPool(
          mode: GameMode.singleNote,
          configuredPool: ['C', 'E'],
          focusNotes: const [],
          numNotes: 1,
          random: _FixedRandom(0.0),
        ),
        ['C', 'E'],
      );
      expect(
        resolveFocusRoundPool(
          mode: GameMode.sharpsOnly,
          configuredPool: chromaticNotes,
          focusNotes: focus,
          numNotes: 1,
          random: _FixedRandom(0.0),
        ),
        sharpNotes,
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

/// Random con nextDouble fijo para decidir rondas de foco.
class _FixedRandom implements Random {
  _FixedRandom(this.value);

  final double value;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}
