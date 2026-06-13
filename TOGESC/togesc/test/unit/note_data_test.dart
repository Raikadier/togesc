import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/models/note_data.dart';
import 'package:togesc/constants/srs_constants.dart';

void main() {
  group('NoteData', () {
    test('constructor por defecto tiene valores correctos', () {
      final data = NoteData();
      expect(data.weight, defaultNoteWeight);
      expect(data.easeFactor, initialEaseFactor);
      expect(data.consecutiveCorrect, 0);
      expect(data.timesSeen, 0);
      expect(data.timesCorrect, 0);
      expect(data.intervalIndex, 0);
      expect(data.lastSeen, isNull);
      expect(data.nextReview, isNull);
      expect(data.isLearning, isTrue);
    });

    test('toJson produce map con claves correctas', () {
      final data = NoteData(
        weight: 5.0,
        easeFactor: 2.0,
        consecutiveCorrect: 3,
        timesSeen: 10,
        timesCorrect: 7,
        intervalIndex: 2,
        lastSeen: '2026-03-01T10:00:00',
        nextReview: '2026-03-08T10:00:00',
        isLearning: false,
      );

      final json = data.toJson();
      expect(json['weight'], 5.0);
      expect(json['ease_factor'], 2.0);
      expect(json['consecutive_correct'], 3);
      expect(json['times_seen'], 10);
      expect(json['times_correct'], 7);
      expect(json['interval_index'], 2);
      expect(json['last_seen'], '2026-03-01T10:00:00');
      expect(json['next_review'], '2026-03-08T10:00:00');
      expect(json['is_learning'], isFalse);
    });

    test('fromJson roundtrip preserva todos los campos', () {
      final original = NoteData(
        weight: 7.5,
        easeFactor: 1.8,
        consecutiveCorrect: 4,
        timesSeen: 15,
        timesCorrect: 12,
        intervalIndex: 3,
        lastSeen: '2026-03-06T14:00:00',
        nextReview: '2026-03-20T14:00:00',
        isLearning: false,
      );

      final restored = NoteData.fromJson(original.toJson());
      expect(restored.weight, original.weight);
      expect(restored.easeFactor, original.easeFactor);
      expect(restored.consecutiveCorrect, original.consecutiveCorrect);
      expect(restored.timesSeen, original.timesSeen);
      expect(restored.timesCorrect, original.timesCorrect);
      expect(restored.intervalIndex, original.intervalIndex);
      expect(restored.lastSeen, original.lastSeen);
      expect(restored.nextReview, original.nextReview);
      expect(restored.isLearning, original.isLearning);
    });

    test('fromJson con campos faltantes usa defaults', () {
      final data = NoteData.fromJson({});
      expect(data.weight, defaultNoteWeight);
      expect(data.easeFactor, initialEaseFactor);
      expect(data.consecutiveCorrect, 0);
      expect(data.timesSeen, 0);
      expect(data.timesCorrect, 0);
      expect(data.intervalIndex, 0);
      expect(data.lastSeen, isNull);
      expect(data.nextReview, isNull);
      expect(data.isLearning, isTrue);
    });

    test('fromJson clampea weight fuera de rango', () {
      final tooLow = NoteData.fromJson({'weight': -5.0});
      expect(tooLow.weight, minNoteWeight);

      final tooHigh = NoteData.fromJson({'weight': 100.0});
      expect(tooHigh.weight, maxNoteWeight);
    });

    test('fromJson clampea ease_factor fuera de rango', () {
      final tooLow = NoteData.fromJson({'ease_factor': 0.5});
      expect(tooLow.easeFactor, minEaseFactor);

      final tooHigh = NoteData.fromJson({'ease_factor': 5.0});
      expect(tooHigh.easeFactor, maxEaseFactor);
    });

    test('fromJson clampea intervalIndex al rango de reviewIntervals', () {
      final tooHigh = NoteData.fromJson({'interval_index': 999});
      expect(tooHigh.intervalIndex, reviewIntervals.length - 1);

      final negative = NoteData.fromJson({'interval_index': -1});
      expect(negative.intervalIndex, 0);
    });

    test('fromJson con valores null usa defaults', () {
      final data = NoteData.fromJson({
        'weight': null,
        'ease_factor': null,
        'consecutive_correct': null,
        'last_seen': null,
      });
      expect(data.weight, defaultNoteWeight);
      expect(data.easeFactor, initialEaseFactor);
      expect(data.consecutiveCorrect, 0);
      expect(data.lastSeen, isNull);
    });

    test('fromJson con tipos incorrectos usa defaults', () {
      final data = NoteData.fromJson({
        'weight': 'not_a_number',
        'ease_factor': true,
        'consecutive_correct': 'abc',
        'times_seen': [],
      });
      expect(data.weight, defaultNoteWeight);
      expect(data.easeFactor, initialEaseFactor);
      expect(data.consecutiveCorrect, 0);
      expect(data.timesSeen, 0);
    });

    test('fromJson acepta string numerico para weight', () {
      final data = NoteData.fromJson({'weight': '5.5'});
      expect(data.weight, 5.5);
    });

    test('fromJson string vacio para last_seen retorna null', () {
      final data = NoteData.fromJson({'last_seen': ''});
      expect(data.lastSeen, isNull);
    });

    test('fromJson clampea consecutive_correct negativo a 0', () {
      final data = NoteData.fromJson({'consecutive_correct': -3});
      expect(data.consecutiveCorrect, 0);
    });

    test('copyWith preserva campos no modificados', () {
      final original = NoteData(weight: 5.0, easeFactor: 2.0, isLearning: false);
      final copy = original.copyWith(weight: 8.0);
      expect(copy.weight, 8.0);
      expect(copy.easeFactor, 2.0);
      expect(copy.isLearning, isFalse);
    });
  });
}
