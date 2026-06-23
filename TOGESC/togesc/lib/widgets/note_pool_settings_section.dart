import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_tokens.dart';
import '../constants/note_naming.dart';
import '../models/practice_session_log.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/practice_note_pool_provider.dart';
import 'togesc_ui.dart';

/// Pool de notas activas para la practica (Fase 7C-4).
class NotePoolSettingsSection extends ConsumerWidget {
  const NotePoolSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poolAsync = ref.watch(practiceNotePoolProvider);
    final naming =
        ref.watch(noteNamingModeProvider).valueOrNull ?? NoteNamingMode.letter;

    return TogescCard(
      child: poolAsync.when(
        data: (pool) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Notas en practica',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Elige que alturas pueden salir en los modos generales '
              '(minimo 1). Los modos especiales siguen sus propias reglas.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: DesignTokens.spacingSm,
              runSpacing: DesignTokens.spacingSm,
              children: chromaticNotes.map((note) {
                final selected = pool.contains(note);
                return FilterChip(
                  label: Text(formatNoteLabel(note, naming)),
                  selected: selected,
                  onSelected: (_) {
                    ref.read(practiceNotePoolProvider.notifier).toggleNote(note);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: pool.length >= chromaticNotes.length
                    ? null
                    : () {
                        ref.read(practiceNotePoolProvider.notifier).selectAll();
                      },
                child: const Text('Seleccionar las 12'),
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
