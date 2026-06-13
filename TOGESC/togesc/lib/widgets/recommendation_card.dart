import 'package:flutter/material.dart';

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

    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.blue, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Recomendaciones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 14)),
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
                  color: Colors.red,
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
                    backgroundColor: Colors.red.shade50,
                    side: BorderSide(color: Colors.red.shade200),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
