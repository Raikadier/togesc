import 'dart:math';

import '../constants/notes.dart';

/// Convierte una frecuencia detectada a la nota cromatica mas cercana.
String? frequencyToNote(double frequency, {double toleranceCents = 55}) {
  if (frequency <= 0 || !frequency.isFinite) return null;

  String? bestNote;
  var bestCents = double.infinity;

  for (var octave = 2; octave <= 6; octave++) {
    for (final entry in notes.entries) {
      final reference = entry.value * pow(2, octave - 4);
      final ratio = frequency / reference;
      if (ratio <= 0) continue;
      final cents = (log(ratio) / ln2 * 1200).abs();
      if (cents < bestCents) {
        bestCents = cents;
        bestNote = entry.key;
      }
    }
  }

  return bestCents <= toleranceCents ? bestNote : null;
}
