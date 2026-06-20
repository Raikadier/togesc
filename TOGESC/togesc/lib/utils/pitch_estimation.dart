import 'dart:math';
import 'dart:typed_data';

/// Estima la frecuencia fundamental de una muestra de audio (autocorrelacion).
double? estimatePitchFrequency(
  Float32List samples, {
  required double sampleRate,
  double minHz = 80,
  double maxHz = 1200,
  double minPeak = 0.02,
}) {
  if (samples.length < 64) return null;

  var peak = 0.0;
  for (var i = 0; i < samples.length; i++) {
    final abs = samples[i].abs();
    if (abs > peak) peak = abs;
  }
  if (peak < minPeak) return null;

  var bestLag = 0;
  var bestCorr = 0.0;
  final minLag = max(2, (sampleRate / maxHz).floor());
  final maxLag = min(samples.length ~/ 2, (sampleRate / minHz).ceil());

  if (minLag >= maxLag) return null;

  for (var lag = minLag; lag < maxLag; lag++) {
    var corr = 0.0;
    final limit = samples.length - lag;
    for (var i = 0; i < limit; i++) {
      corr += samples[i] * samples[i + lag];
    }
    if (corr > bestCorr) {
      bestCorr = corr;
      bestLag = lag;
    }
  }

  if (bestLag <= 0) return null;
  final frequency = sampleRate / bestLag;
  if (frequency < minHz || frequency > maxHz) return null;
  return frequency;
}

/// Convierte bytes PCM16 mono a muestras normalizadas [-1, 1].
Float32List pcm16BytesToFloat32(Uint8List bytes) {
  final aligned = bytes.buffer.asByteData(
    bytes.offsetInBytes,
    bytes.lengthInBytes,
  );
  final sampleCount = bytes.lengthInBytes ~/ 2;
  final output = Float32List(sampleCount);
  for (var i = 0; i < sampleCount; i++) {
    output[i] = aligned.getInt16(i * 2, Endian.little) / 32768.0;
  }
  return output;
}

/// Genera una onda sinusoidal para tests.
Float32List generateSineWave({
  required double frequency,
  required double sampleRate,
  required int sampleCount,
}) {
  final output = Float32List(sampleCount);
  for (var i = 0; i < sampleCount; i++) {
    output[i] = sin(2 * pi * frequency * i / sampleRate);
  }
  return output;
}
