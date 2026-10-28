import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';

/// Fila encima del teclado: «↻ Repetir», indicación y «Saltar ⏭».
class SessionKeyActions extends StatelessWidget {
  final String prompt;
  final VoidCallback? onRepeat;
  final VoidCallback? onSkip;

  const SessionKeyActions({
    super.key,
    required this.prompt,
    this.onRepeat,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(
      foregroundColor: DesignTokens.sessionTextLabel,
      disabledForegroundColor:
          DesignTokens.sessionTextSecondary.withValues(alpha: 0.5),
      minimumSize: const Size(
        DesignTokens.touchTargetMin,
        DesignTokens.touchTargetMin,
      ),
    );
    return Row(
      children: [
        TextButton.icon(
          onPressed: onRepeat,
          style: style,
          icon: const Icon(Icons.replay_rounded, size: 20),
          label: const Text('Repetir'),
        ),
        Expanded(
          child: Text(
            prompt,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DesignTokens.sessionTextSecondary,
                ),
          ),
        ),
        TextButton.icon(
          onPressed: onSkip,
          style: style,
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.skip_next_rounded, size: 20),
          label: const Text('Saltar'),
        ),
      ],
    );
  }
}
