import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../constants/game_constants.dart';
import 'game_session_views.dart';

/// Vista idle del modo velocidad.
class SpeedSessionIdleView extends StatelessWidget {
  final VoidCallback onStart;

  const SpeedSessionIdleView({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return GameSessionPhaseLayout(
      badge: 'MODO VELOCIDAD',
      icon: Icons.speed_rounded,
      accentColor: DesignTokens.speedAccent,
      iconGradient: DesignTokens.speedGradient,
      title: 'Listo para el desafio',
      subtitle: 'Tiempo inicial: ${speedInitialTime.toStringAsFixed(0)}s',
      footer: FilledButton.icon(
        onPressed: onStart,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(DesignTokens.touchTargetMin),
          backgroundColor: DesignTokens.speedAccent,
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusXl,
          ),
        ),
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
      badge: 'RÁFAGA ACTIVA',
      icon: Icons.graphic_eq_rounded,
      accentColor: DesignTokens.speedAccent,
      title: 'Escucha...',
      subtitle: '$numNotes nota(s) — responde al terminar el audio',
      showProgress: true,
      pulsingIcon: true,
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

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      decoration: BoxDecoration(
        gradient: DesignTokens.speedGradient,
        borderRadius: DesignTokens.borderRadiusXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FIN DE SESION',
            style: theme.textTheme.labelMedium?.copyWith(
              color: DesignTokens.onPrimary.withValues(alpha: 0.85),
              letterSpacing: 0.5,
            ),
          ),
          Text(
            'Resumen de velocidad',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: DesignTokens.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
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
            style: TextStyle(
              color: DesignTokens.onPrimary.withValues(alpha: 0.85),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: DesignTokens.onPrimary,
            ),
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

/// Opción de modo en el selector de velocidad (bento Stitch).
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
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingMd),
      child: Material(
        color: scheme.surfaceContainerLowest,
        borderRadius: DesignTokens.borderRadiusXl,
        child: InkWell(
          onTap: onTap,
          borderRadius: DesignTokens.borderRadiusXl,
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spacingLg),
            decoration: BoxDecoration(
              borderRadius: DesignTokens.borderRadiusXl,
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: DesignTokens.speedContainer.withValues(
                      alpha: scheme.brightness == Brightness.dark ? 0.25 : 1,
                    ),
                    borderRadius: DesignTokens.borderRadiusMd,
                  ),
                  child: Icon(icon, color: DesignTokens.speedAccent),
                ),
                const SizedBox(height: DesignTokens.spacingMd),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: DesignTokens.spacingXs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: DesignTokens.spacingMd),
                Row(
                  children: [
                    Text(
                      'Empieza ahora',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: DesignTokens.speedAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: DesignTokens.speedAccent,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMd,
            vertical: DesignTokens.spacingXs,
          ),
          decoration: BoxDecoration(
            color: DesignTokens.speedContainer,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: DesignTokens.speedAccent.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bolt_rounded,
                size: 16,
                color: DesignTokens.speedAccent,
              ),
              const SizedBox(width: DesignTokens.spacingXs),
              Text(
                'MODO VELOCIDAD',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: DesignTokens.speedAccent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        Text(
          numNotes == 1
              ? 'Que nota escuchaste?'
              : 'Que nota(s) escuchaste? ($numNotes)',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
