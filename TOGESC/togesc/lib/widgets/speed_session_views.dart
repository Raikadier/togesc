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
    final colors = TogescColors.of(context);
    final speed = colors.speedAccent;
    return GameSessionPhaseLayout(
      badge: 'Modo velocidad',
      icon: Icons.speed_rounded,
      accentColor: speed,
      title: 'Listo para el desafío',
      subtitle: 'Tiempo inicial: ${initialTime.toStringAsFixed(0)}s',
      footer: FilledButton.icon(
        onPressed: onStart,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(DesignTokens.touchTargetMin),
          backgroundColor: speed,
          foregroundColor: colors.onSpeedAccent,
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusCta,
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
      badge: 'Ráfaga activa',
      icon: Icons.graphic_eq_rounded,
      accentColor: TogescColors.of(context).speedAccent,
      title: 'Escucha…',
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
    final colors = TogescColors.of(context);
    final speed = colors.speedAccent;
    final onSpeed = colors.onSpeedAccent;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      decoration: BoxDecoration(
        color: speed,
        borderRadius: DesignTokens.borderRadiusCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fin de sesión'.toUpperCase(),
            style: DesignTokens.overline.copyWith(color: onSpeed),
          ),
          Text(
            'Resumen de velocidad',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: onSpeed,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          _StatRow(label: 'Respuestas', value: '$responses', color: onSpeed),
          _StatRow(label: 'Racha final', value: '$streak', color: onSpeed),
          _StatRow(
            label: 'Promedio',
            value: '${averageTime.toStringAsFixed(2)}s',
            color: onSpeed,
          ),
          _StatRow(
            label: 'Mejor tiempo',
            value: '${bestTime.toStringAsFixed(2)}s',
            color: onSpeed,
          ),
          _StatRow(
            label: 'Tiempo límite',
            value: '${timeLimit.toStringAsFixed(1)}s',
            color: onSpeed,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
            ).merge(DesignTokens.tabularNumbers),
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
    // Chaos: relleno de acento con `onSpeedAccent`. Teclas negras: card
    // `hero` (#2A0640) de v2 con texto `onHero` y el acento claro de
    // velocidad (7,6:1), en lugar del negro de piano.
    final Color onCard = isChaos
        ? speed.onSpeedAccent
        : isDark
        ? DesignTokens.onHero
        : scheme.onSurface;
    final Color onMuted = isChaos || isDark ? onCard : scheme.onSurfaceVariant;
    final Color ctaColor = isChaos || isDark ? onCard : speed.speedAccent;
    final Color iconBg = isChaos || isDark
        ? onCard.withValues(alpha: 0.14)
        : speed.speedContainer;
    final Color iconColor = isChaos
        ? speed.onSpeedAccent
        : isDark
        ? DesignTokens.speedAccentOnDark
        : speed.speedAccent;
    final Color cardColor = isChaos
        ? speed.speedAccent
        : isDark
        ? DesignTokens.hero
        : scheme.surfaceContainerLowest;
    final Color borderColor = isChaos || isDark
        ? cardColor
        : scheme.outlineVariant;

    return Semantics(
      button: true,
      label: title,
      hint: subtitle,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: DesignTokens.borderRadiusCard,
        child: InkWell(
          onTap: onTap,
          borderRadius: DesignTokens.borderRadiusCard,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: DesignTokens.borderRadiusCard,
              color: cardColor,
              border: Border.all(color: borderColor),
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
            borderRadius: DesignTokens.borderRadiusPill,
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
                'Modo velocidad'.toUpperCase(),
                style: DesignTokens.overline.copyWith(
                  color: speed.speedAccent,
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
