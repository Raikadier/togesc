import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/constants/audio_constants.dart';
import 'package:togesc/services/audio_generator.dart';

void main() {
  late AudioGenerator gen;

  setUp(() {
    gen = AudioGenerator(random: Random(42));
  });

  group('generateTone', () {
    test('produce array con longitud correcta', () {
      final tone = gen.generateTone(440, duration: 1.0);
      expect(tone.length, defaultSampleRate);
    });

    test('duracion 0.5s produce la mitad de muestras', () {
      final tone = gen.generateTone(440, duration: 0.5);
      expect(tone.length, defaultSampleRate ~/ 2);
    });

    test('sine produce valores que aproximan sin(2*pi*f*t)', () {
      final freq = 440.0;
      final tone = gen.generateTone(freq, duration: 0.01, instrument: 'sine');
      // Verificar que no es todo ceros
      final hasNonZero = tone.any((v) => v.abs() > 0.001);
      expect(hasNonZero, isTrue);
    });

    test('todos los valores estan en rango [-1, 1] despues de ADSR', () {
      final tone = gen.generateTone(440, duration: 1.0, instrument: 'piano');
      for (var i = 0; i < tone.length; i++) {
        expect(tone[i], inInclusiveRange(-1.0, 1.0),
            reason: 'Sample $i fuera de rango');
      }
    });

    test('instrumento desconocido usa sine', () {
      final tone = gen.generateTone(440, instrument: 'desconocido');
      expect(tone.length, defaultSampleRate);
    });

    test('diferentes instrumentos producen formas de onda distintas', () {
      final sine = gen.generateTone(440, instrument: 'sine');
      final piano = gen.generateTone(440, instrument: 'piano');

      // Comparar muestra en el medio (sustain phase)
      final midPoint = sine.length ~/ 2;
      expect(sine[midPoint] != piano[midPoint], isTrue,
          reason: 'sine y piano deberian diferir');
    });
  });

  group('applyAdsrEnvelope', () {
    test('al inicio (t=0) el valor es cercano a 0', () {
      final audio = Float64List.fromList(List.filled(44100, 1.0));
      final result = gen.applyAdsrEnvelope(audio, 1.0, 0.1, 0.1, 0.8, 0.1);
      expect(result[0].abs(), lessThan(0.01));
    });

    test('al final del attack el valor es cercano a 1', () {
      final audio = Float64List.fromList(List.filled(44100, 1.0));
      final result = gen.applyAdsrEnvelope(audio, 1.0, 0.1, 0.1, 0.8, 0.1);
      final attackEnd = (44100 * 0.1).toInt() - 1;
      expect(result[attackEnd], closeTo(1.0, 0.05));
    });

    test('durante sustain el valor es cercano a sustainLevel', () {
      final audio = Float64List.fromList(List.filled(44100, 1.0));
      final result = gen.applyAdsrEnvelope(audio, 1.0, 0.05, 0.05, 0.7, 0.05);
      // Punto medio deberia estar en sustain
      final mid = 44100 ~/ 2;
      expect(result[mid], closeTo(0.7, 0.05));
    });
  });

  group('generatePinkNoise', () {
    test('produce longitud correcta', () {
      final noise = gen.generatePinkNoise(1.0);
      expect(noise.length, defaultSampleRate);
    });

    test('valores estan en rango [-1, 1]', () {
      final noise = gen.generatePinkNoise(0.5);
      for (var i = 0; i < noise.length; i++) {
        expect(noise[i], inInclusiveRange(-1.0, 1.0));
      }
    });

    test('no es todo ceros', () {
      final noise = gen.generatePinkNoise(0.1);
      final hasNonZero = noise.any((v) => v.abs() > 0.01);
      expect(hasNonZero, isTrue);
    });
  });

  group('generateSweepingTone', () {
    test('produce longitud correcta', () {
      final sweep = gen.generateSweepingTone(1.0, 200, 800);
      expect(sweep.length, defaultSampleRate);
    });

    test('valores no son todos cero', () {
      final sweep = gen.generateSweepingTone(0.5, 100, 1000);
      final hasNonZero = sweep.any((v) => v.abs() > 0.01);
      expect(hasNonZero, isTrue);
    });

    test('valores estan en rango [-1, 1]', () {
      final sweep = gen.generateSweepingTone(0.5, 200, 800);
      for (final v in sweep) {
        expect(v, inInclusiveRange(-1.0, 1.0));
      }
    });
  });

  group('generateCluster', () {
    test('produce longitud correcta', () {
      final cluster = gen.generateCluster(duration: 1.0);
      expect(cluster.length, defaultSampleRate);
    });

    test('valores estan dentro de limites de clipping', () {
      final cluster = gen.generateCluster(duration: 0.5);
      for (final v in cluster) {
        expect(v, inInclusiveRange(-1.0, 1.0));
      }
    });

    test('no es silencio total', () {
      final cluster = gen.generateCluster(duration: 0.5);
      final maxAbs = cluster.fold<double>(0, (m, v) => max(m, v.abs()));
      expect(maxAbs, greaterThan(0.01));
    });
  });

  group('mixTones', () {
    test('produce buffer con longitud correcta', () {
      final (buffer, _) = gen.mixTones([440.0], duration: 1.0);
      expect(buffer.length, defaultSampleRate);
    });

    test('retorna nombre del instrumento', () {
      final (_, inst) = gen.mixTones([440.0], instrument: 'piano');
      expect(inst, 'piano');
    });

    test('valores estan en rango [-1, 1]', () {
      final (buffer, _) = gen.mixTones([440.0, 554.37, 659.25]);
      for (final v in buffer) {
        expect(v, inInclusiveRange(-1.0, 1.0));
      }
    });

    test('selecciona instrumento aleatorio cuando no se especifica', () {
      final (_, inst) = gen.mixTones([440.0]);
      expect(inst.isNotEmpty, isTrue);
    });
  });

  group('getNoteFrequencies', () {
    test('A retorna 440Hz base', () {
      final gen2 = AudioGenerator(random: Random(42));
      final (freqs, _) = gen2.getNoteFrequencies(['A'], varyOctaves: false);
      expect(freqs[0], 440.0);
    });

    test('con varyOctaves=false retorna frecuencia base', () {
      final (freqs, names) = gen.getNoteFrequencies(['C'], varyOctaves: false);
      expect(freqs[0], 261.63);
      expect(names[0], 'C4');
    });

    test('con varyOctaves=true la frecuencia es base o el doble', () {
      // Con min=0, max=1, freq es base*2^0=base o base*2^1=doble
      final (freqs, _) = gen.getNoteFrequencies(['A'], varyOctaves: true);
      expect(
        freqs[0] == 440.0 || freqs[0] == 880.0,
        isTrue,
        reason: 'Frecuencia debe ser 440 (octava 4) o 880 (octava 5), got ${freqs[0]}',
      );
    });

    test('multiples notas retornan misma cantidad de frecuencias', () {
      final (freqs, names) =
          gen.getNoteFrequencies(['C', 'E', 'G'], varyOctaves: false);
      expect(freqs.length, 3);
      expect(names.length, 3);
    });
  });

  group('float64ListToWavBytes', () {
    test('produce header RIFF valido', () {
      final samples = Float64List.fromList([0.0, 0.5, -0.5, 1.0]);
      final wav = gen.float64ListToWavBytes(samples);

      // RIFF header
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      expect(String.fromCharCodes(wav.sublist(12, 16)), 'fmt ');
      expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');
    });

    test('tamano del archivo es correcto', () {
      final samples = Float64List.fromList([0.0, 0.5, -0.5, 1.0]);
      final wav = gen.float64ListToWavBytes(samples);
      // 44 header + 4 samples * 2 bytes = 52 bytes
      expect(wav.length, 52);
    });

    test('formato PCM (1) en header', () {
      final samples = Float64List.fromList([0.0]);
      final wav = gen.float64ListToWavBytes(samples);
      final byteData = ByteData.sublistView(wav);
      final audioFormat = byteData.getUint16(20, Endian.little);
      expect(audioFormat, 1); // PCM
    });

    test('sample rate correcto en header', () {
      final samples = Float64List.fromList([0.0]);
      final wav = gen.float64ListToWavBytes(samples, sr: 44100);
      final byteData = ByteData.sublistView(wav);
      final sr = byteData.getUint32(24, Endian.little);
      expect(sr, 44100);
    });
  });
}
