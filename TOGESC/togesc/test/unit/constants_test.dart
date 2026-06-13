import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/constants/notes.dart';
import 'package:togesc/constants/srs_constants.dart';
import 'package:togesc/constants/audio_constants.dart';
import 'package:togesc/constants/game_constants.dart';

void main() {
  group('Notes constants', () {
    test('contiene exactamente 12 notas', () {
      expect(notes.length, 12);
    });

    test('A4 es 440Hz', () {
      expect(notes['A'], 440.0);
    });

    test('C4 es 261.63Hz', () {
      expect(notes['C'], 261.63);
    });

    test('todas las frecuencias son positivas', () {
      for (final freq in notes.values) {
        expect(freq, greaterThan(0));
      }
    });

    test('frecuencias estan en orden creciente de C a B', () {
      final ordered = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
      for (var i = 0; i < ordered.length - 1; i++) {
        expect(
          notes[ordered[i]]!,
          lessThan(notes[ordered[i + 1]]!),
          reason: '${ordered[i]} debe ser menor que ${ordered[i + 1]}',
        );
      }
    });
  });

  group('Enharmonics', () {
    test('contiene 5 mapeos', () {
      expect(enharmonics.length, 5);
    });

    test('Db mapea a C#', () {
      expect(enharmonics['DB'], 'C#');
    });

    test('Eb mapea a D#', () {
      expect(enharmonics['EB'], 'D#');
    });

    test('Gb mapea a F#', () {
      expect(enharmonics['GB'], 'F#');
    });

    test('Ab mapea a G#', () {
      expect(enharmonics['AB'], 'G#');
    });

    test('Bb mapea a A#', () {
      expect(enharmonics['BB'], 'A#');
    });

    test('todos los valores de enarmonias existen en notes', () {
      for (final sharp in enharmonics.values) {
        expect(notes.containsKey(sharp), isTrue, reason: '$sharp debe existir en notes');
      }
    });
  });

  group('Sharp notes', () {
    test('contiene 5 notas sostenidas', () {
      expect(sharpNotes.length, 5);
    });

    test('todas las sostenidas existen en notes', () {
      for (final note in sharpNotes) {
        expect(notes.containsKey(note), isTrue, reason: '$note debe existir en notes');
      }
    });

    test('todas terminan en #', () {
      for (final note in sharpNotes) {
        expect(note.endsWith('#'), isTrue);
      }
    });
  });

  group('SRS constants', () {
    test('weight bounds son consistentes', () {
      expect(minNoteWeight, lessThan(defaultNoteWeight));
      expect(defaultNoteWeight, lessThan(maxNoteWeight));
    });

    test('ease factor bounds son consistentes', () {
      expect(minEaseFactor, lessThan(initialEaseFactor));
      expect(initialEaseFactor, lessThanOrEqualTo(maxEaseFactor));
    });

    test('review intervals estan en orden creciente', () {
      for (var i = 0; i < reviewIntervals.length - 1; i++) {
        expect(reviewIntervals[i], lessThan(reviewIntervals[i + 1]));
      }
    });

    test('learning phase threshold es positivo', () {
      expect(learningPhaseThreshold, greaterThan(0));
    });
  });

  group('Audio constants', () {
    test('sample rate es 44100', () {
      expect(defaultSampleRate, 44100);
    });

    test('cluster freq range es valido', () {
      expect(clusterMinFreq, lessThan(clusterMaxFreq));
    });

    test('octave shift min <= max', () {
      expect(minOctaveShift, lessThanOrEqualTo(maxOctaveShift));
    });
  });

  group('GameMode', () {
    test('tiene 7 modos', () {
      expect(GameMode.values.length, 7);
    });

    test('fromId retorna modo correcto', () {
      expect(GameMode.fromId(1), GameMode.singleNote);
      expect(GameMode.fromId(4), GameMode.random);
      expect(GameMode.fromId(7), GameMode.speedTraining);
    });

    test('fromId retorna null para id invalido', () {
      expect(GameMode.fromId(99), isNull);
    });

    test('todos los modos tienen displayName no vacio', () {
      for (final mode in GameMode.values) {
        expect(mode.displayName.isNotEmpty, isTrue);
      }
    });
  });

  group('Speed constants', () {
    test('speed time bounds son consistentes', () {
      expect(speedMinTime, lessThan(speedInitialTime));
      expect(speedInitialTime, lessThanOrEqualTo(speedMaxTime));
    });
  });
}
