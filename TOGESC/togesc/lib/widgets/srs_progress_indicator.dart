import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../app/togesc_colors.dart';

/// Indicador visual del progreso SRS de una nota.
///
/// Muestra el umbral del perfil activo o el badge "Consolidada".
class SrsProgressIndicator extends StatelessWidget {
  final String note;
  final int consecutiveCorrect;
  final bool isLearning;
  final int learningThreshold;

  const SrsProgressIndicator({
    super.key,
    required this.note,
    required this.consecutiveCorrect,
    required this.isLearning,
    this.learningThreshold = 5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = TogescColors.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          note,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(width: DesignTokens.spacingSm),
        if (isLearning) ...[
          ...List.generate(learningThreshold, (i) {
            final filled = i < consecutiveCorrect;
            return Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: filled
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(DesignTokens.spacingXs / 2),
              ),
            );
          }),
          const SizedBox(width: DesignTokens.spacingXs),
          Text(
            '$consecutiveCorrect/$learningThreshold',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ] else
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingSm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: colors.correctContainer,
              borderRadius: DesignTokens.borderRadiusMd,
            ),
            child: Text(
              'Consolidada',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onCorrectContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
