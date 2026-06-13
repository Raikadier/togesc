import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/models/instrument_preset.dart';

void main() {
  group('InstrumentPreset', () {
    test('contiene exactamente 7 presets', () {
      expect(instrumentPresets.length, 7);
    });

    test('todos los presets esperados existen', () {
      final expected = ['sine', 'piano', 'violin', 'guitar', 'flute', 'trumpet', 'organ'];
      for (final name in expected) {
        expect(instrumentPresets.containsKey(name), isTrue, reason: '$name debe existir');
      }
    });

    test('todos los presets tienen armonicos no vacios', () {
      for (final entry in instrumentPresets.entries) {
        expect(
          entry.value.harmonics.isNotEmpty,
          isTrue,
          reason: '${entry.key} debe tener armonicos',
        );
      }
    });

    test('todos los armonicos tienen amplitud positiva', () {
      for (final entry in instrumentPresets.entries) {
        for (final (harmonic, amplitude) in entry.value.harmonics) {
          expect(harmonic, greaterThan(0), reason: '${entry.key}: armonico debe ser > 0');
          expect(amplitude, greaterThan(0), reason: '${entry.key}: amplitud debe ser > 0');
        }
      }
    });

    test('sine tiene solo 1 armonico fundamental', () {
      final sine = instrumentPresets['sine']!;
      expect(sine.harmonics.length, 1);
      expect(sine.harmonics[0].$1, 1);
      expect(sine.harmonics[0].$2, 1.0);
    });

    test('todos los ADSR tienen valores positivos', () {
      for (final entry in instrumentPresets.entries) {
        final p = entry.value;
        expect(p.attack, greaterThanOrEqualTo(0), reason: '${entry.key} attack');
        expect(p.decay, greaterThanOrEqualTo(0), reason: '${entry.key} decay');
        expect(p.sustainLevel, greaterThan(0), reason: '${entry.key} sustain');
        expect(p.sustainLevel, lessThanOrEqualTo(1.0), reason: '${entry.key} sustain <= 1');
        expect(p.release, greaterThanOrEqualTo(0), reason: '${entry.key} release');
      }
    });

    test('piano tiene attack muy rapido', () {
      final piano = instrumentPresets['piano']!;
      expect(piano.attack, lessThan(0.01));
    });

    test('violin tiene attack mas lento', () {
      final violin = instrumentPresets['violin']!;
      expect(violin.attack, greaterThan(0.05));
    });
  });
}
