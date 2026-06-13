import '../constants/notes.dart';

/// Parsea la respuesta del usuario extrayendo nombres de notas.
///
/// Acepta formatos: "C E G", "C, E, G", "C-E-G", case-insensitive.
/// Convierte bemoles a sostenidos (Db -> C#).
List<String> parseNotes(String answer) {
  if (answer.trim().isEmpty) return [];

  final upper = answer.toUpperCase().trim();
  final parts = upper.split(RegExp(r'[\s,\-]+')).where((s) => s.isNotEmpty);

  return parts.map((note) => enharmonics[note] ?? note).toList();
}
