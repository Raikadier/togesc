import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../app/togesc_colors.dart';
import '../constants/game_constants.dart';
import 'togesc_ui.dart';

/// Hero del selector de modo velocidad (Stitch).
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
        Text(
          'Modo velocidad',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        Text(
          'Elige un desafío de ráfagas. El tiempo límite baja con cada acierto.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingLg),
        TogescCard(
          color: scheme.surfaceContainerLowest,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: speed.speedContainer,
                  borderRadius: DesignTokens.borderRadiusMd,
                  border: Border.all(
                    color: speed.speedAccent.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  Icons.timer_outlined,
                  color: speed.speedAccent,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cómo funciona',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: speed.speedAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingXs),
                    Text(
                      'El tiempo límite disminuye con cada respuesta correcta. '
                      'Mantén la concentración.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Selector Fácil / Pro / Elite (tiempo inicial).
class SpeedDifficultySelector extends StatelessWidget {
  final SpeedDifficulty selected;
  final ValueChanged<SpeedDifficulty> onChanged;

  const SpeedDifficultySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  IconData _iconFor(SpeedDifficulty d) => switch (d) {
    SpeedDifficulty.easy => Icons.timer_outlined,
    SpeedDifficulty.pro => Icons.timer_10_outlined,
    SpeedDifficulty.elite => Icons.bolt_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final speed = TogescColors.of(context);

    return Column(
      children: [
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 48),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.outlineVariant.withValues(alpha: 0),
                scheme.outlineVariant,
                scheme.outlineVariant.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingLg),
        Text(
          'Tiempo inicial',
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final level in SpeedDifficulty.values) ...[
              if (level != SpeedDifficulty.values.first)
                const SizedBox(width: DesignTokens.spacingLg),
              _DifficultyChip(
                label: level.label,
                subtitle: '${level.initialTime.toStringAsFixed(0)}s',
                icon: _iconFor(level),
                selected: selected == level,
                accent: speed.speedAccent,
                onTap: () => onChanged(level),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _DifficultyChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $subtitle',
      child: Material(
        color: selected
            ? accent.withValues(alpha: 0.12)
            : scheme.surfaceContainerLowest,
        borderRadius: DesignTokens.borderRadiusXl,
        child: InkWell(
          onTap: onTap,
          borderRadius: DesignTokens.borderRadiusXl,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: DesignTokens.touchTargetMin,
              minHeight: DesignTokens.touchTargetMin,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMd,
                vertical: DesignTokens.spacingSm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: selected ? accent : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: DesignTokens.spacingXs),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? accent : scheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
