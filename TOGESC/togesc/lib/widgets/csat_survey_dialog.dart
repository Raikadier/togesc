import 'package:flutter/material.dart';

/// Encuesta CSAT ocasional (Fase 6): valoracion 1-5 estrellas.
class CsatSurveyDialog extends StatefulWidget {
  const CsatSurveyDialog({super.key});

  @override
  State<CsatSurveyDialog> createState() => _CsatSurveyDialogState();
}

class _CsatSurveyDialogState extends State<CsatSurveyDialog> {
  int _rating = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Como va tu experiencia?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tu opinion nos ayuda a mejorar TOGESC. '
              'Califica del 1 al 5.',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                final selected = star <= _rating;
                return IconButton(
                  tooltip: '$star estrella${star > 1 ? 's' : ''}',
                  onPressed: () => setState(() => _rating = star),
                  icon: Icon(
                    selected ? Icons.star : Icons.star_border,
                    color: selected ? Colors.amber : null,
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Ahora no'),
        ),
        FilledButton(
          onPressed: _rating == 0
              ? null
              : () => Navigator.of(context).pop(
                    CsatSurveyResult(
                      rating: _rating,
                      comment: _commentController.text.trim(),
                    ),
                  ),
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}

class CsatSurveyResult {
  const CsatSurveyResult({required this.rating, this.comment = ''});

  final int rating;
  final String comment;
}

Future<CsatSurveyResult?> showCsatSurveyDialog(BuildContext context) {
  return showDialog<CsatSurveyResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const CsatSurveyDialog(),
  );
}
