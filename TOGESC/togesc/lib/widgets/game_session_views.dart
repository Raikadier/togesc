import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_tokens.dart';
import '../models/audio_preferences.dart';
import '../providers/audio_preferences_provider.dart';
import 'session_instrument_sheet.dart';

/// Layout centrado para fases idle, listening y cluster (Stitch premium).
class GameSessionPhaseLayout extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? footer;
  final bool showProgress;
  final Color? accentColor;
  final String? badge;
  final LinearGradient? iconGradient;
  final bool pulsingIcon;

  const GameSessionPhaseLayout({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.footer,
    this.showProgress = false,
    this.accentColor,
    this.badge,
    this.iconGradient,
    this.pulsingIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = accentColor ?? scheme.primaryContainer;
    final gradient = iconGradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.06),
          ],
        );

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.marginMobile,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingMd,
                  vertical: DesignTokens.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Text(
                  badge!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingLg),
            ],
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (pulsingIcon) ...[
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: 0.15),
                          width: 2,
                        ),
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.06),
                      ),
                    ),
                  ],
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.25)),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 44, color: color),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spacingLg),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: DesignTokens.spacingSm),
              Text(
                subtitle!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (showProgress) ...[
              const SizedBox(height: DesignTokens.spacingLg),
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: color,
                ),
              ),
            ],
            if (footer != null) ...[
              const SizedBox(height: DesignTokens.spacingLg * 1.5),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Progreso hacia el objetivo de rondas de la sesion.
class GameSessionProgressBar extends StatelessWidget {
  final int roundsCompleted;
  final int targetRounds;

  const GameSessionProgressBar({
    super.key,
    required this.roundsCompleted,
    required this.targetRounds,
  });

  @override
  Widget build(BuildContext context) {
    if (targetRounds <= 0) return const SizedBox.shrink();

    final progress = (roundsCompleted / targetRounds).clamp(0.0, 1.0);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ronda $roundsCompleted de $targetRounds',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        ClipRRect(
          borderRadius: DesignTokens.borderRadiusMd,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: scheme.primary.withValues(alpha: 0.12),
            color: scheme.primaryContainer,
          ),
        ),
      ],
    );
  }
}

/// Controles de pausa y saltar nota durante la ronda.
class GameSessionRoundControls extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSkip;
  final bool showPause;

  const GameSessionRoundControls({
    super.key,
    required this.isPaused,
    required this.onPause,
    required this.onResume,
    required this.onSkip,
    this.showPause = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showPause) {
      return OutlinedButton.icon(
        onPressed: onSkip,
        icon: const Icon(Icons.skip_next_rounded),
        label: const Text('Saltar nota'),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isPaused ? onResume : onPause,
            icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
            label: Text(isPaused ? 'Reanudar' : 'Pausar'),
          ),
        ),
        const SizedBox(width: DesignTokens.spacingMd),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSkip,
            icon: const Icon(Icons.skip_next_rounded),
            label: const Text('Saltar nota'),
          ),
        ),
      ],
    );
  }
}

/// Overlay cuando la sesion esta pausada.
class GameSessionPausedOverlay extends StatelessWidget {
  final VoidCallback onResume;

  const GameSessionPausedOverlay({super.key, required this.onResume});

  @override
  Widget build(BuildContext context) {
    return GameSessionPhaseLayout(
      icon: Icons.pause_circle_outline_rounded,
      title: 'Sesion pausada',
      subtitle: 'El tiempo de respuesta esta detenido',
      footer: FilledButton.icon(
        onPressed: onResume,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Reanudar'),
      ),
    );
  }
}

/// Banner al completar el objetivo de rondas.
class GameSessionGoalCompleteBanner extends StatelessWidget {
  final int targetRounds;

