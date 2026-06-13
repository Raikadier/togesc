import 'dart:math';
import 'dart:typed_data';

import '../constants/audio_constants.dart';
import '../constants/notes.dart' as n;
import '../models/instrument_preset.dart';

/// Generador de audio para el entrenador de oido absoluto.
///
/// Genera tonos musicales usando sintesis aditiva, envelopes ADSR,
/// y sonidos de limpieza (cluster caotico) usando buffers Float64List.
class AudioGenerator {
  final int sampleRate;
  final double duration;
  final Random _random;

  AudioGenerator({
    this.sampleRate = defaultSampleRate,
    this.duration = defaultDuration,
    Random? random,
  }) : _random = random ?? Random();

  /// Genera un tono con el timbre del instrumento especificado.
  Float64List generateTone(
    double frequency, {
    double? duration,
    String instrument = 'sine',
  }) {
    final dur = duration ?? this.duration;
    final numSamples = (sampleRate * dur).toInt();
    final t = Float64List(numSamples);
    for (var i = 0; i < numSamples; i++) {
      t[i] = i / sampleRate;
    }

    final preset = instrumentPresets[instrument] ?? instrumentPresets['sine']!;

    // Sintesis aditiva
    final tone = Float64List(numSamples);
    for (final (harmonic, amplitude) in preset.harmonics) {
      final freq = frequency * harmonic;
      for (var i = 0; i < numSamples; i++) {
        tone[i] += amplitude * sin(2 * pi * freq * t[i]);
      }
    }

    // Normalizar
    var maxVal = 0.0;
    for (var i = 0; i < numSamples; i++) {
      final abs = tone[i].abs();
      if (abs > maxVal) maxVal = abs;
    }
    if (maxVal > 0) {
      for (var i = 0; i < numSamples; i++) {
        tone[i] /= maxVal;
      }
    }

    // Aplicar envelope ADSR
    return applyAdsrEnvelope(
      tone,
      dur,
      preset.attack,
      preset.decay,
      preset.sustainLevel,
      preset.release,
    );
  }

  /// Aplica un envelope ADSR al audio.
  Float64List applyAdsrEnvelope(
    Float64List audio,
    double duration,
    double attack,
    double decay,
    double sustainLevel,
    double release,
  ) {
    final totalSamples = audio.length;
    final attackSamples = (sampleRate * attack).toInt();
    final decaySamples = (sampleRate * decay).toInt();
    final releaseSamples = (sampleRate * release).toInt();
    final sustainSamples = totalSamples - attackSamples - decaySamples - releaseSamples;

    final envelope = Float64List(totalSamples);

    // Attack: 0 -> 1
    for (var i = 0; i < attackSamples && i < totalSamples; i++) {
      envelope[i] = i / attackSamples;
    }

    // Decay: 1 -> sustainLevel
    for (var i = 0; i < decaySamples && (attackSamples + i) < totalSamples; i++) {
      envelope[attackSamples + i] = 1.0 - (1.0 - sustainLevel) * (i / decaySamples);
    }

    // Sustain
    final sustainEnd = attackSamples + decaySamples + (sustainSamples > 0 ? sustainSamples : 0);
    for (var i = attackSamples + decaySamples; i < sustainEnd && i < totalSamples; i++) {
      envelope[i] = sustainLevel;
    }

    // Release: sustainLevel -> 0
    final int releaseStart = sustainEnd;
    for (var i = 0; i < releaseSamples && (releaseStart + i) < totalSamples; i++) {
      envelope[releaseStart + i] =
          sustainLevel * (1.0 - i / releaseSamples);
    }

    // Aplicar
    final result = Float64List(totalSamples);
    for (var i = 0; i < totalSamples; i++) {
      result[i] = audio[i] * envelope[i];
    }
    return result;
  }

