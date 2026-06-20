import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/utils/frequency_to_note.dart';
import 'package:togesc/utils/pitch_estimation.dart';

void main() {
  test('estimatePitchFrequency detecta tono sinusoidal A4', () {
    const sampleRate = 44100.0;
    final samples = generateSineWave(
      frequency: 440,
      sampleRate: sampleRate,
      sampleCount: 8192,
    );

    final frequency = estimatePitchFrequency(
      samples,
      sampleRate: sampleRate,
    );

    expect(frequency, isNotNull);
    expect(frequencyToNote(frequency!), 'A');
  });
}
