import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
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
        borderRadius: DesignTokens.borderRadiusXl,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
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
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: DesignTokens.spacingMd),
            child: Text(
              'INPUT',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.outline,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          border: OutlineInputBorder(
            borderRadius: DesignTokens.borderRadiusXl,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: DesignTokens.borderRadiusXl,
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: DesignTokens.borderRadiusXl,
            borderSide: BorderSide(
              color: scheme.primary,
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
