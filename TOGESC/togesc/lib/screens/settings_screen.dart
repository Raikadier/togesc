import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../widgets/settings_groups.dart';
import '../widgets/togesc_ui.dart';

/// Ajustes v2.1 (SPEC §2.8): 5 grupos con la accesibilidad primero. En
/// escritorio van en 2 columnas.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Ancho de contenido a partir del cual los grupos van en 2 columnas.
  static const double twoColumnBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: DesignTokens.spacingMd);
    const left = [SettingsAccessibilityGroup(), gap, SettingsSessionGroup()];
    const right = [
      SettingsSoundGroup(),
      gap,
      SettingsAppearanceGroup(),
      gap,
      SettingsMoreGroup(),
    ];

    return TogescScaffold(
      title: 'Ajustes',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= twoColumnBreakpoint;
          final margin = constraints.maxWidth >= DesignTokens.shellBreakpoint
              ? DesignTokens.marginDesktop
              : DesignTokens.marginMobile;
          final intro = Text(
            'Configura la práctica. Los cambios se guardan al momento en este '
            'dispositivo.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
          return ListView(
            padding: EdgeInsets.all(margin),
            children: [
              intro,
              const SizedBox(height: DesignTokens.spacingLg),
              if (wide)
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Column(children: left)),
                    SizedBox(width: DesignTokens.spacingLg),
                    Expanded(child: Column(children: right)),
                  ],
                )
              else
                const Column(children: [...left, gap, ...right]),
            ],
          );
        },
      ),
    );
  }
}
