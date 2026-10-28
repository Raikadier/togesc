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

/// Cuenta atrás 3-2-1 antes de la primera ráfaga (SPEC §2.4.2). Cada cifra
/// entra con un pop (escala con rebote); con movimiento reducido aparece
/// sin animar.
class SpeedCountdownView extends StatelessWidget {
  final int value;
  final String difficultyLabel;

  const SpeedCountdownView({
    super.key,
    required this.value,
    required this.difficultyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = TogescColors.of(context);
    final duration = motionDuration(context, const Duration(milliseconds: 600));

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Listo para el desafío'.toUpperCase(),
            style: DesignTokens.overline.copyWith(color: colors.speedAccent),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          Semantics(
            liveRegion: true,
            label: '$value',
            excludeSemantics: true,
            child: _Pop(
              key: ValueKey('speed-countdown-$value'),
              duration: duration,
              child: Text(
                '$value',
                key: const ValueKey('speed-countdown'),
                style: theme.textTheme.displayLarge
                    ?.copyWith(
                      fontSize: 96,
                      fontWeight: FontWeight.w800,
                      color: colors.speedAccent,
                    )
                    .merge(DesignTokens.tabularNumbers),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          Text(
            'Empieza ahora · $difficultyLabel',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Entrada con pop: escala de 0,4 a 1 con rebote y fundido.
class _Pop extends StatelessWidget {
  final Duration duration;
  final Widget child;

  const _Pop({super.key, required this.duration, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: duration == Duration.zero ? 1 : 0, end: 1),
      duration: duration,
      curve: DesignTokens.easeSpring,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.4 + 0.6 * t, child: child),
      ),
      child: child,
    );
  }
}

/// Píldora «Nuevo récord personal» del resumen (SPEC §2.4.3).
class SpeedRecordPill extends StatelessWidget {
  const SpeedRecordPill({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = TogescColors.of(context);

    return _Pop(
      duration: motionDuration(context, const Duration(milliseconds: 500)),
      child: Container(
        key: const ValueKey('speed-new-record'),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd),
        decoration: BoxDecoration(
          color: colors.speedAccent,
          borderRadius: DesignTokens.borderRadiusPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              size: 18,
              color: colors.onSpeedAccent,
            ),
            const SizedBox(width: DesignTokens.spacingXs + 2),
            Text(
              'Nuevo récord personal',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.onSpeedAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// KPI del resumen de velocidad (SPEC §2.4.3): Racha final, Mejor tiempo,
/// Promedio y Respuestas (aciertos / rondas). Sin respuestas, los tiempos
/// muestran «—».
class SpeedSessionSummaryCard extends StatelessWidget {
  final int streak;
  final double bestTime;
  final double averageTime;
  final int correctRounds;
  final int roundsPlayed;

  const SpeedSessionSummaryCard({
    super.key,
    required this.streak,
    required this.bestTime,
    required this.averageTime,
    required this.correctRounds,
    required this.roundsPlayed,
  });

  static String _time(double s) =>
      s > 0 ? '${s.toStringAsFixed(2).replaceAll('.', ',')} s' : '—';

  @override
  Widget build(BuildContext context) {
    final kpis = [
      ('streak', 'Racha final', '$streak'),
      ('best', 'Mejor tiempo', _time(bestTime)),
      ('average', 'Promedio', _time(averageTime)),
      ('answers', 'Respuestas', '$correctRounds/$roundsPlayed'),
    ];
    return LayoutBuilder(
      key: const ValueKey('speed-result-kpis'),
      builder: (context, constraints) {
        const gap = DesignTokens.spacingSm;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (id, label, value) in kpis)
              SizedBox(
                width: width,
                child: _Kpi(id: id, label: label, value: value),
              ),
          ],
        );
      },
    );
  }
}

class _Kpi extends StatelessWidget {
  final String id;
  final String label;
  final String value;

  const _Kpi({required this.id, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: DesignTokens.borderRadiusCard,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                key: ValueKey('speed-kpi-$id'),
                style: theme.textTheme.headlineMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    )
                    .merge(DesignTokens.tabularNumbers),
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Resumen al cerrar la ráfaga (fallo o tiempo agotado): motivo, píldora de
/// récord, KPI y acciones.
class SpeedSessionResultView extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final bool newRecord;
  final Widget summary;
  final VoidCallback onRetry;
  final VoidCallback onMenu;

  const SpeedSessionResultView({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.newRecord,
    required this.summary,
    required this.onRetry,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Fin de sesión'.toUpperCase(),
                textAlign: TextAlign.center,
                style: DesignTokens.overline.copyWith(
                  color: TogescColors.of(context).speedAccent,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingMd),
              Icon(icon, size: 48, color: accentColor),
              const SizedBox(height: DesignTokens.spacingSm),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingXs),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (newRecord) ...[
                const SizedBox(height: DesignTokens.spacingMd),
                const Center(child: SpeedRecordPill()),
              ],
              const SizedBox(height: DesignTokens.spacingLg),
              summary,
              const SizedBox(height: DesignTokens.spacingLg),
              SpeedSessionRetryActions(onRetry: onRetry, onMenu: onMenu),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botones «Reintentar» (relleno de acento de velocidad, #FF8A65 con texto
/// #2A0640 en la sesión) y «Menú».
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
    final colors = TogescColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: const ValueKey('speed-retry'),
          onPressed: onRetry,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(DesignTokens.touchTargetMin),
            backgroundColor: colors.speedAccent,
            foregroundColor: colors.onSpeedAccent,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(
              borderRadius: DesignTokens.borderRadiusCta,
            ),
          ),
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Reintentar'),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        OutlinedButton.icon(
          key: const ValueKey('speed-menu'),
          onPressed: onMenu,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(DesignTokens.touchTargetMin),
          ),
          icon: const Icon(Icons.home_rounded),
          label: const Text('Menú'),
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
                style: DesignTokens.overline.copyWith(color: speed.speedAccent),
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
