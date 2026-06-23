import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_tokens.dart';
import '../models/practice_session_preferences.dart';
import '../providers/practice_session_preferences_provider.dart';
import 'togesc_ui.dart';

/// Objetivo de sesion y auto-avance (Fase 7B).
class SessionSettingsSection extends ConsumerWidget {
  const SessionSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(practiceSessionPreferencesProvider);

    return TogescCard(
      child: prefsAsync.when(
        data: (prefs) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sesion de practica',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Objetivo de rondas',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: DesignTokens.spacingSm,
              runSpacing: DesignTokens.spacingSm,
              children: SessionRoundGoal.values.map((goal) {
                final selected = prefs.roundGoal == goal;
                return ChoiceChip(
                  label: Text(goal.label),
                  selected: selected,
                  onSelected: (_) {
                    ref
                        .read(practiceSessionPreferencesProvider.notifier)
                        .setRoundGoal(goal);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Continuar automaticamente'),
              subtitle: const Text(
                'Tras cada resultado, pasa al cluster y a la siguiente ronda sin pulsar Siguiente.',
              ),
              value: prefs.autoAdvanceAfterResult,
              onChanged: (value) {
                ref
                    .read(practiceSessionPreferencesProvider.notifier)
                    .setAutoAdvanceAfterResult(value);
              },
            ),
          ],
        ),
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }
}
