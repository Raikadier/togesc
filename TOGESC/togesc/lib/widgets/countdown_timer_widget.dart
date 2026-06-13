import 'package:flutter/material.dart';

/// Widget de countdown circular para el modo velocidad.
class CountdownTimerWidget extends StatelessWidget {
  final double remainingTime;
  final double totalTime;

  const CountdownTimerWidget({
    super.key,
    required this.remainingTime,
    required this.totalTime,
  });

  Color _getColor() {
    final ratio = remainingTime / totalTime;
    if (ratio > 0.5) return Colors.green;
    if (ratio > 0.25) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final progress = totalTime > 0 ? (remainingTime / totalTime).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(_getColor()),
          ),
          Text(
            '${remainingTime.toStringAsFixed(1)}s',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getColor(),
            ),
          ),
        ],
      ),
    );
  }
}
