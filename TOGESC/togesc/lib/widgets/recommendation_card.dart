import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import 'togesc_ui.dart';

/// Panel de recomendaciones de practica basado en el estado SRS.
class RecommendationCard extends StatelessWidget {
  final Map<String, dynamic> recommendations;

  const RecommendationCard({
    super.key,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.lightbulb, color: DesignTokens.primaryContainer),
              const SizedBox(width: 8),
              Text(
                'Recomendaciones',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            _buildStatRow('Notas pendientes', '$totalOverdue'),
            _buildStatRow('En aprendizaje', '$learningCount'),
            if (daysSince > 0)
              _buildStatRow('Ultima sesion', 'hace $daysSince dia(s)'),
            if (criticalNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Notas criticas:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: DesignTokens.incorrect,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: criticalNotes.take(5).map((item) {
                  // item is a Record (String, int) but comes as dynamic
                  final note = item is (String, int) ? item.$1 : '$item';
                  return Chip(
                    label: Text(note),
                    backgroundColor: DesignTokens.errorContainer,
                    side: const BorderSide(color: DesignTokens.incorrect),
                  );
                }).toList(),
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: DesignTokens.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
