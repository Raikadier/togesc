/// Notacion de notas: letras (C/D/E) o solfeo (Do/Re/Mi).
enum NoteNamingMode {
  letter,
  solfege,
}

const Map<String, String> letterToSolfege = {
  'C': 'Do',
  'C#': 'Do#',
  'D': 'Re',
  'D#': 'Re#',
  'E': 'Mi',
  'F': 'Fa',
  'F#': 'Fa#',
  'G': 'Sol',
  'G#': 'Sol#',
  'A': 'La',
  'A#': 'La#',
  'B': 'Si',
};

/// Solfeo en mayusculas sin acentos (Do, Re#...).
const Map<String, String> solfegeToLetter = {
  'DO': 'C',
  'DO#': 'C#',
  'RE': 'D',
  'RE#': 'D#',
  'MI': 'E',
  'FA': 'F',
  'FA#': 'F#',
  'SOL': 'G',
  'SOL#': 'G#',
  'LA': 'A',
  'LA#': 'A#',
  'SI': 'B',
};

String formatNoteLabel(String letterName, NoteNamingMode mode) {
  if (mode == NoteNamingMode.letter) return letterName;
  return letterToSolfege[letterName] ?? letterName;
}

/// Nombre hablado de una nota para lectores de pantalla: «A sostenido»,
/// «La sostenido». [label] es el nombre ya formateado (letra o solfeo).
String spokenNoteName(String label) {
  if (label.endsWith('#')) {
    return '${label.substring(0, label.length - 1)} sostenido';
  }
  return label;
}

String? letterFromSolfegeToken(String token) => solfegeToLetter[token];
