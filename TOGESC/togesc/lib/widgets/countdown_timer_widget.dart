import 'package:flutter/material.dart';

import '../app/design_tokens.dart';

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
    final ratio = totalTime > 0 ? remainingTime / totalTime : 0;
    if (ratio > 0.5) return DesignTokens.correct;
    if (ratio > 0.25) return DesignTokens.selection;
    return DesignTokens.incorrect;
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        totalTime > 0 ? (remainingTime / totalTime).clamp(0.0, 1.0) : 0.0;
    final color = _getColor();
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: DesignTokens.surfaceContainer,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Text(
                '${remainingTime.toStringAsFixed(1)}s',
                style: theme.textTheme.titleLarge?.copyWith(color: color),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        Text(
          'Tiempo restante',
          style: theme.textTheme.labelLarge?.copyWith(
            color: DesignTokens.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
