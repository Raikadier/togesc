import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../app/togesc_colors.dart';
import 'togesc_ui.dart';

/// Panel de recomendaciones de practica basado en el estado SRS.
class RecommendationCard extends StatelessWidget {
  final Map<String, dynamic> recommendations;

  const RecommendationCard({super.key, required this.recommendations});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = TogescColors.of(context);
    final message = recommendations['message'] as String? ?? '';
    final totalOverdue = recommendations['total_overdue'] as int? ?? 0;
    final learningCount = recommendations['learning_notes_count'] as int? ?? 0;
    final daysSince = recommendations['days_since_last_session'] as int? ?? 0;
    final criticalNotes =
        recommendations['critical_notes'] as List<dynamic>? ?? [];

    return TogescCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: scheme.primaryContainer),
              const SizedBox(width: DesignTokens.spacingSm),
              Text('Recomendaciones', style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          Text(message, style: theme.textTheme.bodyMedium),
          const SizedBox(height: DesignTokens.spacingMd),
          _buildStatRow(context, 'Notas pendientes', '$totalOverdue'),
          _buildStatRow(context, 'En aprendizaje', '$learningCount'),
          if (daysSince > 0)
            _buildStatRow(context, 'Última sesión', 'hace $daysSince día(s)'),
          if (criticalNotes.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spacingSm),
            Text(
              'Notas criticas:',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.incorrect,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingXs),
            Wrap(
              spacing: DesignTokens.spacingSm,
              children: criticalNotes.take(5).map((item) {
                final note = item is (String, int) ? item.$1 : '$item';
                return Chip(
                  label: Text(
                    note,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onIncorrectContainer,
                    ),
                  ),
                  backgroundColor: colors.incorrectContainer,
                  side: BorderSide(color: colors.incorrect),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
