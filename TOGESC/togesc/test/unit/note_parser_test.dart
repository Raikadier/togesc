import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/services/note_parser.dart';

void main() {
  group('parseNotes', () {
    test('parsea notas separadas por espacios', () {
      expect(parseNotes('C E G'), ['C', 'E', 'G']);
    });

    test('parsea notas separadas por comas', () {
      expect(parseNotes('C, E, G'), ['C', 'E', 'G']);
    });

    test('parsea notas separadas por guiones', () {
      expect(parseNotes('C-E-G'), ['C', 'E', 'G']);
    });

    test('acepta minusculas y convierte a mayusculas', () {
      expect(parseNotes('c e g'), ['C', 'E', 'G']);
    });

    test('convierte bemoles a sostenidos', () {
      expect(parseNotes('Db'), ['C#']);
      expect(parseNotes('Eb'), ['D#']);
      expect(parseNotes('Gb'), ['F#']);
      expect(parseNotes('Ab'), ['G#']);
      expect(parseNotes('Bb'), ['A#']);
    });

    test('mezcla de sostenidos y bemoles', () {
      expect(parseNotes('C# Eb G'), ['C#', 'D#', 'G']);
    });

    test('cadena vacia retorna lista vacia', () {
      expect(parseNotes(''), isEmpty);
    });

    test('solo espacios retorna lista vacia', () {
      expect(parseNotes('   '), isEmpty);
    });

    test('una sola nota', () {
      expect(parseNotes('A'), ['A']);
    });

    test('multiples espacios entre notas', () {
      expect(parseNotes('C   E   G'), ['C', 'E', 'G']);
    });

    test('mezcla de separadores', () {
      expect(parseNotes('C, E - G A'), ['C', 'E', 'G', 'A']);
    });

    test('sostenido pasa sin cambio', () {
      expect(parseNotes('F#'), ['F#']);
    });

    test('nota desconocida pasa sin cambio', () {
      expect(parseNotes('X'), ['X']);
    });

    test('parsea solfeo basico', () {
      expect(parseNotes('Do Re Mi'), ['C', 'D', 'E']);
      expect(parseNotes('do sol si'), ['C', 'G', 'B']);
    });

    test('parsea solfeo con sostenidos', () {
      expect(parseNotes('Fa# La#'), ['F#', 'A#']);
    });
  });
}
