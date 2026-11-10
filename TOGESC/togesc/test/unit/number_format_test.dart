import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/utils/number_format.dart';

void main() {
  test('formatDecimalEs usa coma y respeta los decimales', () {
    expect(formatDecimalEs(0), '0,0');
    expect(formatDecimalEs(1), '1,0');
    expect(formatDecimalEs(33.333), '33,3');
    expect(formatDecimalEs(0.925, decimals: 2), '0,93');
    expect(formatDecimalEs(3, trimZeros: true), '3');
    expect(formatDecimalEs(1.5, decimals: 2, trimZeros: true), '1,5');
    expect(formatDecimalEs(10, decimals: 0, trimZeros: true), '10');
  });

  test('formatPercentEs quita el «,0» y separa el símbolo', () {
    expect(formatPercentEs(0), '0 %');
    expect(formatPercentEs(1), '1 %');
    expect(formatPercentEs(33.333), '33,3 %');
    expect(formatPercentEs(99.96), '100 %');
  });

  test('formatSecondsEs', () {
    expect(formatSecondsEs(0), '0,0 s');
    expect(formatSecondsEs(1), '1,0 s');
    expect(formatSecondsEs(33.333), '33,3 s');
    expect(formatSecondsEs(3, trimZeros: true), '3 s');
  });

  test('plural concuerda con 0, 1 y varios', () {
    expect(plural(0, 'ronda', 'rondas'), '0 rondas');
    expect(plural(1, 'ronda', 'rondas'), '1 ronda');
    expect(plural(2, 'ronda', 'rondas'), '2 rondas');
  });
}