  /// Genera ruido rosa (aproximacion Voss-McCartney).
  Float64List generatePinkNoise(double duration) {
    final numSamples = (sampleRate * duration).toInt();
    final pink = Float64List(numSamples);
    const numRows = 16;

    final cols = numSamples ~/ numRows + 1;
    final rows = List.generate(
      numRows,
      (_) => List.generate(cols, (_) => _random.nextGaussian()),
    );

    for (var i = 0; i < numSamples; i++) {
      final col = i ~/ numRows;
      var sum = 0.0;
      for (var r = 0; r < numRows; r++) {
        sum += rows[r][col];
      }
      pink[i] = sum + _random.nextGaussian();
    }

    // Normalizar a [-1, 1]
    var maxVal = 0.0;
    for (var i = 0; i < numSamples; i++) {
      final abs = pink[i].abs();
      if (abs > maxVal) maxVal = abs;
    }
    if (maxVal > 0) {
      for (var i = 0; i < numSamples; i++) {
        pink[i] /= maxVal;
      }
    }

    return pink;
  }

  /// Genera un tono con frecuencia que varia en el tiempo (sweep).
  Float64List generateSweepingTone(
    double duration,
    double fStart,
    double fEnd,
  ) {
    final numSamples = (sampleRate * duration).toInt();
    final result = Float64List(numSamples);

    // Frecuencia interpolada linealmente
    var phase = 0.0;
    for (var i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final freq = fStart + (fEnd - fStart) * t;
      phase += 2 * pi * freq / sampleRate;
      result[i] = sin(phase);
    }

    return result;
  }

  /// Genera un cluster caotico para limpieza tonal.
  Float64List generateCluster({double duration = clusterDuration}) {
    final numSamples = (sampleRate * duration).toInt();

    // 50 tonos sweeping
    final tones = <Float64List>[];
    for (var i = 0; i < clusterNumTones; i++) {
      final fStart =
          _random.nextDouble() * (clusterMaxFreq - clusterMinFreq) + clusterMinFreq;
      final fEnd =
          _random.nextDouble() * (clusterMaxFreq - clusterMinFreq) + clusterMinFreq;
      tones.add(generateSweepingTone(duration, fStart, fEnd));
    }

    // Mezclar tonos
    final mixedTones = Float64List(numSamples);
    for (final tone in tones) {
      for (var i = 0; i < numSamples; i++) {
        mixedTones[i] += tone[i];
      }
    }
    for (var i = 0; i < numSamples; i++) {
      mixedTones[i] /= tones.length;
    }

    // Ruido rosa
    final pinkNoise = generatePinkNoise(duration);

    // Combinar: 70% tonos + 30% ruido
    final cluster = Float64List(numSamples);
    for (var i = 0; i < numSamples; i++) {
      cluster[i] = mixedTones[i] * 0.7 + pinkNoise[i] * 0.3;
    }

    // Normalizar y aplicar amplitud
    var maxVal = 0.0;
    for (var i = 0; i < numSamples; i++) {
      final abs = cluster[i].abs();
      if (abs > maxVal) maxVal = abs;
    }
    if (maxVal > 0) {
      for (var i = 0; i < numSamples; i++) {
        cluster[i] = (cluster[i] / maxVal) * maxAmplitude;
      }
    }

    // Envelope tipo nube
    final attackTime = 0.1;
    final releaseTime = 0.8;
    final attackSamples = (sampleRate * attackTime).toInt();
    final releaseSamples = (sampleRate * releaseTime).toInt();
    final sustainSamples = numSamples - attackSamples - releaseSamples;

    for (var i = 0; i < attackSamples && i < numSamples; i++) {
      cluster[i] *= i / attackSamples;
    }
    // Sustain con fluctuaciones
    for (var i = attackSamples; i < attackSamples + max(0, sustainSamples) && i < numSamples; i++) {
      final t = (i - attackSamples) / sampleRate;
      cluster[i] *= 1.0 + 0.1 * sin(2 * pi * 2 * t);
    }
    // Release
    final releaseStart = numSamples - releaseSamples;
    for (var i = max(0, releaseStart); i < numSamples; i++) {
      cluster[i] *= (numSamples - i) / releaseSamples;
    }

    return cluster;
  }

