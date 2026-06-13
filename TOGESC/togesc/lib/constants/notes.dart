/// Frecuencias de notas musicales y mapeo de enarmonias.
library;

/// Frecuencias de las notas en la 4ta octava (A4 = 440Hz).
const Map<String, double> notes = {
  'C': 261.63,
  'C#': 277.18,
  'D': 293.66,
  'D#': 311.13,
  'E': 329.63,
  'F': 349.23,
  'F#': 369.99,
  'G': 392.00,
  'G#': 415.30,
  'A': 440.00,
  'A#': 466.16,
  'B': 493.88,
};

/// Mapeo de notas bemoles a sus equivalentes sostenidos.
const Map<String, String> enharmonics = {
  'DB': 'C#',
  'EB': 'D#',
  'GB': 'F#',
  'AB': 'G#',
  'BB': 'A#',
};

/// Notas sostenidas (para el modo solo sostenidos).
const List<String> sharpNotes = ['C#', 'D#', 'F#', 'G#', 'A#'];
