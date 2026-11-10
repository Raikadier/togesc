import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/constants/srs_constants.dart';
import 'package:togesc/models/note_progress_summary.dart';
import 'package:togesc/widgets/progress_v2/progress_metrics.dart';

NoteProgressSummary _s(String note, int seen, int correct) =>
    NoteProgressSummary(
      note: note,
      isLearning: true,
      consecutiveCorrect: 0,
      timesSeen: seen,
      timesCorrect: correct,
      weight: 1,
      isOverdue: false,
    );

void main() {
  group('masteryStatusOf', () {
    MasteryStatus of(int seen, double pct) =>
        masteryStatusOf(timesSeen: seen, pct: pct);

    test('sin intentos no hay datos', () {
      expect(of(0, 0), MasteryStatus.unseen);
      expect(of(0, 100), MasteryStatus.unseen);
    });

    test('con menos de $masteryMinAttempts intentos solo se mide', () {
      expect(of(1, 0), MasteryStatus.measuring);
      expect(of(1, 100), MasteryStatus.measuring);
      expect(of(masteryMinAttempts - 1, 0), MasteryStatus.measuring);
    });

    test('desde $masteryMinAttempts intentos se juzga por la precisión', () {
      expect(of(masteryMinAttempts, 0), MasteryStatus.critical);
      expect(of(masteryMinAttempts, 49.9), MasteryStatus.critical);
      expect(of(masteryMinAttempts, 50), MasteryStatus.inProgress);
      expect(of(masteryMinAttempts, 74.9), MasteryStatus.inProgress);
      expect(of(masteryMinAttempts, 75), MasteryStatus.mastered);
      expect(of(100, 100), MasteryStatus.mastered);
      expect(of(10, double.nan), MasteryStatus.critical);
    });

    test('solo los estados juzgados muestran color y porcentaje', () {
      expect(MasteryStatus.unseen.isJudged, isFalse);
      expect(MasteryStatus.measuring.isJudged, isFalse);
      expect(MasteryStatus.critical.isJudged, isTrue);
      expect(MasteryStatus.inProgress.isJudged, isTrue);
      expect(MasteryStatus.mastered.isJudged, isTrue);
    });

    test('títulos para el usuario: ya no existe «Crítica»', () {
      expect(MasteryStatus.critical.title, 'A reforzar');
      expect(MasteryStatus.measuring.title, 'Midiendo');
      expect(MasteryStatus.mastered.title, 'Consolidada');
    });
  });

  group('masterySubtitle', () {
    test('usuario nuevo', () {
      expect(
        masterySubtitle([for (var i = 0; i < 12; i++) _s('N$i', 0, 0)]),
        '0 consolidadas · 12 sin datos',
      );
    });

    test('tras una sesión con un intento por nota nadie queda en rojo', () {
      expect(
        masterySubtitle([for (var i = 0; i < 12; i++) _s('N$i', 1, 0)]),
        '0 consolidadas · 12 midiendo',
      );
    });

    test('cuenta cada estado y concuerda el singular', () {
      expect(
        masterySubtitle([
          _s('C', 10, 9),
          _s('D', 10, 6),
          _s('E', 10, 6),
          _s('F', 10, 2),
          _s('G', 2, 0),
          _s('A', 0, 0),
        ]),
        '1 consolidada · 2 en curso · 1 a reforzar · 1 midiendo · '
        '1 sin datos',
      );
    });

    test('measuringProgressLabel', () {
      expect(measuringProgressLabel(2), '2 de $masteryMinAttempts');
    });
  });
}
