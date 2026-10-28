import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/models/note_progress_summary.dart';
import 'package:togesc/widgets/session_v2/session_phase.dart';
import 'package:togesc/widgets/session_v2/session_shortcuts.dart';
import 'package:togesc/widgets/session_v2/session_srs_panel.dart';
import 'package:togesc/widgets/session_v2/session_top_bar.dart';

void main() {
  group('sessionShortcutFor', () {
    test('A–G responde la nota natural', () {
      expect(
        sessionShortcutFor(LogicalKeyboardKey.keyA),
        const SessionShortcut.note('A'),
      );
      expect(
        sessionShortcutFor(LogicalKeyboardKey.keyG),
        const SessionShortcut.note('G'),
      );
    });

    test('⇧ + letra es sostenido; ⇧E y ⇧B no existen', () {
      expect(
        sessionShortcutFor(LogicalKeyboardKey.keyF, shift: true),
        const SessionShortcut.note('F#'),
      );
      expect(sessionShortcutFor(LogicalKeyboardKey.keyE, shift: true), isNull);
      expect(sessionShortcutFor(LogicalKeyboardKey.keyB, shift: true), isNull);
    });

    test('R repite y Espacio es siguiente', () {
      expect(
        sessionShortcutFor(LogicalKeyboardKey.keyR),
        const SessionShortcut.repeat(),
      );
      expect(
        sessionShortcutFor(LogicalKeyboardKey.space),
        const SessionShortcut.next(),
      );
    });

    test('Esc pausa (v2.1)', () {
      expect(
        sessionShortcutFor(LogicalKeyboardKey.escape),
        const SessionShortcut.pause(),
      );
      expect(
        const SessionShortcut.pause(),
        isNot(const SessionShortcut.next()),
      );
    });

    test('con Ctrl/Alt/Meta no hay atajo (no pisa Ctrl+R)', () {
      expect(
        sessionShortcutFor(LogicalKeyboardKey.keyR, otherModifier: true),
        isNull,
      );
      expect(
        sessionShortcutFor(LogicalKeyboardKey.keyC, otherModifier: true),
        isNull,
      );
      expect(sessionShortcutFor(LogicalKeyboardKey.keyH), isNull);
    });
  });

  group('sessionPhaseCopy', () {
    test('fallo: «Era X, respondiste Y»', () {
      final copy = sessionPhaseCopy(
        const SessionPhaseContext(
          phase: SessionPhase.result,
          isCorrect: false,
          correctLabels: ['Re'],
          answerLabels: ['Mi'],
        ),
      );
      expect(copy.overline, 'Incorrecto');
      expect(copy.headline, 'Era Re, respondiste Mi');
      expect(copy.subtitle, 'La tecla correcta queda marcada en verde.');
    });

    test('acierto con meta cumplida', () {
      final copy = sessionPhaseCopy(
        const SessionPhaseContext(
          phase: SessionPhase.result,
          isCorrect: true,
          goalReached: true,
          targetRounds: 12,
        ),
      );
      expect(copy.headline, 'Bien identificada');
      expect(
        copy.subtitle,
        'Objetivo cumplido: 12 rondas. Preparando tu resumen…',
      );
    });

    test('«Preparado»: rondas, notas y foco reales', () {
      final copy = sessionPhaseCopy(
        const SessionPhaseContext(
          phase: SessionPhase.idle,
          targetRounds: 12,
          focusLabels: ['C#', 'F#', 'A#'],
        ),
      );
      expect(copy.overline, 'Preparado');
      expect(copy.headline, 'Ponte los auriculares');
      expect(copy.subtitle, '12 rondas · 1 nota · foco en C#, F#, A#');

      final unlimited = sessionPhaseCopy(
        const SessionPhaseContext(
          phase: SessionPhase.idle,
          requiredNotes: 2,
        ),
      );
      expect(unlimited.subtitle, 'Sin límite de rondas · 2 notas');
    });

    test('«¡N seguidas!» desde 3 aciertos seguidos', () {
      String headline(int streak) => sessionPhaseCopy(
            SessionPhaseContext(
              phase: SessionPhase.result,
              isCorrect: true,
              streak: streak,
            ),
          ).headline;
      expect(headline(1), 'Bien identificada');
      expect(headline(2), 'Bien identificada');
      expect(headline(3), '¡3 seguidas!');
      expect(headline(7), '¡7 seguidas!');
      // Un fallo nunca dice «seguidas».
      final wrong = sessionPhaseCopy(
        const SessionPhaseContext(
          phase: SessionPhase.result,
          isCorrect: false,
          streak: 5,
          correctLabels: ['C'],
          answerLabels: ['D'],
        ),
      );
      expect(wrong.headline, 'Era C, respondiste D');
    });

    test('listen usa solo el detalle real', () {
      final copy = sessionPhaseCopy(
        const SessionPhaseContext(
          phase: SessionPhase.listen,
          listenDetail: '1 nota',
        ),
      );
      expect(copy.subtitle, '1 nota');
      expect(copy.announcement, 'Escuchando. Escucha con atención. 1 nota');
    });

    test('answer con varias notas', () {
      final copy = sessionPhaseCopy(
        const SessionPhaseContext(phase: SessionPhase.answer, requiredNotes: 2),
      );
      expect(copy.headline, '¿Qué notas escuchaste?');
    });
  });

  group('buildSessionFocusEntries', () {
    NoteProgressSummary summary(
      String note, {
      bool learning = true,
      int seen = 0,
      int correct = 0,
      int interval = 0,
    }) {
      return NoteProgressSummary(
        note: note,
        isLearning: learning,
        consecutiveCorrect: 0,
        timesSeen: seen,
        timesCorrect: correct,
        weight: 1,
        isOverdue: false,
        intervalIndex: interval,
      );
    }

    test('deriva Crítica / En curso / Consolidando / Sin datos', () {
      final entries = buildSessionFocusEntries(
        notes: ['C', 'D', 'E', 'F', 'G'],
        summaries: [
          summary('C', seen: 10, correct: 3),
          summary('D', seen: 10, correct: 7),
          summary('E', learning: false, seen: 10, correct: 9, interval: 2),
          summary('F'),
          summary('G', seen: 10, correct: 9),
        ],
        criticalNotes: {'G'},
      );
      expect(entries.map((e) => e.status).toList(), [
        SessionFocusStatus.critical,
        SessionFocusStatus.inProgress,
        SessionFocusStatus.consolidating,
        SessionFocusStatus.noData,
        SessionFocusStatus.critical,
      ]);
      expect(entries[3].accuracyPercent, isNull);
      expect(entries[2].srsLevel, 4);
    });
  });

  group('SessionStats', () {
    test('textos de chips', () {
      const stats = SessionStats(
        round: 3,
        targetRounds: 12,
        accuracyPercent: 78.4,
        streak: 2,
      );
      expect(stats.roundText, '3 / 12');
      expect(stats.accuracyText, '78%');
      expect(stats.progress, closeTo(0.25, 1e-9));
      const empty = SessionStats(
        round: 1,
        targetRounds: 0,
        accuracyPercent: null,
        streak: 0,
      );
      expect(empty.roundText, 'Ronda 1');
      expect(empty.accuracyText, '—');
      expect(empty.progress, isNull);
    });
  });
}
