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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final usePulse = pulsingIcon && !reduceMotion;
    final iconFill = iconGradient == null
        ? BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.35)),
          )
        : BoxDecoration(
            gradient: iconGradient,
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.35)),
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
                    fontWeight: FontWeight.w600,
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
                  if (usePulse) ...[
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
                    decoration: iconFill,
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
            if (showProgress && !reduceMotion) ...[
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
