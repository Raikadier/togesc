import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../app/togesc_colors.dart';
import '../services/note_parser.dart';

/// Campo de texto estilo command-bar (Stitch).
class NoteInputField extends StatefulWidget {
  final ValueChanged<List<String>> onSubmitted;
  final bool enabled;
  final String hintText;

  const NoteInputField({
    super.key,
    required this.onSubmitted,
    this.enabled = true,
    this.hintText = 'Escribe notas (C, Do, Mi...)',
  });

  @override
  State<NoteInputField> createState() => _NoteInputFieldState();
}

class _NoteInputFieldState extends State<NoteInputField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final notes = parseNotes(text);
    if (notes.isNotEmpty) {
      widget.onSubmitted(notes);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: DesignTokens.borderRadiusMd,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        decoration: InputDecoration(
          hintText: widget.hintText,
          filled: true,
          fillColor: scheme.surfaceContainerLowest,
          prefixIcon: const Icon(Icons.keyboard_rounded),
          suffixIcon: IconButton(
            tooltip: 'Enviar',
            onPressed: widget.enabled ? _submit : null,
            icon: Icon(Icons.send_rounded, color: scheme.primary),
          ),
          border: OutlineInputBorder(
            borderRadius: DesignTokens.borderRadiusMd,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: DesignTokens.borderRadiusMd,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: DesignTokens.borderRadiusMd,
            borderSide: BorderSide(
              color: TogescColors.of(context).selection,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMd,
            vertical: DesignTokens.spacingMd,
          ),
        ),
        textCapitalization: TextCapitalization.characters,
        onSubmitted: (_) => _submit(),
        onEditingComplete: _submit,
      ),
    );
  }
}
