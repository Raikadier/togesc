import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_tokens.dart';
import '../models/ui_preferences.dart';
import '../providers/ui_preferences_provider.dart';
import 'togesc_ui.dart';

/// Tema claro / oscuro / sistema (Fase 7D-3).
class AppearanceSettingsSection extends ConsumerWidget {
  const AppearanceSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(uiPreferencesProvider);

    return TogescCard(
      child: prefsAsync.when(
        data: (prefs) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Apariencia',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tema de la app',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: DesignTokens.spacingSm,
              runSpacing: DesignTokens.spacingSm,
              children: AppThemePreference.values.map((option) {
                return ChoiceChip(
                  label: Text(option.label),
                  selected: prefs.themePreference == option,
                  onSelected: (_) {
                    ref
                        .read(uiPreferencesProvider.notifier)
                        .setThemePreference(option);
                  },
                );
              }).toList(),
            ),
          ],
        ),
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }
}
