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
              'Práctica y accesibilidad',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            Text(
              'Modo de respuesta',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            RadioGroup<GameInputMode>(
              groupValue: prefs.inputMode,
              onChanged: (value) {
                if (value == null) return;
                ref.read(uiPreferencesProvider.notifier).setInputMode(value);
              },
              child: Column(
                children: [
                  for (final mode in GameInputMode.values)
                    RadioListTile<GameInputMode>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(mode.label),
                      subtitle: Text(mode.description),
                      value: mode,
                    ),
                ],
              ),
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Confirmar antes de enviar'),
              subtitle: const Text(
                'Si está desactivado, al completar la selección en el piano se envía la respuesta al instante.',
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
              title: const Text('Piano más grande'),
              subtitle: const Text('Teclas más amplias para facilitar el toque.'),
              value: prefs.largePiano,
              onChanged: (value) {
                ref.read(uiPreferencesProvider.notifier).setLargePiano(value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reducir animaciones'),
              subtitle: const Text(
                'Desactiva el movimiento de la interfaz y acorta esperas entre rondas.',
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
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }
}
