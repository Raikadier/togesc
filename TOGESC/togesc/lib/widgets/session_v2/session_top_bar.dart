import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../models/audio_preferences.dart';
import '../../providers/audio_preferences_provider.dart';
import '../session_instrument_sheet.dart';

/// Datos de las chips de la sesión: ronda, precisión y racha.
@immutable
class SessionStats {
  /// Ronda que se muestra (la actual o la recién respondida).
  final int round;

  /// Meta de rondas; 0 = sin límite.
  final int targetRounds;

  /// Precisión de la sesión en %; `null` sin rondas jugadas.
  final double? accuracyPercent;
  final int streak;

  const SessionStats({
    required this.round,
    required this.targetRounds,
    required this.accuracyPercent,
    required this.streak,
  });

  String get roundText =>
      targetRounds > 0 ? '$round / $targetRounds' : 'Ronda $round';

  String get roundSemantics => targetRounds > 0
      ? 'Ronda $round de $targetRounds'
      : 'Ronda $round';

  String get accuracyText =>
      accuracyPercent == null ? '—' : '${accuracyPercent!.round()}%';

  String get accuracySemantics => accuracyPercent == null
      ? 'Precisión: sin rondas todavía'
      : 'Precisión ${accuracyPercent!.round()} por ciento';

  /// Progreso 0..1 hacia la meta; `null` sin meta.
  double? get progress =>
      targetRounds > 0 ? (round / targetRounds).clamp(0.0, 1.0) : null;
}

/// Chip oscura de la barra superior («3 / 12», «✓ 78%», «⚡ 4»).
class SessionStatChip extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String text;
  final String semanticsLabel;

  const SessionStatChip({
    super.key,
    required this.text,
    required this.semanticsLabel,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: DesignTokens.sessionChip,
            borderRadius: DesignTokens.borderRadiusPill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 4),
              ],
              Text(
                text,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(
                      color: DesignTokens.sessionTextPrimary,
                      fontWeight: FontWeight.w700,
                    )
                    .merge(DesignTokens.tabularNumbers),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Las tres chips de estado de la sesión.
class SessionStatChips extends StatelessWidget {
  final SessionStats stats;

  /// En escritorio la chip de ronda dice «Ronda 3 / 12».
  final bool verboseRound;

  const SessionStatChips({
    super.key,
    required this.stats,
    this.verboseRound = false,
  });

  @override
  Widget build(BuildContext context) {
    final roundText = verboseRound && stats.targetRounds > 0
        ? 'Ronda ${stats.roundText}'
        : stats.roundText;
    return Wrap(
      spacing: DesignTokens.spacingSm,
      runSpacing: DesignTokens.spacingXs,
      children: [
        SessionStatChip(
          key: const ValueKey('session-chip-round'),
          text: roundText,
          semanticsLabel: stats.roundSemantics,
        ),
        SessionStatChip(
          key: const ValueKey('session-chip-accuracy'),
          icon: Icons.check_rounded,
          iconColor: DesignTokens.sessionSuccess,
          text: stats.accuracyText,
          semanticsLabel: stats.accuracySemantics,
        ),
        SessionStatChip(
          key: const ValueKey('session-chip-streak'),
          icon: Icons.bolt_rounded,
          iconColor: DesignTokens.sessionAmber,
          text: '${stats.streak}',
          semanticsLabel: 'Racha de ${stats.streak} aciertos seguidos',
        ),
      ],
    );
  }
}

/// Barra de progreso de 3 px en el acento de sesión.
class SessionProgressBar extends StatelessWidget {
  final double? progress;

  const SessionProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    if (progress == null) {
      return const SizedBox(height: DesignTokens.sessionProgressBarHeight);
    }
    return Semantics(
      label: 'Progreso de la sesión',
      value: '${(progress! * 100).round()} %',
      child: ClipRRect(
        borderRadius: DesignTokens.borderRadiusPill,
        child: LinearProgressIndicator(
          key: const ValueKey('session-progress'),
          value: progress,
          minHeight: DesignTokens.sessionProgressBarHeight,
          backgroundColor: DesignTokens.sessionChip,
          color: DesignTokens.sessionAccent,
        ),
      ),
    );
  }
}

/// Botón de pausa / reanudar de la barra superior.
class SessionPauseButton extends StatelessWidget {
  final bool isPaused;
  final bool enabled;
  final VoidCallback onPause;
  final VoidCallback onResume;

