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

String? letterFromSolfegeToken(String token) => solfegeToLetter[token];
