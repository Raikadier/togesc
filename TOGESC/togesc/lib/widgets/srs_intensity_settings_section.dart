import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/srs_intensity_profile.dart';
import '../providers/srs_intensity_provider.dart';
import 'togesc_ui.dart';

/// Selector de intensidad del algoritmo SRS (Fase 7E-2).
class SrsIntensitySettingsSection extends ConsumerWidget {
  const SrsIntensitySettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(srsIntensityProfileProvider);

    return TogescCard(
      child: profileAsync.when(
        data: (selected) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Intensidad SRS',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Ajusta la frecuencia de repaso entre sesiones.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            RadioGroup<SrsIntensityProfile>(
              groupValue: selected,
              onChanged: (value) {
                if (value == null) return;
                ref.read(srsIntensityProfileProvider.notifier).setProfile(value);
              },
              child: Column(
                children: [
                  for (final profile in SrsIntensityProfile.values)
                    RadioListTile<SrsIntensityProfile>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(profile.label),
                      subtitle: Text(profile.description),
                      value: profile,
                    ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }
}
