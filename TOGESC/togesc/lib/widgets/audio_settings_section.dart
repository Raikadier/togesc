import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_tokens.dart';
import '../models/audio_preferences.dart';
import '../models/instrument_preset.dart';
import '../providers/audio_preferences_provider.dart';
import 'audio_test_button.dart';
import 'togesc_ui.dart';

/// Preferencias de sonido: timbre, volumen y cluster (Fase 7A).
class AudioSettingsSection extends ConsumerWidget {
  const AudioSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioAsync = ref.watch(audioPreferencesProvider);

    return TogescCard(
      child: audioAsync.when(
        data: (prefs) => _AudioSettingsBody(prefs: prefs),
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _AudioSettingsBody extends ConsumerWidget {
  final AudioPreferences prefs;

  const _AudioSettingsBody({required this.prefs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(audioPreferencesProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sonido',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Timbre por defecto',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<InstrumentMode>(
          segments: const [
            ButtonSegment(
              value: InstrumentMode.random,
              label: Text('Aleatorio'),
              icon: Icon(Icons.shuffle_rounded, size: 18),
            ),
            ButtonSegment(
              value: InstrumentMode.fixed,
              label: Text('Fijo'),
              icon: Icon(Icons.piano_rounded, size: 18),
            ),
          ],
          selected: {prefs.instrumentMode},
          onSelectionChanged: (selection) {
            notifier.setInstrumentMode(selection.first);
          },
        ),
        if (prefs.instrumentMode == InstrumentMode.fixed) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: instrumentPresets.keys.map((id) {
              final selected = prefs.fixedInstrumentId == id;
              return FilterChip(
                label: Text(instrumentLabel(id)),
                selected: selected,
                onSelected: (_) => notifier.setFixedInstrument(id),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Volumen (${(prefs.masterVolume * 100).round()}%)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Slider(
          value: prefs.masterVolume,
          onChanged: notifier.setMasterVolume,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Limpieza tonal (cluster)'),
          subtitle: const Text(
            'Sonido breve entre rondas para evitar anclaje tonal.',
          ),
          value: prefs.clusterEnabled,
          onChanged: notifier.setClusterEnabled,
        ),
        if (prefs.clusterEnabled) ...[
          const SizedBox(height: 4),
          Text(
            'Duracion del cluster',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<double>(
            segments: const [
              ButtonSegment(value: 2.0, label: Text('2 s')),
              ButtonSegment(value: 3.0, label: Text('3 s')),
              ButtonSegment(value: 5.0, label: Text('5 s')),
            ],
            selected: {prefs.clusterDurationSec},
            onSelectionChanged: (selection) {
              notifier.setClusterDuration(selection.first);
            },
          ),
        ],
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Variacion de octavas'),
          subtitle: const Text(
            'Las notas pueden sonar una octava arriba o abajo en cada ronda.',
          ),
          value: prefs.octaveVariationEnabled,
          onChanged: notifier.setOctaveVariationEnabled,
        ),
        const SizedBox(height: 4),
        Text(
          'Duracion del tono',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<double>(
          segments: const [
            ButtonSegment(value: 0.5, label: Text('0,5 s')),
            ButtonSegment(value: 1.0, label: Text('1 s')),
            ButtonSegment(value: 1.5, label: Text('1,5 s')),
          ],
          selected: {prefs.toneDurationSec},
          onSelectionChanged: (selection) {
            notifier.setToneDuration(selection.first);
          },
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        const AudioTestButton(),
        const SizedBox(height: DesignTokens.spacingXs),
        Text(
          'Durante el juego puedes cambiar el timbre solo para esa sesion '
          'desde el icono de la barra superior.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
