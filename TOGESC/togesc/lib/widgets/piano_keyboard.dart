import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/design_tokens.dart';
import '../app/togesc_colors.dart';
import '../constants/note_naming.dart';

/// Estética del teclado.
///
/// - [classic]: teclado claro original (velocidad y resto de pantallas).
/// - [session]: teclado v2 de la sesión oscura móvil (1b): 230 de alto,
///   contenedor `#1A121E` con radio 16 y negras de 38×140.
/// - [sessionWide]: teclado ancho de escritorio (1d): 210 de alto y negras
///   de 52×126.
enum PianoKeyboardVariant { classic, session, sessionWide }

/// Teclado de piano interactivo.
///
/// La API es retrocompatible: los parámetros nuevos ([variant], [dimOthers])
/// son opcionales y por defecto reproducen el teclado clásico.
class PianoKeyboard extends StatefulWidget {
  final Set<String> selectedNotes;
  final Set<String> correctNotes;
  final Set<String> incorrectNotes;
  final ValueChanged<String>? onNoteTapped;
  final bool disabled;
  final NoteNamingMode noteNamingMode;
  final bool large;
  final bool hideLabels;

  /// Estética del teclado (por defecto la clásica).
  final PianoKeyboardVariant variant;

  /// Atenúa las teclas sin feedback cuando hay alguna correcta o errónea
  /// (fase `result` de la sesión v2). Solo afecta a las variantes de sesión.
  final bool dimOthers;

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
    this.variant = PianoKeyboardVariant.classic,
    this.dimOthers = false,
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

  bool get _isSession => widget.variant != PianoKeyboardVariant.classic;

  Widget? _statusBadge(
    String note, {
    required bool onDarkKey,
    required TogescColors colors,
  }) {
    // En sesión las teclas blancas con feedback son verde o rojo claros:
    // el icono va en el tono profundo (>=4,5:1) y en las negras, en blanco.
    final size = _isSession ? 20.0 : (widget.large ? 18.0 : 14.0);
    if (widget.correctNotes.contains(note)) {
      return Icon(
        Icons.check_circle,
        size: size,
        color: onDarkKey
            ? Colors.white
            : (_isSession ? _sessionCorrectInk : colors.correct),
        semanticLabel: 'correcta',
      );
    }
    if (widget.incorrectNotes.contains(note)) {
      return Icon(
        Icons.cancel,
        size: size,
        color: onDarkKey
            ? Colors.white
            : (_isSession ? _sessionWrongInk : colors.incorrect),
        semanticLabel: 'incorrecta',
      );
    }
    return null;
  }