  /// Mezcla multiples tonos en un solo buffer.
  (Float64List buffer, String instrument) mixTones(
    List<double> frequencies, {
    double? duration,
    String? instrument,
  }) {
    final dur = duration ?? this.duration;
    final numSamples = (sampleRate * dur).toInt();

    // Seleccionar instrumento
    final inst = instrument ??
        instrumentPresets.keys.elementAt(
          _random.nextInt(instrumentPresets.length),
        );

    // Generar cada tono
    final tones = frequencies
        .map((freq) => generateTone(freq, duration: dur, instrument: inst))
        .toList();

    // Sumar y normalizar
    final mixed = Float64List(numSamples);
    for (final tone in tones) {
      for (var i = 0; i < numSamples; i++) {
        mixed[i] += tone[i];
      }
    }
    for (var i = 0; i < numSamples; i++) {
      mixed[i] = (mixed[i] / frequencies.length) * maxAmplitude;
    }

    // Clip
    for (var i = 0; i < numSamples; i++) {
      mixed[i] = mixed[i].clamp(-1.0, 1.0);
    }

    return (mixed, inst);
  }

  /// Convierte nombres de notas a frecuencias con variacion de octavas.
  (List<double> frequencies, List<String> notesWithOctave) getNoteFrequencies(
    List<String> noteNames, {
    bool varyOctaves = true,
  }) {
    final frequencies = <double>[];
    final notesWithOctave = <String>[];

    for (final note in noteNames) {
      final baseFreq = n.notes[note]!;
      int octaveShift;
      if (varyOctaves) {
        octaveShift =
            _random.nextInt(maxOctaveShift - minOctaveShift + 1) + minOctaveShift;
      } else {
        octaveShift = 0;
      }
      final freq = baseFreq * pow(2, octaveShift);
      frequencies.add(freq);
      notesWithOctave.add('$note${4 + octaveShift}');
    }

    return (frequencies, notesWithOctave);
  }

  /// Convierte Float64List a bytes WAV (16-bit PCM).
  Uint8List float64ListToWavBytes(Float64List samples, {int? sr}) {
    final rate = sr ?? sampleRate;
    final numSamples = samples.length;
    const bitsPerSample = 16;
    const numChannels = 1;
    final byteRate = rate * numChannels * bitsPerSample ~/ 8;
    const blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = numSamples * blockAlign;
    final fileSize = 36 + dataSize;

    final buffer = ByteData(44 + dataSize);

    // RIFF header
    buffer.setUint8(0, 0x52); // R
    buffer.setUint8(1, 0x49); // I
    buffer.setUint8(2, 0x46); // F
    buffer.setUint8(3, 0x46); // F
    buffer.setUint32(4, fileSize, Endian.little);
    buffer.setUint8(8, 0x57); // W
    buffer.setUint8(9, 0x41); // A
    buffer.setUint8(10, 0x56); // V
    buffer.setUint8(11, 0x45); // E

    // fmt subchunk
    buffer.setUint8(12, 0x66); // f
    buffer.setUint8(13, 0x6D); // m
    buffer.setUint8(14, 0x74); // t
    buffer.setUint8(15, 0x20); // (space)
    buffer.setUint32(16, 16, Endian.little); // Subchunk1Size (PCM)
    buffer.setUint16(20, 1, Endian.little); // AudioFormat (PCM)
    buffer.setUint16(22, numChannels, Endian.little);
    buffer.setUint32(24, rate, Endian.little);
    buffer.setUint32(28, byteRate, Endian.little);
    buffer.setUint16(32, blockAlign, Endian.little);
    buffer.setUint16(34, bitsPerSample, Endian.little);

    // data subchunk
    buffer.setUint8(36, 0x64); // d
    buffer.setUint8(37, 0x61); // a
    buffer.setUint8(38, 0x74); // t
    buffer.setUint8(39, 0x61); // a
    buffer.setUint32(40, dataSize, Endian.little);

    // PCM data (16-bit signed)
    for (var i = 0; i < numSamples; i++) {
      final sample = (samples[i] * 32767).round().clamp(-32768, 32767);
      buffer.setInt16(44 + i * 2, sample, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }
}

/// Extension para generar numeros gaussianos desde Random.
extension GaussianRandom on Random {
  double nextGaussian() {
    // Box-Muller transform
    final u1 = nextDouble();
    final u2 = nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }
}
