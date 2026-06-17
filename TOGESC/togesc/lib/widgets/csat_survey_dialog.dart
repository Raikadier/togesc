import 'package:flutter/material.dart';

import '../app/design_tokens.dart';

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
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Como va tu experiencia?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tu opinion nos ayuda a mejorar TOGESC. Califica del 1 al 5.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DesignTokens.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                final selected = star <= _rating;
                return IconButton(
                  tooltip: '$star estrella${star > 1 ? 's' : ''}',
                  onPressed: () => setState(() => _rating = star),
                  icon: Icon(
                    selected ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: selected
                        ? DesignTokens.selection
                        : DesignTokens.outlineVariant,
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
                alignLabelWithHint: true,
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
