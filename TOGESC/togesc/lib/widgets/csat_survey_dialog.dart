import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import 'togesc_premium_dialog.dart';

/// Encuesta CSAT ocasional (Stitch premium).
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
    final scheme = Theme.of(context).colorScheme;

    return TogescPremiumDialog(
      icon: Icons.star_rounded,
      accentColor: DesignTokens.selection,
      title: 'Como va tu experiencia?',
      subtitle: 'Tu opinion nos ayuda a mejorar TOGESC. Califica del 1 al 5.',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                      : scheme.outlineVariant,
                  size: 36,
                ),
              );
            }),
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Comentario (opcional)',
              alignLabelWithHint: true,
              filled: true,
              fillColor: scheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: DesignTokens.borderRadiusXl,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Ahora no'),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        FilledButton(
          onPressed: _rating == 0
              ? null
              : () => Navigator.of(context).pop(
                    CsatSurveyResult(
                      rating: _rating,
                      comment: _commentController.text.trim(),
                    ),
                  ),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(DesignTokens.touchTargetMin),
            shape: RoundedRectangleBorder(
              borderRadius: DesignTokens.borderRadiusXl,
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
