import 'package:flutter/material.dart';

/// Card que muestra el resultado de una ronda.
class ResultCard extends StatelessWidget {
  final bool isCorrect;
  final Set<String> correctNotes;
  final double responseTime;
  final Map<String, Map<String, dynamic>>? srsChanges;

  const ResultCard({
    super.key,
    required this.isCorrect,
    required this.correctNotes,
    required this.responseTime,
    this.srsChanges,
  });

  String _timeComment() {
    if (responseTime < 2.0) return 'Rapido!';
    if (responseTime < 5.0) return 'Buen tiempo';
    return 'Tomate tu tiempo';
  }

  Color _timeColor() {
    if (responseTime < 2.0) return Colors.green;
    if (responseTime < 5.0) return Colors.orange;
    return Colors.red.shade300;
  }

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? Colors.green : Colors.red;
    final icon = isCorrect ? Icons.check_circle : Icons.cancel;
    final title = isCorrect ? 'EXCELENTE!' : 'INCORRECTO';
    final notesList = correctNotes.toList()..sort();

    return Card(
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 48),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCorrect
                  ? 'Acertaste: ${notesList.join(", ")}'
                  : 'Las notas correctas eran: ${notesList.join(", ")}',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer, size: 16, color: _timeColor()),
                const SizedBox(width: 4),
                Text(
                  '${responseTime.toStringAsFixed(2)}s - ${_timeComment()}',
                  style: TextStyle(color: _timeColor()),
                ),
              ],
            ),
            if (srsChanges != null && srsChanges!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Progreso de notas:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              ...srsChanges!.entries.map((entry) {
                final newData = entry.value['new'] as Map<String, dynamic>;
                final consecutive = newData['consecutive_correct'] as int;
                final isLearning = newData['is_learning'] as bool;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${entry.key}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (isLearning) ...[
                        ...List.generate(5, (i) => Icon(
                          i < consecutive ? Icons.square : Icons.square_outlined,
                          size: 14,
                          color: i < consecutive ? Colors.deepPurple : Colors.grey,
                        )),
                        Text(' $consecutive/5', style: const TextStyle(fontSize: 12)),
                      ] else
                        const Text('Consolidada', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
