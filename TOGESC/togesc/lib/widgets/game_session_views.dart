import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_tokens.dart';
import '../models/audio_preferences.dart';
import '../providers/audio_preferences_provider.dart';
import 'session_instrument_sheet.dart';

/// Layout centrado para fases idle, listening y cluster.
class GameSessionPhaseLayout extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? footer;
  final bool showProgress;
  final Color? accentColor;

  const GameSessionPhaseLayout({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.footer,
    this.showProgress = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? DesignTokens.primaryContainer;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.marginMobile,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.25),
                ),
              ),
              child: Icon(
                icon,
                size: 48,
                color: color,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingLg),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: DesignTokens.spacingSm),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (showProgress) ...[
              const SizedBox(height: DesignTokens.spacingLg),
              SizedBox(
                width: 32,
                height: 32,
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

/// Vista idle — preparación antes de escuchar.
class GameSessionIdleView extends StatelessWidget {
  final VoidCallback onPlay;

  const GameSessionIdleView({super.key, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return GameSessionPhaseLayout(
      icon: Icons.headphones_rounded,
      title: 'Preparate para escuchar',
      footer: FilledButton.icon(
        onPressed: onPlay,
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
      icon: Icons.graphic_eq_rounded,
      title: 'Escucha atentamente... ($numNotes nota(s))',
      subtitle: 'Concentrate en cada altura',
      showProgress: true,
    );
  }
}

/// Vista cluster — limpieza tonal post-ronda.
class GameSessionClusterView extends StatelessWidget {
  const GameSessionClusterView({super.key});

  @override
  Widget build(BuildContext context) {
    return const GameSessionPhaseLayout(
      icon: Icons.waves_rounded,
      title: 'Limpiando el oido...',
      subtitle: 'Transicion tonal breve',
      showProgress: true,
    );
  }
}

/// Encabezado de la fase de respuesta.
class GameSessionAnswerHeader extends StatelessWidget {
  final int numNotes;

  const GameSessionAnswerHeader({super.key, required this.numNotes});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Que nota(s) escuchaste? ($numNotes)',
      style: Theme.of(context).textTheme.titleLarge,
      textAlign: TextAlign.center,
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
