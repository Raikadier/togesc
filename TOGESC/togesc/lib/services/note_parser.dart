import '../constants/note_naming.dart';
import '../constants/notes.dart';

/// Parsea la respuesta del usuario extrayendo nombres de notas.
///
/// Acepta formatos: "C E G", "Do Re Mi", "C, E, G", case-insensitive.
/// Convierte bemoles a sostenidos (Db -> C#) y solfeo a letras (Do -> C).
List<String> parseNotes(String answer) {
  if (answer.trim().isEmpty) return [];

  final upper = answer.toUpperCase().trim();
  final parts = upper.split(RegExp(r'[\s,\-]+')).where((s) => s.isNotEmpty);

  return parts.map(_normalizeToken).toList();
}

String _normalizeToken(String token) {
  final fromSolfege = letterFromSolfegeToken(token);
  if (fromSolfege != null) return fromSolfege;
  return enharmonics[token] ?? token;
}
