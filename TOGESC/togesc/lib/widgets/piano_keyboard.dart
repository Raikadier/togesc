import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
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

  /// Teclas mas amplias (accesibilidad).
  final bool large;

  /// Oculta nombres en las teclas.
  final bool hideLabels;

  const PianoKeyboard({
    super.key,
    this.selectedNotes = const {},
    this.correctNotes = const {},
    this.incorrectNotes = const {},
    this.onNoteTapped,
    this.disabled = false,
    this.noteNamingMode = NoteNamingMode.letter,
    this.large = false,
    this.hideLabels = false,
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
    if (correctNotes.contains(note)) {
      return DesignTokens.correct.withValues(alpha: 0.25);
    }
    if (incorrectNotes.contains(note)) {
      return DesignTokens.incorrect.withValues(alpha: 0.25);
    }
    if (selectedNotes.contains(note)) {
      return DesignTokens.selection.withValues(alpha: 0.35);
    }
    return DesignTokens.pianoWhite;
  }

  Color _getBlackKeyColor(String note) {
    if (correctNotes.contains(note)) return DesignTokens.correct;
    if (incorrectNotes.contains(note)) return DesignTokens.incorrect;
    if (selectedNotes.contains(note)) return const Color(0xFF8A6A00);
    return DesignTokens.pianoBlack;
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

  Color _whiteKeyBorder(String note) {
    if (selectedNotes.contains(note)) return DesignTokens.selection;
    if (correctNotes.contains(note)) return DesignTokens.correct;
    if (incorrectNotes.contains(note)) return DesignTokens.incorrect;
    return DesignTokens.outlineVariant;
  }

  double _whiteKeyBorderWidth(String note) {
    if (selectedNotes.contains(note)) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = large ? 640.0 : 500.0;
        final minWidth = large ? 320.0 : 280.0;
        final totalWidth = constraints.maxWidth.clamp(minWidth, maxWidth);
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
                          border: Border.all(
                            color: _whiteKeyBorder(note),
                            width: _whiteKeyBorderWidth(note),
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 8),
                        child: hideLabels
                            ? const SizedBox.shrink()
                            : Text(
                                formatNoteLabel(note, noteNamingMode),
                                style: TextStyle(
                                  fontSize: large ? 16 : 14,
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
                        border: Border.all(
                          color: selectedNotes.contains(sharpNote)
                              ? DesignTokens.selection
                              : Colors.transparent,
                          width: selectedNotes.contains(sharpNote) ? 2 : 0,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.only(bottom: 4),
                      child: hideLabels
                          ? const SizedBox.shrink()
                          : Text(
                              formatNoteLabel(sharpNote, noteNamingMode),
                              style: TextStyle(
                                fontSize: large ? 12 : 10,
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
