import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../constants/game_constants.dart';
import 'game_session_views.dart';
import 'togesc_ui.dart';

/// Vista idle del modo velocidad.
class SpeedSessionIdleView extends StatelessWidget {
  final VoidCallback onStart;

  const SpeedSessionIdleView({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return GameSessionPhaseLayout(
      icon: Icons.speed_rounded,
      accentColor: DesignTokens.secondary,
      title: 'Modo Velocidad',
      subtitle: 'Tiempo inicial: ${speedInitialTime.toStringAsFixed(0)}s',
      footer: FilledButton.icon(
        onPressed: onStart,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Comenzar'),
      ),
    );
  }
}

/// Vista listening del modo velocidad.
class SpeedSessionListeningView extends StatelessWidget {
  final int numNotes;

  const SpeedSessionListeningView({super.key, required this.numNotes});

  @override
  Widget build(BuildContext context) {
    return GameSessionPhaseLayout(
      icon: Icons.graphic_eq_rounded,
      title: 'Escucha... ($numNotes nota(s))',
      subtitle: 'Responde en cuanto termine el audio',
      showProgress: true,
    );
  }
}

/// Feedback tras acierto, error o timeout.
class SpeedSessionFeedbackView extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String? subtitle;
  final Widget? footer;

  const SpeedSessionFeedbackView({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    this.subtitle,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return GameSessionPhaseLayout(
      icon: icon,
      accentColor: accentColor,
      title: title,
      subtitle: subtitle,
      footer: footer,
    );
  }
}

/// Resumen de sesión al terminar (game over).
class SpeedSessionSummaryCard extends StatelessWidget {
  final int responses;
  final int streak;
  final double averageTime;
  final double bestTime;
  final double timeLimit;

  const SpeedSessionSummaryCard({
    super.key,
    required this.responses,
    required this.streak,
    required this.averageTime,
    required this.bestTime,
    required this.timeLimit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TogescCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen de sesion', style: theme.textTheme.titleLarge),
          const SizedBox(height: DesignTokens.spacingMd),
          _StatRow(label: 'Respuestas', value: '$responses'),
          _StatRow(label: 'Racha final', value: '$streak'),
          _StatRow(
            label: 'Promedio',
            value: '${averageTime.toStringAsFixed(2)}s',
          ),
          _StatRow(label: 'Mejor tiempo', value: '${bestTime.toStringAsFixed(2)}s'),
          _StatRow(
            label: 'Tiempo limite',
            value: '${timeLimit.toStringAsFixed(1)}s',
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: DesignTokens.onSurfaceVariant),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Botones reintentar / volver al menú.
class SpeedSessionRetryActions extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onMenu;

  const SpeedSessionRetryActions({
    super.key,
    required this.onRetry,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Reintentar'),
          ),
        ),
        const SizedBox(width: DesignTokens.spacingMd),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onMenu,
            icon: const Icon(Icons.home_rounded),
            label: const Text('Menu'),
          ),
        ),
      ],
    );
  }
}

/// Opción de modo en el selector de velocidad.
class SpeedModeOptionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const SpeedModeOptionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingSm),
      child: TogescCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor:
                DesignTokens.primaryContainer.withValues(alpha: 0.12),
            child: Icon(icon, color: DesignTokens.primaryContainer),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
          ),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: DesignTokens.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Encabezado de respuesta en modo velocidad.
class SpeedSessionAnswerHeader extends StatelessWidget {
  final int numNotes;

  const SpeedSessionAnswerHeader({super.key, required this.numNotes});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Que nota(s)? ($numNotes)',
      style: Theme.of(context).textTheme.titleLarge,
      textAlign: TextAlign.center,
    );
  }
}
