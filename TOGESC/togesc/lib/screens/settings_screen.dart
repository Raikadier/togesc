import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_tokens.dart';
import '../widgets/practice_settings_section.dart';
import '../widgets/togesc_ui.dart';

/// Ajustes de práctica, sonido, apariencia y accesibilidad (Fase 7D).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TogescScaffold(
      title: 'Ajustes',
      body: ListView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width >= DesignTokens.shellBreakpoint
              ? DesignTokens.marginDesktop
              : DesignTokens.marginMobile,
        ),
        children: [
          Text(
            'Configura la práctica',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          const PracticeSettingsSection(),
        ],
      ),
    );
  }
}
