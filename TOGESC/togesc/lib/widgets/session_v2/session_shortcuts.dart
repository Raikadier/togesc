import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Acción de un atajo físico de la sesión.
@immutable
class SessionShortcut {
  /// Nota (`C`, `C#`…) si el atajo responde una tecla.
  final String? note;
  final bool repeat;
  final bool next;

  /// `Esc`: pausar (v2.1).
  final bool pause;

  const SessionShortcut.note(String this.note)
      : repeat = false,
        next = false,
        pause = false;
  const SessionShortcut.repeat()
      : note = null,
        repeat = true,
        next = false,
        pause = false;
  const SessionShortcut.next()
      : note = null,
        repeat = false,
        next = true,
        pause = false;
  const SessionShortcut.pause()
      : note = null,
        repeat = false,
        next = false,
        pause = true;

  @override
  bool operator ==(Object other) =>
      other is SessionShortcut &&
      other.note == note &&
      other.repeat == repeat &&
      other.next == next &&
      other.pause == pause;

  @override
  int get hashCode => Object.hash(note, repeat, next, pause);

  @override
  String toString() {
    if (note != null) return 'SessionShortcut.note($note)';
    if (repeat) return 'SessionShortcut.repeat()';
    if (pause) return 'SessionShortcut.pause()';
    return 'SessionShortcut.next()';
  }
}

final _letterKeys = <LogicalKeyboardKey, String>{
  LogicalKeyboardKey.keyA: 'A',
  LogicalKeyboardKey.keyB: 'B',
  LogicalKeyboardKey.keyC: 'C',
  LogicalKeyboardKey.keyD: 'D',
  LogicalKeyboardKey.keyE: 'E',
  LogicalKeyboardKey.keyF: 'F',
  LogicalKeyboardKey.keyG: 'G',
};

/// Notas sin sostenido propio (no existen E# ni B#).
const _noSharp = {'E', 'B'};

/// Traduce una tecla física al atajo de la sesión (spec 1d):
/// `A–G` nota natural, `⇧`+letra sostenido (⇧E y ⇧B se ignoran),
/// `R` repetir, `Espacio` siguiente/saltar y `Esc` pausar. Con Ctrl, Alt o
/// Meta no hay
/// atajo (no se pisan los del navegador, como Ctrl+R). Función pura.
SessionShortcut? sessionShortcutFor(
  LogicalKeyboardKey key, {
  bool shift = false,
  bool otherModifier = false,
}) {
  if (otherModifier) return null;
  final letter = _letterKeys[key];
  if (letter != null) {
    if (!shift) return SessionShortcut.note(letter);
    if (_noSharp.contains(letter)) return null;
    return SessionShortcut.note('$letter#');
  }
  if (shift) return null;
  if (key == LogicalKeyboardKey.keyR) return const SessionShortcut.repeat();
  if (key == LogicalKeyboardKey.space) return const SessionShortcut.next();
  if (key == LogicalKeyboardKey.escape) return const SessionShortcut.pause();
  return null;
}

/// `true` si el foco está en un campo de texto (los atajos se desactivan).
bool isTextInputFocused() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return false;
  if (context.widget is EditableText) return true;
  return context.findAncestorWidgetOfExactType<EditableText>() != null;
}

/// Raíz de la sesión que escucha los atajos físicos (web y escritorio).
///
/// - Se desactivan si un campo de texto tiene el foco.
/// - No chocan con Enter/Espacio sobre la tecla enfocada: la tecla del piano
///   consume el evento antes de que llegue aquí. Espacio solo actúa como
///   «siguiente» si ningún control concreto tiene el foco, para no robar la
///   activación de un botón enfocado.
class SessionShortcuts extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final ValueChanged<String> onNote;
  final VoidCallback onRepeat;
  final VoidCallback onNext;

  /// `Esc` (v2.1). Sin callback, `Esc` no hace nada aquí.
  final VoidCallback? onPause;

  const SessionShortcuts({
    super.key,
    required this.child,
    required this.onNote,
    required this.onRepeat,
    required this.onNext,
    this.onPause,
    this.enabled = true,
  });

  @override
  State<SessionShortcuts> createState() => _SessionShortcutsState();
}

class _SessionShortcutsState extends State<SessionShortcuts> {
  final FocusNode _node = FocusNode(debugLabel: 'session-shortcuts');

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (isTextInputFocused()) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    final shortcut = sessionShortcutFor(
      event.logicalKey,
      shift: keyboard.isShiftPressed,
      otherModifier: keyboard.isControlPressed ||
          keyboard.isAltPressed ||
          keyboard.isMetaPressed,
    );
    if (shortcut == null) return KeyEventResult.ignored;
    if (shortcut.next) {
      final primary = FocusManager.instance.primaryFocus;
      if (primary != null && primary != _node) return KeyEventResult.ignored;
      widget.onNext();
      return KeyEventResult.handled;
    }
    if (shortcut.repeat) {
      widget.onRepeat();
      return KeyEventResult.handled;
    }
    if (shortcut.pause) {
      final onPause = widget.onPause;
      if (onPause == null) return KeyEventResult.ignored;
      onPause();
      return KeyEventResult.handled;
    }
    widget.onNote(shortcut.note!);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _node,
      autofocus: true,
      onKeyEvent: _onKey,
      child: widget.child,
    );
  }
}