  /// En escritorio se muestra con texto («Pausar»).
  final bool showLabel;

  const SessionPauseButton({
    super.key,
    required this.isPaused,
    required this.enabled,
    required this.onPause,
    required this.onResume,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = isPaused ? 'Reanudar' : 'Pausar';
    final icon = isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded;
    final onPressed = enabled ? (isPaused ? onResume : onPause) : null;
    if (showLabel) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: sessionSecondaryButtonStyle(),
      );
    }
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(icon),
      color: DesignTokens.sessionTextPrimary,
      disabledColor: DesignTokens.sessionTextSecondary.withValues(alpha: 0.5),
    );
  }
}

/// Estilo del botón secundario de sesión (#1E1622, borde #3A2E42).
ButtonStyle sessionSecondaryButtonStyle() {
  return OutlinedButton.styleFrom(
    minimumSize: const Size(DesignTokens.touchTargetMin,
        DesignTokens.touchTargetMin),
    backgroundColor: DesignTokens.sessionButton,
    foregroundColor: DesignTokens.sessionTextPrimary,
    disabledForegroundColor:
        DesignTokens.sessionTextSecondary.withValues(alpha: 0.6),
    side: const BorderSide(color: DesignTokens.sessionBorder),
    shape: RoundedRectangleBorder(borderRadius: DesignTokens.borderRadiusCta),
  );
}

/// Instrumento de la sesión. En móvil es un icono con tooltip; en
/// escritorio, un botón con el nombre real del instrumento («Piano»).
class SessionInstrumentButton extends ConsumerWidget {
  final String? sessionInstrumentOverride;
  final ValueChanged<String?> onOverrideChanged;
  final bool showLabel;

  const SessionInstrumentButton({
    super.key,
    required this.sessionInstrumentOverride,
    required this.onOverrideChanged,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(audioPreferencesProvider).valueOrNull ??
        const AudioPreferences();
    final summary = sessionInstrumentSummary(
      prefs: prefs,
      sessionOverrideKey: sessionInstrumentOverride,
    );
    void open() {
      showSessionInstrumentSheet(
        context: context,
        sessionOverrideKey: sessionInstrumentOverride,
        onSelected: onOverrideChanged,
      );
    }

    if (showLabel) {
      final id = prefs.playbackInstrument(
        sessionOverrideKey: sessionInstrumentOverride,
      );
      return Tooltip(
        message: summary,
        child: OutlinedButton.icon(
          onPressed: open,
          icon: const Icon(Icons.music_note_rounded),
          label: Text(id == null ? 'Aleatorio' : instrumentLabel(id)),
          style: sessionSecondaryButtonStyle(),
        ),
      );
    }
    return IconButton(
      tooltip: summary,
      onPressed: open,
      icon: const Icon(Icons.music_note_rounded),
      color: DesignTokens.sessionTextPrimary,
    );
  }
}

/// Barra superior móvil (1b): volver, chips, instrumento y pausa.
class SessionTopBar extends StatelessWidget {
  final SessionStats stats;
  final VoidCallback onBack;
  final Widget instrumentButton;
  final Widget pauseButton;

  const SessionTopBar({
    super.key,
    required this.stats,
    required this.onBack,
    required this.instrumentButton,
    required this.pauseButton,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DesignTokens.appBarHeight,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: DesignTokens.sessionTextPrimary,
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SessionStatChips(stats: stats),
            ),
          ),
          instrumentButton,
          pauseButton,
        ],
      ),
    );
  }
}

/// Cabecera de escritorio (1d): modo, chips, «Piano» y «Pausar».
class SessionDesktopHeader extends StatelessWidget {
  final String modeName;
  final SessionStats stats;
  final VoidCallback onBack;
  final Widget instrumentButton;
  final Widget pauseButton;

  const SessionDesktopHeader({
    super.key,
    required this.modeName,
    required this.stats,
    required this.onBack,
    required this.instrumentButton,
    required this.pauseButton,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Volver',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          color: DesignTokens.sessionTextPrimary,
        ),
        const SizedBox(width: DesignTokens.spacingSm),
        Flexible(
          child: Text(
            modeName,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: DesignTokens.sessionTextPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        const SizedBox(width: DesignTokens.spacingLg),
        SessionStatChips(stats: stats, verboseRound: true),
        const Spacer(),
        instrumentButton,
        const SizedBox(width: DesignTokens.spacingSm),
        pauseButton,
      ],
    );
  }
}