  /// Tinta sobre las teclas blancas de sesión con feedback.
  static const _sessionCorrectInk = Color(0xFF1B5E20);
  static const _sessionWrongInk = Color(0xFF7A1010);
  static const _sessionWhiteLabel = Color(0xFF4D4351);

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
              alignment:
                  _isSession ? Alignment.bottomCenter : Alignment.topCenter,
              children: [
                visual,
                if (badge != null)
                  Padding(
                    // En sesión el badge va sobre la etiqueta, en la parte
                    // visible de la tecla (las negras tapan el borde superior
                    // de las blancas).
                    padding: _isSession
                        ? EdgeInsets.only(
                            bottom: onDarkKey
                                ? (widget.hideLabels ? 8 : 24)
                                : (widget.hideLabels ? 12 : 34),
                          )
                        : const EdgeInsets.only(top: 4),
                    child: badge,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSession) return _buildSession(context);
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

  // ---------------------------------------------------------------------------
  // Variantes de sesión v2 (1b móvil y 1d escritorio).
  // ---------------------------------------------------------------------------

  bool get _hasFeedback =>
      widget.correctNotes.isNotEmpty || widget.incorrectNotes.isNotEmpty;

  bool _isDimmed(String note) =>
      widget.dimOthers &&
      _hasFeedback &&
      !widget.correctNotes.contains(note) &&
      !widget.incorrectNotes.contains(note);

  LinearGradient _sessionGradient(
    String note, {
    required bool black,
    required TogescColors colors,
  }) {
    if (widget.correctNotes.contains(note)) {
      return black ? colors.pianoBlackKeyCorrect : colors.pianoWhiteKeyCorrect;
    }
    if (widget.incorrectNotes.contains(note)) {
      return black ? colors.pianoBlackKeyWrong : colors.pianoWhiteKeyWrong;
    }
    if (_isDimmed(note)) {
      return black ? colors.pianoBlackKeyDimmed : colors.pianoWhiteKeyDimmed;
    }
    return black ? colors.pianoBlackKey : colors.pianoWhiteKey;
  }

  Widget _sessionLabel(String note, {required bool black}) {
    if (widget.hideLabels) return const SizedBox.shrink();
    final wide = widget.variant == PianoKeyboardVariant.sessionWide;
    final Color color;
    if (black) {
      color = Colors.white.withValues(alpha: _isDimmed(note) ? 0.6 : 0.92);
    } else if (widget.correctNotes.contains(note)) {
      color = _sessionCorrectInk;
    } else if (widget.incorrectNotes.contains(note)) {
      color = _sessionWrongInk;
    } else {
      color = _isDimmed(note) ? const Color(0xFF2A2230) : _sessionWhiteLabel;
    }
    return ExcludeSemantics(
      child: Text(
        formatNoteLabel(note, widget.noteNamingMode),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: TextStyle(
          fontSize: black ? (wide ? 12 : 10) : (wide ? 15 : 14),
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSession(BuildContext context) {
    final colors = TogescColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final animDuration = reduceMotion ? Duration.zero : DesignTokens.motionFast;
    final wide = widget.variant == PianoKeyboardVariant.sessionWide;
    final containerHeight = wide
        ? DesignTokens.pianoSessionWideHeight
        : DesignTokens.pianoSessionHeight;
    final blackSize = wide
        ? DesignTokens.pianoSessionWideBlackKeySize
        : DesignTokens.pianoSessionBlackKeySize;
    const padding = 8.0;
    // Zona táctil de las negras: nunca menos de 48 (WCAG 2.5.8), aunque
    // visualmente midan 38.
    final blackHitWidth = blackSize.width < DesignTokens.touchTargetMin
        ? DesignTokens.touchTargetMin
        : blackSize.width;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = wide ? 960.0 : 560.0;
        // 7 teclas x 48 dp mínimo + relleno del contenedor.
        const minWidth = 336.0 + padding * 2;
        final available =
            constraints.hasBoundedWidth ? constraints.maxWidth : maxWidth;
        final totalWidth = available.clamp(minWidth, maxWidth);
        final innerWidth = totalWidth - padding * 2;
        final keysHeight = containerHeight - padding * 2;
        final whiteKeyWidth = innerWidth / 7;
        final blackHeight = blackSize.height.clamp(0.0, keysHeight * 0.7);

        return Semantics(
          container: true,
          label: 'Teclado de piano',
          child: Container(
            key: const ValueKey('piano-session-container'),
            width: totalWidth,
            height: containerHeight,
            padding: const EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: DesignTokens.pianoSessionContainer,
              borderRadius: BorderRadius.circular(
                DesignTokens.pianoSessionRadius,
              ),
              border: Border.all(color: DesignTokens.sessionBorderSubtle),
            ),
            child: Stack(
              children: [
                Row(
                  children: PianoKeyboard.whiteNotes.map((note) {
                    final pressed = _pressed.contains(note);
                    final selected = widget.selectedNotes.contains(note);
                    return Expanded(
                      child: _accessibleKey(
                        note: note,
                        onDarkKey: false,
                        colors: colors,
                        visual: AnimatedContainer(
                          key: ValueKey('piano-key-$note'),
                          duration: animDuration,
                          transform: pressed
                              ? (Matrix4.identity()
                                ..translateByDouble(0.0, 3.0, 0.0, 1.0))
                              : Matrix4.identity(),
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            gradient: _sessionGradient(
                              note,
                              black: false,
                              colors: colors,
                            ),
                            border: selected
                                ? Border.all(color: colors.selection, width: 3)
                                : null,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                              bottom: Radius.circular(8),
                            ),
                          ),
                          alignment: Alignment.bottomCenter,
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _sessionLabel(note, black: false),
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
                  final selected = widget.selectedNotes.contains(sharpNote);
                  final leftOffset =
                      (whiteIndex + 1) * whiteKeyWidth - blackHitWidth / 2;
                  return Positioned(
                    left: leftOffset,
                    top: 0,
                    width: blackHitWidth,
                    height: blackHeight,
                    child: _accessibleKey(
                      note: sharpNote,
                      onDarkKey: true,
                      colors: colors,
                      visual: Align(
                        alignment: Alignment.topCenter,
                        child: AnimatedContainer(
                          key: ValueKey('piano-key-$sharpNote'),
                          duration: animDuration,
                          width: blackSize.width,
                          height: blackHeight,
                          transform: pressed
                              ? (Matrix4.identity()
                                ..translateByDouble(0.0, 3.0, 0.0, 1.0))
                              : Matrix4.identity(),
                          decoration: BoxDecoration(
                            gradient: _sessionGradient(
                              sharpNote,
                              black: true,
                              colors: colors,
                            ),
                            border: selected
                                ? Border.all(color: colors.selection, width: 3)
                                : null,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(6),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.bottomCenter,
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _sessionLabel(sharpNote, black: true),
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
