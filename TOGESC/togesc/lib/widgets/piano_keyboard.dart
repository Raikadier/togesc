import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/design_tokens.dart';
import '../app/togesc_colors.dart';
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

  LinearGradient _whiteGradient(
    String note,
    bool pressed,
    ColorScheme scheme,
    TogescColors colors,
  ) {
    if (widget.correctNotes.contains(note)) {
      return LinearGradient(
        colors: [
          colors.correct.withValues(alpha: 0.3),
          colors.correct.withValues(alpha: 0.2),
        ],
      );
    }
    if (widget.incorrectNotes.contains(note)) {
      return LinearGradient(
        colors: [
          colors.incorrect.withValues(alpha: 0.3),
          colors.incorrect.withValues(alpha: 0.2),
        ],
      );
    }
    if (widget.selectedNotes.contains(note)) {
      return LinearGradient(
        colors: [
          colors.selection.withValues(alpha: 0.4),
          colors.selection.withValues(alpha: 0.25),
        ],
      );
    }
    if (pressed) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [scheme.surfaceContainer, scheme.surfaceContainerHighest],
      );
    }
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        DesignTokens.pianoWhite,
        scheme.surfaceContainerLowest,
        scheme.surfaceContainerHigh,
      ],
      stops: const [0, 0.9, 1],
    );
  }

  LinearGradient _blackGradient(
    String note,
    bool pressed,
    TogescColors colors,
  ) {
    if (widget.correctNotes.contains(note)) {
      return LinearGradient(colors: [colors.correct, colors.correctDeep]);
    }
    if (widget.incorrectNotes.contains(note)) {
      return LinearGradient(colors: [colors.incorrect, colors.incorrectDeep]);
    }
    if (widget.selectedNotes.contains(note)) {
      return LinearGradient(
        colors: [
          colors.selectionDeep,
          colors.selectionDeep.withValues(alpha: 0.85),
        ],
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
      colors: [Color(0xFF333333), DesignTokens.pianoBlack, Colors.black],
      stops: [0, 0.8, 1],
    );
  }

  Color _whiteKeyBorder(String note, ColorScheme scheme, TogescColors colors) {
    if (widget.selectedNotes.contains(note)) return colors.selection;
    if (widget.correctNotes.contains(note)) return colors.correct;
    if (widget.incorrectNotes.contains(note)) return colors.incorrect;
    return scheme.outlineVariant;
  }

  double _whiteKeyBorderWidth(String note) =>
      widget.selectedNotes.contains(note) ? 2 : 1;

  String _semanticsLabel(String note) =>
      formatNoteLabel(note, widget.noteNamingMode);

  String? _semanticsHint(String note) {
    if (widget.correctNotes.contains(note)) return 'correcta';
    if (widget.incorrectNotes.contains(note)) return 'incorrecta';
    if (widget.selectedNotes.contains(note)) return 'seleccionada';
    return null;
  }

  Widget? _statusBadge(
    String note, {
    required bool onDarkKey,
    required TogescColors colors,
  }) {
    if (widget.correctNotes.contains(note)) {
      return Icon(
        Icons.check_circle,
        size: widget.large ? 18 : 14,
        color: onDarkKey ? Colors.white : colors.correct,
        semanticLabel: 'correcta',
      );
    }
    if (widget.incorrectNotes.contains(note)) {
      return Icon(
        Icons.cancel,
        size: widget.large ? 18 : 14,
        color: onDarkKey ? Colors.white : colors.incorrect,
        semanticLabel: 'incorrecta',
      );
    }
    return null;
  }

  void _tap(String note) {
    if (widget.disabled) return;
    HapticFeedback.selectionClick();
    setState(() => _pressed.add(note));
    widget.onNoteTapped?.call(note);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    Future<void>.delayed(
      reduceMotion ? Duration.zero : DesignTokens.motionKeyPress,
      () {
        if (mounted) setState(() => _pressed.remove(note));
      },
    );
  }

  KeyEventResult _handleKeyActivation(
    String note,
    FocusNode node,
    KeyEvent event,
  ) {
    if (widget.disabled) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _tap(note);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _accessibleKey({
    required String note,
    required Widget visual,
    required bool onDarkKey,
    required TogescColors colors,
  }) {
    final badge = _statusBadge(note, onDarkKey: onDarkKey, colors: colors);
    return Semantics(
      button: true,
      enabled: !widget.disabled,
      label: _semanticsLabel(note),
      hint: _semanticsHint(note),
      selected: widget.selectedNotes.contains(note),
      child: Focus(
        canRequestFocus: !widget.disabled,
        onKeyEvent: (node, event) => _handleKeyActivation(note, node, event),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.disabled ? null : () => _tap(note),
            focusColor: colors.selection.withValues(alpha: 0.2),
            hoverColor: colors.selection.withValues(alpha: 0.1),
            splashColor: colors.selection.withValues(alpha: 0.15),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                visual,
                if (badge != null)
                  Padding(padding: const EdgeInsets.only(top: 4), child: badge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = TogescColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final animDuration = reduceMotion
        ? Duration.zero
        : DesignTokens.motionFast;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = widget.large ? 640.0 : 500.0;
        // 7 teclas x 48dp minimo (WCAG 2.5.8).
        const minWidth = 336.0;
        final totalWidth = constraints.maxWidth.clamp(minWidth, maxWidth);
        final whiteKeyWidth = totalWidth / 7;
        final whiteKeyHeight = whiteKeyWidth * 3.5;
        final blackKeyWidth = whiteKeyWidth * 0.6;
        final blackKeyHeight = whiteKeyHeight * 0.62;
        final blackHitWidth = DesignTokens.touchTargetMin;

        return Semantics(
          container: true,
          label: 'Teclado de piano',
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: DesignTokens.borderRadiusMd,
              border: Border.all(color: scheme.outlineVariant),
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
                        child: _accessibleKey(
                          note: note,
                          onDarkKey: false,
                          colors: colors,
                          visual: AnimatedContainer(
                            duration: animDuration,
                            transform: pressed
                                ? (Matrix4.identity()
                                    ..translateByDouble(0.0, 4.0, 0.0, 1.0)
                                    ..scaleByDouble(0.985, 0.985, 1.0, 1.0))
                                : Matrix4.identity(),
                            margin: const EdgeInsets.symmetric(horizontal: 0.5),
                            decoration: BoxDecoration(
                              gradient: _whiteGradient(
                                note,
                                pressed,
                                scheme,
                                colors,
                              ),
                              border: Border.all(
                                color: _whiteKeyBorder(note, scheme, colors),
                                width: _whiteKeyBorderWidth(note),
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(
                                  note == 'C' ? 8 : 2,
                                ),
                                bottomRight: Radius.circular(
                                  note == 'B' ? 8 : 2,
                                ),
                              ),
                            ),
                            alignment: Alignment.bottomCenter,
                            padding: const EdgeInsets.only(bottom: 8),
                            child: widget.hideLabels
                                ? const SizedBox.shrink()
                                : ExcludeSemantics(
                                    child: Text(
                                      formatNoteLabel(
                                        note,
                                        widget.noteNamingMode,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontSize: widget.large ? 18 : 15,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.3,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  ...PianoKeyboard.blackNoteMap.entries.map((entry) {
                    final whiteIndex = PianoKeyboard.whiteNotes.indexOf(
                      entry.key,
                    );
                    final sharpNote = entry.value;
                    final pressed = _pressed.contains(sharpNote);
                    final leftOffset =
                        (whiteIndex + 1) * whiteKeyWidth - blackHitWidth / 2;

                    return Positioned(
                      left: leftOffset,
                      top: 0,
                      width: blackHitWidth,
                      height: blackKeyHeight,
                      child: _accessibleKey(
                        note: sharpNote,
                        onDarkKey: true,
                        colors: colors,
                        visual: Align(
                          child: AnimatedContainer(
                            duration: animDuration,
                            width: blackKeyWidth,
                            height: blackKeyHeight,
                            transform: pressed
                                ? (Matrix4.identity()
                                    ..translateByDouble(0.0, 5.0, 0.0, 1.0)
                                    ..scaleByDouble(0.97, 0.97, 1.0, 1.0))
                                : Matrix4.identity(),
                            decoration: BoxDecoration(
                              gradient: _blackGradient(
                                sharpNote,
                                pressed,
                                colors,
                              ),
                              border: Border.all(
                                color: widget.selectedNotes.contains(sharpNote)
                                    ? colors.selection
                                    : Colors.transparent,
                                width: widget.selectedNotes.contains(sharpNote)
                                    ? 2
                                    : 0,
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(4),
                                bottomRight: Radius.circular(4),
                              ),
                            ),
                            alignment: Alignment.bottomCenter,
                            padding: const EdgeInsets.only(bottom: 4),
                            child: widget.hideLabels
                                ? const SizedBox.shrink()
                                : ExcludeSemantics(
                                    child: Text(
                                      formatNoteLabel(
                                        sharpNote,
                                        widget.noteNamingMode,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontSize: widget.large ? 12 : 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
