import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/utils/frequency_to_note.dart';

void main() {
  test('frequencyToNote reconoce A4', () {
    expect(frequencyToNote(440), 'A');
  });

  test('frequencyToNote reconoce C4 aproximado', () {
    expect(frequencyToNote(261.63), 'C');
  });

  test('frequencyToNote rechaza frecuencias fuera de rango', () {
    expect(frequencyToNote(30), isNull);
    expect(frequencyToNote(5000), isNull);
  });
}
