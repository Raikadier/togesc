import 'package:flutter/material.dart';

import '../constants/note_naming.dart';

/// Teclado de piano interactivo con 7 teclas blancas y 5 negras.
///
/// Permite seleccionar/deseleccionar notas con tap.
/// Soporta colores de highlight para feedback visual.
class PianoKeyboard extends StatelessWidget {
  /// Notas actualmente seleccionadas por el usuario.
  final Set<String> selectedNotes;

  /// Notas correctas (para highlight verde despues de responder).
  final Set<String> correctNotes;

  /// Notas incorrectas (para highlight rojo despues de responder).
  final Set<String> incorrectNotes;

  /// Callback cuando el usuario toca una nota.
  final ValueChanged<String>? onNoteTapped;

  /// Si el teclado esta deshabilitado (no acepta taps).
  final bool disabled;

  /// Etiquetas en letras o solfeo (Do/Re/Mi).
  final NoteNamingMode noteNamingMode;

  const PianoKeyboard({
    super.key,
    this.selectedNotes = const {},
    this.correctNotes = const {},
    this.incorrectNotes = const {},
    this.onNoteTapped,
    this.disabled = false,
    this.noteNamingMode = NoteNamingMode.letter,
  });

  static const whiteNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  static const blackNoteMap = {
    'C': 'C#',
    'D': 'D#',
    'F': 'F#',
    'G': 'G#',
    'A': 'A#',
  };

  Color _getWhiteKeyColor(String note) {
    if (correctNotes.contains(note)) return Colors.green.shade200;
    if (incorrectNotes.contains(note)) return Colors.red.shade200;
    if (selectedNotes.contains(note)) return Colors.amber.shade200;
    return Colors.white;
  }

  Color _getBlackKeyColor(String note) {
    if (correctNotes.contains(note)) return Colors.green.shade700;
    if (incorrectNotes.contains(note)) return Colors.red.shade700;
    if (selectedNotes.contains(note)) return Colors.amber.shade700;
    return Colors.black87;
  }

  Color _getWhiteKeyTextColor(String note) {
    if (correctNotes.contains(note) ||
        incorrectNotes.contains(note) ||
        selectedNotes.contains(note)) {
      return Colors.black;
    }
    return Colors.black87;
  }

  Color _getBlackKeyTextColor(String note) {
    if (correctNotes.contains(note) ||
        incorrectNotes.contains(note) ||
        selectedNotes.contains(note)) {
      return Colors.black;
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth.clamp(280.0, 500.0);
        final whiteKeyWidth = totalWidth / 7;
        final whiteKeyHeight = whiteKeyWidth * 3.5;
        final blackKeyWidth = whiteKeyWidth * 0.6;
        final blackKeyHeight = whiteKeyHeight * 0.6;

        return SizedBox(
          width: totalWidth,
          height: whiteKeyHeight,
          child: Stack(
            children: [
              // Teclas blancas
              Row(
                children: whiteNotes.map((note) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: disabled ? null : () => onNoteTapped?.call(note),
                      child: Container(
                        height: whiteKeyHeight,
                        decoration: BoxDecoration(
                          color: _getWhiteKeyColor(note),
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          formatNoteLabel(note, noteNamingMode),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getWhiteKeyTextColor(note),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              // Teclas negras
              ...blackNoteMap.entries.map((entry) {
                final whiteIndex = whiteNotes.indexOf(entry.key);
                final sharpNote = entry.value;
                final leftOffset = (whiteIndex + 1) * whiteKeyWidth - blackKeyWidth / 2;

                return Positioned(
                  left: leftOffset,
                  top: 0,
                  width: blackKeyWidth,
                  height: blackKeyHeight,
                  child: GestureDetector(
                    onTap: disabled ? null : () => onNoteTapped?.call(sharpNote),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getBlackKeyColor(sharpNote),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        formatNoteLabel(sharpNote, noteNamingMode),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getBlackKeyTextColor(sharpNote),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
