import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_tokens.dart';
import '../models/ui_preferences.dart';
import '../providers/ui_preferences_provider.dart';
import 'togesc_ui.dart';

/// Entrada de respuesta, confirmacion y accesibilidad del piano (Fase 7D-2/4).
class GameplaySettingsSection extends ConsumerWidget {
  const GameplaySettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(uiPreferencesProvider);

    return TogescCard(
      child: prefsAsync.when(
        data: (prefs) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Juego y accesibilidad',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Modo de respuesta',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            ...GameInputMode.values.map((mode) {
              return RadioListTile<GameInputMode>(
                contentPadding: EdgeInsets.zero,
                title: Text(mode.label),
                subtitle: Text(mode.description),
                value: mode,
                groupValue: prefs.inputMode,
                onChanged: (value) {
                  if (value == null) return;
                  ref.read(uiPreferencesProvider.notifier).setInputMode(value);
                },
              );
            }),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Confirmar antes de enviar'),
              subtitle: const Text(
                'Si esta desactivado, al completar la seleccion en el piano se envia la respuesta al instante.',
              ),
              value: prefs.confirmBeforeSubmit,
              onChanged: (value) {
                ref
                    .read(uiPreferencesProvider.notifier)
                    .setConfirmBeforeSubmit(value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ocultar etiquetas del piano'),
              subtitle: const Text('Entrena sin ver los nombres en las teclas.'),
              value: prefs.hidePianoLabels,
              onChanged: (value) {
                ref
                    .read(uiPreferencesProvider.notifier)
                    .setHidePianoLabels(value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Piano mas grande'),
              subtitle: const Text('Teclas mas amplias para facilitar el toque.'),
              value: prefs.largePiano,
              onChanged: (value) {
                ref.read(uiPreferencesProvider.notifier).setLargePiano(value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reducir animaciones'),
              subtitle: const Text(
                'Transiciones mas rapidas y menos espera entre rondas.',
              ),
              value: prefs.reduceAnimations,
              onChanged: (value) {
                ref
                    .read(uiPreferencesProvider.notifier)
                    .setReduceAnimations(value);
              },
            ),
          ],
        ),
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
