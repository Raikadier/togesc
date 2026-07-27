import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../app/togesc_colors.dart';
import '../constants/game_constants.dart';
import 'game_session_views.dart';

/// Vista idle del modo velocidad.
class SpeedSessionIdleView extends StatelessWidget {
  final VoidCallback onStart;
  final double initialTime;

  const SpeedSessionIdleView({
    super.key,
    required this.onStart,
    this.initialTime = speedInitialTime,
  });

  @override
  Widget build(BuildContext context) {
    final speed = TogescColors.of(context).speedAccent;
    return GameSessionPhaseLayout(
      badge: 'MODO VELOCIDAD',
      icon: Icons.speed_rounded,
      accentColor: speed,
      iconGradient: DesignTokens.speedGradient,
      title: 'Listo para el desafío',
      subtitle: 'Tiempo inicial: ${initialTime.toStringAsFixed(0)}s',
      footer: FilledButton.icon(
        onPressed: onStart,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(DesignTokens.touchTargetMin),
          backgroundColor: speed,
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
      accentColor: TogescColors.of(context).speedAccent,
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
          _StatRow(
            label: 'Mejor tiempo',
            value: '${bestTime.toStringAsFixed(2)}s',
          ),
          _StatRow(
            label: 'Tiempo límite',
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
            label: const Text('Menú'),
          ),
        ),
      ],
    );
  }
}

/// Opción de modo en el selector de velocidad (bento Stitch).
enum SpeedModeCardVariant { standard, chaos, darkKeys }

class SpeedModeOptionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final SpeedModeCardVariant variant;
  final bool compact;
  final bool showCta;

  const SpeedModeOptionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
    this.variant = SpeedModeCardVariant.standard,
    this.compact = false,
    this.showCta = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final speed = TogescColors.of(context);
    final isChaos = variant == SpeedModeCardVariant.chaos;
    final isDark = variant == SpeedModeCardVariant.darkKeys;
    final onCard = isChaos || isDark ? Colors.white : scheme.onSurface;
    final onMuted = isChaos || isDark
        ? Colors.white.withValues(alpha: 0.85)
        : scheme.onSurfaceVariant;
    final ctaColor = isChaos || isDark ? Colors.white : speed.speedAccent;
    final iconBg = isChaos
        ? Colors.white.withValues(alpha: 0.2)
        : isDark
        ? Colors.white.withValues(alpha: 0.1)
        : speed.speedContainer;
    final iconColor = isChaos
        ? Colors.white
        : isDark
        ? speed.speedAccent
        : speed.speedAccent;

    return Semantics(
      button: true,
      label: title,
      hint: subtitle,
      child: Material(
        color: Colors.transparent,
        borderRadius: DesignTokens.borderRadiusXl,
        child: InkWell(
          onTap: onTap,
          borderRadius: DesignTokens.borderRadiusXl,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: DesignTokens.borderRadiusXl,
              gradient: isChaos ? DesignTokens.speedGradient : null,
              color: isChaos
                  ? null
                  : isDark
                  ? DesignTokens.pianoBlack
                  : scheme.surfaceContainerLowest,
              border: Border.all(
                color: isChaos || isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(
                compact ? DesignTokens.spacingMd : DesignTokens.spacingLg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: compact ? 40 : 48,
                    height: compact ? 40 : 48,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: DesignTokens.borderRadiusMd,
                    ),
                    child: Icon(icon, color: iconColor),
                  ),
                  SizedBox(
                    height: compact
                        ? DesignTokens.spacingSm
                        : DesignTokens.spacingMd,
                  ),
                  Text(
                    title,
                    style:
                        (compact
                                ? theme.textTheme.titleLarge
                                : theme.textTheme.headlineSmall)
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: onCard,
                            ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: DesignTokens.spacingXs),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onMuted,
                      ),
                    ),
                  ],
                  if (showCta) ...[
                    const SizedBox(height: DesignTokens.spacingMd),
                    Row(
                      children: [
                        Text(
                          'Empieza ahora',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: ctaColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: ctaColor,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
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
    final speed = TogescColors.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMd,
            vertical: DesignTokens.spacingXs,
          ),
          decoration: BoxDecoration(
            color: speed.speedContainer,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: speed.speedAccent.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: speed.speedAccent),
              const SizedBox(width: DesignTokens.spacingXs),
              Text(
                'MODO VELOCIDAD',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: speed.speedAccent,
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
              ? '¿Qué nota escuchaste?'
              : '¿Qué nota(s) escuchaste? ($numNotes)',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
