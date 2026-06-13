import 'package:flutter/material.dart';

import '../services/note_parser.dart';

/// Campo de texto alternativo para ingresar notas.
///
/// Parsea la entrada del usuario y devuelve las notas normalizadas.
class NoteInputField extends StatefulWidget {
  final ValueChanged<List<String>> onSubmitted;
  final bool enabled;
  final String hintText;

  const NoteInputField({
    super.key,
    required this.onSubmitted,
    this.enabled = true,
    this.hintText = 'Escribe notas: C E G / C, E, G / C-E-G',
  });

  @override
  State<NoteInputField> createState() => _NoteInputFieldState();
}

class _NoteInputFieldState extends State<NoteInputField> {
  final _controller = TextEditingController();

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: widget.enabled,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: widget.enabled ? _submit : null,
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}
