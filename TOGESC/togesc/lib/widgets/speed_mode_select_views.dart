import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../app/togesc_colors.dart';
import '../constants/game_constants.dart';
import 'togesc_ui.dart';

/// Segundos con coma decimal y sin ceros sobrantes: «3 s», «1,5 s».
String formatSpeedSeconds(double seconds, {int decimals = 1}) {
  final fixed = seconds.toStringAsFixed(decimals);
  final trimmed = fixed.contains('.')
      ? fixed.replaceFirst(RegExp(r'\.?0+$'), '')
      : fixed;
  return '${trimmed.replaceAll('.', ',')} s';
}

/// Cabecera del selector de velocidad (v2.1, SPEC §2.4.1).
class SpeedModeSelectHero extends StatelessWidget {
  const SpeedModeSelectHero({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final speed = TogescColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Row(
            children: [
              Icon(Icons.bolt_rounded, size: 32, color: speed.speedAccent),
              const SizedBox(width: DesignTokens.spacingSm),
              Expanded(
                child: Text(
                  'Modo velocidad',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        Text(
          'Elige un desafío de ráfagas. El tiempo límite baja con cada acierto.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Descripción corta de cada dificultad (tarjetas radio).
String speedDifficultyDescription(SpeedDifficulty d) => switch (d) {
  SpeedDifficulty.easy => 'Para calentar el oído',
  SpeedDifficulty.pro => 'Ritmo de práctica habitual',
  SpeedDifficulty.elite => 'Reconocimiento inmediato',
};

/// Tarjetas radio Fácil / Pro / Elite con su tiempo inicial y la mejor
/// racha guardada (SPEC §2.4.1). Una dificultad sin ráfagas muestra «—».
class SpeedDifficultySelector extends StatelessWidget {
  final SpeedDifficulty selected;
  final ValueChanged<SpeedDifficulty> onChanged;
  final Map<SpeedDifficulty, int> bestStreaks;

  const SpeedDifficultySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.bestStreaks = const {},
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Tiempo inicial'.toUpperCase(),
            style: DesignTokens.overline.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        for (final level in SpeedDifficulty.values) ...[
          if (level != SpeedDifficulty.values.first)
            const SizedBox(height: DesignTokens.spacingSm + 2),
          SpeedDifficultyCard(
            difficulty: level,
            best: bestStreaks[level],
            selected: selected == level,
            onTap: () => onChanged(level),
          ),
        ],
      ],
    );
  }
}

/// Tarjeta radio de una dificultad: cuadro de segundos, nombre, descripción
/// y mejor racha. La selección se marca con borde, fondo, cuadro relleno e
/// icono de check (el color nunca es la única señal).
class SpeedDifficultyCard extends StatelessWidget {
  final SpeedDifficulty difficulty;
  final int? best;
  final bool selected;
  final VoidCallback onTap;

  const SpeedDifficultyCard({
    super.key,
    required this.difficulty,
    required this.best,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final speed = TogescColors.of(context);
    final seconds = difficulty.initialTime.toStringAsFixed(0);
    final bestText = best == null ? '—' : '$best';
    final duration = motionDuration(context, DesignTokens.motionFast);

    return Semantics(
      key: ValueKey('speed-diff-${difficulty.name}'),
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label:
          '${difficulty.label}, $seconds segundos. '
          '${speedDifficultyDescription(difficulty)}. '
          'Mejor racha: ${best == null ? 'sin datos' : '$best'}',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: DesignTokens.borderRadiusCard,
          child: AnimatedContainer(
            duration: duration,
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            decoration: BoxDecoration(
              color: selected
                  ? speed.speedContainer
                  : scheme.surfaceContainerLowest,
              borderRadius: DesignTokens.borderRadiusCard,
              border: Border.all(
                color: selected ? speed.speedAccent : scheme.outlineVariant,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: duration,
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? speed.speedAccent
                        : scheme.surfaceContainerHigh,
                    borderRadius: DesignTokens.borderRadiusMd,
                  ),
                  child: Text(
                    '${seconds}s',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: selected
                              ? speed.onSpeedAccent
                              : speed.speedAccent,
                        )
                        .merge(DesignTokens.tabularNumbers),
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        difficulty.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        speedDifficultyDescription(difficulty),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingSm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Mejor racha',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      bestText,
                      key: ValueKey('speed-best-${difficulty.name}'),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          )
                          .merge(DesignTokens.tabularNumbers),
                    ),
                  ],
                ),
                const SizedBox(width: DesignTokens.spacingSm),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? speed.speedAccent : scheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card «Cómo funciona» con 3 pasos numerados (SPEC §2.4.1). El copy
/// describe las reglas ACTUALES de `speed_session_provider` (§2.4.4).
class SpeedHowItWorksCard extends StatelessWidget {
  const SpeedHowItWorksCard({super.key});

  static List<String> get steps => [
    'Suena una ráfaga. Respóndela en el piano o escribiendo las notas '
        'antes de que se acabe el tiempo.',
    'Cada acierto reduce el tiempo límite '
        '${formatSpeedSeconds(speedCorrectDecrease)}, hasta un mínimo de '
        '${formatSpeedSeconds(speedMinTime)}.',
    'Un fallo o un tiempo agotado cierra la ráfaga. '
        'Mantén la concentración.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final speed = TogescColors.of(context);

    return TogescCard(
      key: const ValueKey('speed-how'),
      color: scheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Cómo funciona'.toUpperCase(),
              style: DesignTokens.overline.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          for (final (i, step) in steps.indexed) ...[
            if (i > 0) const SizedBox(height: DesignTokens.spacingMd),
            Semantics(
              label: 'Paso ${i + 1}: $step',
              excludeSemantics: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: speed.speedContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: speed.speedAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingMd),
                  Expanded(
                    child: Text(
                      step,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
