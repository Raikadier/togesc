import 'package:flutter/material.dart';

/// Indicador visual del progreso SRS de una nota.
///
/// Muestra 5 bloques para fase de aprendizaje o badge "Consolidada".
class SrsProgressIndicator extends StatelessWidget {
  final String note;
  final int consecutiveCorrect;
  final bool isLearning;

  const SrsProgressIndicator({
    super.key,
    required this.note,
    required this.consecutiveCorrect,
    required this.isLearning,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          note,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(width: 8),
        if (isLearning) ...[
          ...List.generate(5, (i) {
            final filled = i < consecutiveCorrect;
            return Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: filled ? Colors.deepPurple : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
          const SizedBox(width: 4),
          Text('$consecutiveCorrect/5', style: const TextStyle(fontSize: 12)),
        ] else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Consolidada',
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