  const GameSessionGoalCompleteBanner({
    super.key,
    required this.targetRounds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      decoration: BoxDecoration(
        color: DesignTokens.correct.withValues(alpha: 0.12),
        borderRadius: DesignTokens.borderRadiusMd,
        border: Border.all(color: DesignTokens.correct.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: DesignTokens.correct),
          const SizedBox(width: DesignTokens.spacingMd),
          Expanded(
            child: Text(
              'Objetivo cumplido: $targetRounds rondas',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: DesignTokens.correct,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vista idle — preparación antes de escuchar.
class GameSessionIdleView extends StatelessWidget {
  final VoidCallback onPlay;

  const GameSessionIdleView({super.key, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return GameSessionPhaseLayout(
      badge: 'ENTRENAMIENTO DE OIDO',
      icon: Icons.headphones_rounded,
      title: 'Preparate para escuchar',
      subtitle: 'Pulsa reproducir cuando estes listo',
      footer: FilledButton.icon(
        onPressed: onPlay,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(DesignTokens.touchTargetMin),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusXl,
          ),
        ),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Reproducir'),
      ),
    );
  }
}

/// Vista listening — audio en reproducción.
class GameSessionListeningView extends StatelessWidget {
  final int numNotes;

  const GameSessionListeningView({super.key, required this.numNotes});

  @override
  Widget build(BuildContext context) {
    return GameSessionPhaseLayout(
      badge: 'ESCUCHANDO',
      icon: Icons.graphic_eq_rounded,
      title: 'Escucha atentamente',
      subtitle: '$numNotes nota(s) — concentrate en cada altura',
      showProgress: true,
      pulsingIcon: true,
    );
  }
}

/// Vista cluster — limpieza tonal post-ronda.
class GameSessionClusterView extends StatelessWidget {
  const GameSessionClusterView({super.key});

  @override
  Widget build(BuildContext context) {
    return GameSessionPhaseLayout(
      badge: 'LIMPIEZA TONAL',
      icon: Icons.waves_rounded,
      accentColor: DesignTokens.tertiary,
      title: 'Limpiando el oido...',
      subtitle: 'Transicion tonal breve para romper el anclaje',
      showProgress: true,
      pulsingIcon: true,
    );
  }
}

/// Etiqueta de seccion en vista de resultado (Stitch).
class GameSessionResultSectionLabel extends StatelessWidget {
  final String label;

  const GameSessionResultSectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingMd),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: DesignTokens.spacingSm),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.outline,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// Encabezado de la fase de respuesta (Stitch).
class GameSessionAnswerHeader extends StatelessWidget {
  final int numNotes;

  const GameSessionAnswerHeader({super.key, required this.numNotes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMd,
            vertical: DesignTokens.spacingSm,
          ),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hearing_rounded,
                size: 18,
                color: scheme.onSecondaryContainer,
              ),
              const SizedBox(width: DesignTokens.spacingSm),
              Text(
                'ENTRENAMIENTO DE OIDO',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSecondaryContainer,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        Text(
          numNotes == 1
              ? 'Que nota escuchaste?'
              : 'Que nota(s) escuchaste?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Chips de seleccion encima del piano.
class GameSelectionChips extends StatelessWidget {
  final Set<String> selectedNotes;
  final ValueChanged<String>? onRemove;

  const GameSelectionChips({
    super.key,
    required this.selectedNotes,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (selectedNotes.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingLg,
          vertical: DesignTokens.spacingSm,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          'Esperando respuesta...',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
        ),
      );
    }

    return Wrap(
      spacing: DesignTokens.spacingSm,
      runSpacing: DesignTokens.spacingSm,
      alignment: WrapAlignment.center,
      children: selectedNotes.map((note) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingLg,
            vertical: DesignTokens.spacingSm,
          ),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                note,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: DesignTokens.spacingXs),
                InkWell(
                  onTap: () => onRemove!(note),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Acción AppBar: elegir timbre de la sesion (override temporal).
class GameInstrumentToggleAction extends ConsumerWidget {
  final String? sessionInstrumentOverride;
  final ValueChanged<String?> onOverrideChanged;

  const GameInstrumentToggleAction({
    super.key,
    required this.sessionInstrumentOverride,
    required this.onOverrideChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(audioPreferencesProvider).valueOrNull ??
        const AudioPreferences();
    final summary = sessionInstrumentSummary(
      prefs: prefs,
      sessionOverrideKey: sessionInstrumentOverride,
    );

    return IconButton(
      icon: const Icon(Icons.music_note_rounded),
      tooltip: summary,
      onPressed: () {
        showSessionInstrumentSheet(
          context: context,
          sessionOverrideKey: sessionInstrumentOverride,
          onSelected: onOverrideChanged,
        );
      },
    );
  }
}
