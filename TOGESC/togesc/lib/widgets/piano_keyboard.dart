import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../constants/note_naming.dart';

/// Teclado de piano interactivo (Stitch skeuominimalist).
class PianoKeyboard extends StatefulWidget {
  final Set<String> selectedNotes;
  final Set<String> correctNotes;
  final Set<String> incorrectNotes;
  final ValueChanged<String>? onNoteTapped;
  final bool disabled;
  final NoteNamingMode noteNamingMode;
  final bool large;
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

  @override
  State<PianoKeyboard> createState() => _PianoKeyboardState();
}

class _PianoKeyboardState extends State<PianoKeyboard> {
  final Set<String> _pressed = {};

  LinearGradient _whiteGradient(String note, bool pressed) {
    if (widget.correctNotes.contains(note)) {
      return LinearGradient(
        colors: [
          DesignTokens.correct.withValues(alpha: 0.3),
          DesignTokens.correct.withValues(alpha: 0.2),
        ],
      );
    }
    if (widget.incorrectNotes.contains(note)) {
      return LinearGradient(
        colors: [
          DesignTokens.incorrect.withValues(alpha: 0.3),
          DesignTokens.incorrect.withValues(alpha: 0.2),
        ],
      );
    }
    if (widget.selectedNotes.contains(note)) {
      return LinearGradient(
        colors: [
          DesignTokens.selection.withValues(alpha: 0.4),
          DesignTokens.selection.withValues(alpha: 0.25),
        ],
      );
    }
    if (pressed) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF3ECF1), Color(0xFFEEEEEE)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white, Color(0xFFFCFCFC), Color(0xFFF0F0F0)],
      stops: [0, 0.9, 1],
    );
  }

  LinearGradient _blackGradient(String note, bool pressed) {
    if (widget.correctNotes.contains(note)) {
      return const LinearGradient(
        colors: [DesignTokens.correct, Color(0xFF1B5E20)],
      );
    }
    if (widget.incorrectNotes.contains(note)) {
      return const LinearGradient(
        colors: [DesignTokens.incorrect, Color(0xFF8B0000)],
      );
    }
    if (widget.selectedNotes.contains(note)) {
      return const LinearGradient(
        colors: [Color(0xFF8A6A00), Color(0xFF5D4800)],
      );
    }
    if (pressed) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF4D4351), Color(0xFF333333)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF333333), Color(0xFF212121), Colors.black],
      stops: [0, 0.8, 1],
    );
  }

  Color _whiteKeyBorder(String note, ColorScheme scheme) {
    if (widget.selectedNotes.contains(note)) return DesignTokens.selection;
    if (widget.correctNotes.contains(note)) return DesignTokens.correct;
    if (widget.incorrectNotes.contains(note)) return DesignTokens.incorrect;
    return scheme.outlineVariant;
  }

  double _whiteKeyBorderWidth(String note) =>
      widget.selectedNotes.contains(note) ? 2 : 1;

  void _tap(String note) {
    if (widget.disabled) return;
    setState(() => _pressed.add(note));
    widget.onNoteTapped?.call(note);
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (mounted) setState(() => _pressed.remove(note));
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = widget.large ? 640.0 : 500.0;
        final minWidth = widget.large ? 320.0 : 280.0;
        final totalWidth = constraints.maxWidth.clamp(minWidth, maxWidth);
        final whiteKeyWidth = totalWidth / 7;
        final whiteKeyHeight = whiteKeyWidth * 3.5;
        final blackKeyWidth = whiteKeyWidth * 0.6;
        final blackKeyHeight = whiteKeyHeight * 0.62;

        return Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: DesignTokens.borderRadiusXl,
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            width: totalWidth,
            height: whiteKeyHeight,
            child: Stack(
              children: [
                Row(
                  children: PianoKeyboard.whiteNotes.map((note) {
                    final pressed = _pressed.contains(note);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _tap(note),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 50),
                          transform: pressed
                              ? (Matrix4.identity()..translateByDouble(0.0, 2.0, 0.0, 1.0))
                              : Matrix4.identity(),
                          margin: const EdgeInsets.symmetric(horizontal: 0.5),
                          decoration: BoxDecoration(
                            gradient: _whiteGradient(note, pressed),
                            border: Border.all(
                              color: _whiteKeyBorder(note, scheme),
                              width: _whiteKeyBorderWidth(note),
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(
                                note == 'C' ? 12 : 4,
                              ),
                              bottomRight: Radius.circular(
                                note == 'B' ? 12 : 4,
                              ),
                            ),
                            boxShadow: pressed
                                ? null
                                : [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          alignment: Alignment.bottomCenter,
                          padding: const EdgeInsets.only(bottom: 8),
                          child: widget.hideLabels
                              ? const SizedBox.shrink()
                              : Text(
                                  formatNoteLabel(note, widget.noteNamingMode),
                                  style: TextStyle(
                                    fontSize: widget.large ? 16 : 14,
                                    fontWeight: FontWeight.bold,
                                    color: scheme.outline,
                                  ),
                                ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                ...PianoKeyboard.blackNoteMap.entries.map((entry) {
                  final whiteIndex =
                      PianoKeyboard.whiteNotes.indexOf(entry.key);
                  final sharpNote = entry.value;
                  final pressed = _pressed.contains(sharpNote);
                  final leftOffset =
                      (whiteIndex + 1) * whiteKeyWidth - blackKeyWidth / 2;

                  return Positioned(
                    left: leftOffset,
                    top: 0,
                    width: blackKeyWidth,
                    height: blackKeyHeight,
                    child: GestureDetector(
                      onTap: () => _tap(sharpNote),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 50),
                        transform: pressed
                            ? (Matrix4.identity()..translateByDouble(0.0, 3.0, 0.0, 1.0))
                            : Matrix4.identity(),
                        decoration: BoxDecoration(
                          gradient: _blackGradient(sharpNote, pressed),
                          border: Border.all(
                            color: widget.selectedNotes.contains(sharpNote)
                                ? DesignTokens.selection
                                : Colors.transparent,
                            width: widget.selectedNotes.contains(sharpNote)
                                ? 2
                                : 0,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 4),
                        child: widget.hideLabels
                            ? const SizedBox.shrink()
                            : Text(
                                formatNoteLabel(
                                  sharpNote,
                                  widget.noteNamingMode,
                                ),
                                style: TextStyle(
                                  fontSize: widget.large ? 12 : 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
