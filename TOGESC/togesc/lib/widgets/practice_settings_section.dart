import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/note_naming.dart';
import '../providers/app_preferences_provider.dart';
import '../services/practice_reminder_service.dart';
import 'audio_settings_section.dart';
import 'appearance_settings_section.dart';
import 'gameplay_settings_section.dart';
import 'note_pool_settings_section.dart';
import 'session_settings_section.dart';
import 'srs_intensity_settings_section.dart';
import 'togesc_ui.dart';

/// Preferencias de practica: solfeo y recordatorios (Fase 6).
class PracticeSettingsSection extends ConsumerWidget {
  const PracticeSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final namingAsync = ref.watch(noteNamingModeProvider);
    final remindersAsync = ref.watch(practiceRemindersEnabledProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppearanceSettingsSection(),
        const SizedBox(height: 16),
        const GameplaySettingsSection(),
        const SizedBox(height: 16),
        const AudioSettingsSection(),
        const SizedBox(height: 16),
        const SessionSettingsSection(),
        const SizedBox(height: 16),
        const NotePoolSettingsSection(),
        const SizedBox(height: 16),
        const SrsIntensitySettingsSection(),
        const SizedBox(height: 16),
        TogescCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Preferencias de practica',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              namingAsync.when(
              data: (mode) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notacion Do/Re/Mi'),
                subtitle: const Text(
                  'Muestra solfeo en el piano y acepta respuestas en solfeo.',
                ),
                value: mode == NoteNamingMode.solfege,
                onChanged: (value) {
                  ref.read(noteNamingModeProvider.notifier).setMode(
                        value ? NoteNamingMode.solfege : NoteNamingMode.letter,
                      );
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            remindersAsync.when(
              data: (enabled) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recordatorios de repaso'),
                subtitle: Text(
                  PracticeReminderService.isSupported
                      ? 'Notificacion local si tienes notas vencidas.'
                      : 'Disponible en Android e iOS.',
                ),
                value: enabled && PracticeReminderService.isSupported,
                onChanged: PracticeReminderService.isSupported
                    ? (value) async {
                        await ref
                            .read(practiceRemindersEnabledProvider.notifier)
                            .setEnabled(value);
                        if (value) {
                          await PracticeReminderService.instance
                              .requestPermission();
                        } else {
                          await PracticeReminderService.instance.cancel();
                        }
                      }
                    : null,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ],
    );
  }
}
