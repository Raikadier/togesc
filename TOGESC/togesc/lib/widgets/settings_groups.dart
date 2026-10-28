import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/app_theme.dart';
import '../app/design_tokens.dart';
import '../app/router.dart';
import '../constants/note_naming.dart';
import '../models/audio_preferences.dart';
import '../models/practice_session_log.dart';
import '../models/practice_session_preferences.dart';
import '../models/srs_intensity_profile.dart';
import '../models/ui_preferences.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/audio_preferences_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/practice_note_pool_provider.dart';
import '../providers/practice_session_preferences_provider.dart';
import '../providers/router_provider.dart';
import '../providers/srs_intensity_provider.dart';
import '../providers/ui_preferences_provider.dart';
import '../services/app_preferences.dart';
import '../services/practice_reminder_service.dart';
import 'audio_test_button.dart';
import 'piano_keyboard.dart';
import 'session_instrument_sheet.dart';
import 'togesc_ui.dart';

/// Grupo de Ajustes v2.1 (SPEC §2.8): card con icono y título de cabecera.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return TogescCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Row(
              children: [
                ExcludeSemantics(child: Icon(icon, color: scheme.primary)),
                const SizedBox(width: DesignTokens.spacingSm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          ...children,
        ],
      ),
    );
  }
}

/// Etiqueta de un control que no es un interruptor (segmentos, chips).
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.title, {this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: DesignTokens.spacingMd,
        bottom: DesignTokens.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          if (subtitle != null)
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

SwitchListTile _switch({
  Key? key,
  required String title,
  required String subtitle,
  required bool value,
  required ValueChanged<bool>? onChanged,
  Color? subtitleColor,
}) {
  return SwitchListTile(
    key: key,
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(
      subtitle,
      style: subtitleColor == null ? null : TextStyle(color: subtitleColor),
    ),
    value: value,
    onChanged: onChanged,
  );
}

/// 1 · Práctica y accesibilidad (primero), con la vista previa del teclado.
class SettingsAccessibilityGroup extends ConsumerWidget {
  const SettingsAccessibilityGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(uiPreferencesProvider).valueOrNull;
    final naming =
        ref.watch(noteNamingModeProvider).valueOrNull ?? NoteNamingMode.letter;
    final notifier = ref.read(uiPreferencesProvider.notifier);
    if (ui == null) return const LinearProgressIndicator();

    return SettingsGroup(
      key: const ValueKey('settings-a11y'),
      icon: Icons.accessibility_new_rounded,
      title: 'Práctica y accesibilidad',
      children: [
        _switch(
          title: 'Reducir animaciones',
          subtitle:
              'Desactiva el movimiento de la interfaz y acorta esperas entre '
              'rondas.',
          value: ui.reduceAnimations,
          onChanged: notifier.setReduceAnimations,
        ),
        _switch(
          key: const ValueKey('settings-large-text'),
          title: 'Texto más grande',
          subtitle: 'Aumenta el tamaño de los textos de toda la app.',
          value: ui.largeText,
          onChanged: notifier.setLargeText,
        ),
        _switch(
          key: const ValueKey('settings-large-piano'),
          title: 'Piano más grande',
          subtitle: 'Teclas más amplias para facilitar el toque.',
          value: ui.largePiano,
          onChanged: notifier.setLargePiano,
        ),
        _switch(
          key: const ValueKey('settings-hide-labels'),
          title: 'Ocultar etiquetas del piano',
          subtitle: 'Entrena sin ver los nombres en las teclas.',
          value: ui.hidePianoLabels,
          onChanged: notifier.setHidePianoLabels,
        ),
        _switch(
          key: const ValueKey('settings-solfege'),
          title: 'Notación Do/Re/Mi',
          subtitle: 'Muestra solfeo en el piano y acepta respuestas en solfeo.',
          value: naming == NoteNamingMode.solfege,
          onChanged: (value) => ref
              .read(noteNamingModeProvider.notifier)
              .setMode(value ? NoteNamingMode.solfege : NoteNamingMode.letter),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        SettingsPianoPreview(
          large: ui.largePiano,
          hideLabels: ui.hidePianoLabels,
          namingMode: naming,
        ),
      ],
    );
  }
}

/// Vista previa en vivo del teclado de sesión: refleja el tamaño, las
/// etiquetas y la notación. Es decorativa (sin foco ni lectura).
class SettingsPianoPreview extends StatelessWidget {
  const SettingsPianoPreview({
    super.key,
    required this.large,
    required this.hideLabels,
    required this.namingMode,
  });

  final bool large;
  final bool hideLabels;
  final NoteNamingMode namingMode;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.session,
      child: Builder(
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          return Container(
            key: const ValueKey('settings-piano-preview'),
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            decoration: BoxDecoration(
              color: DesignTokens.sessionBackground,
              borderRadius: DesignTokens.borderRadiusCard,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Vista previa del teclado'.toUpperCase(),
                  style: DesignTokens.overline.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingSm),
                ExcludeSemantics(
                  child: IgnorePointer(
                    child: Center(
                      child: PianoKeyboard(
                        variant: PianoKeyboardVariant.session,
                        large: large,
                        hideLabels: hideLabels,
                        noteNamingMode: namingMode,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 2 · Sesión de práctica.
class SettingsSessionGroup extends ConsumerWidget {
  const SettingsSessionGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(practiceSessionPreferencesProvider).valueOrNull;
    final ui = ref.watch(uiPreferencesProvider).valueOrNull;
    final srs = ref.watch(srsIntensityProfileProvider).valueOrNull;
    final pool = ref.watch(practiceNotePoolProvider).valueOrNull;
    final reminders = ref.watch(practiceRemindersEnabledProvider).valueOrNull;
    final naming =
        ref.watch(noteNamingModeProvider).valueOrNull ?? NoteNamingMode.letter;
    if (session == null || ui == null) return const LinearProgressIndicator();
    final sessionNotifier = ref.read(
      practiceSessionPreferencesProvider.notifier,
    );
    final uiNotifier = ref.read(uiPreferencesProvider.notifier);

    return SettingsGroup(
      key: const ValueKey('settings-session'),
      icon: Icons.timer_outlined,
      title: 'Sesión de práctica',
      children: [
        const _FieldLabel(
          'Objetivo de rondas',
          subtitle: 'Para los modos de práctica libre.',
        ),
        Wrap(
          spacing: DesignTokens.spacingSm,
          runSpacing: DesignTokens.spacingSm,
          children: [
            for (final goal in SessionRoundGoal.values)
              ChoiceChip(
                label: Text(goal.label),
                selected: session.roundGoal == goal,
                onSelected: (_) => sessionNotifier.setRoundGoal(goal),
              ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        _switch(
          title: 'Continuar automáticamente',
          subtitle:
              'Tras cada resultado, pasa al cluster y a la siguiente ronda sin '
              'pulsar Siguiente.',
          value: session.autoAdvanceAfterResult,
          onChanged: sessionNotifier.setAutoAdvanceAfterResult,
        ),
        _switch(
          title: 'Confirmar antes de enviar',
          subtitle:
              'Si está desactivado, al completar la selección en el piano se '
              'envía la respuesta al instante.',
          value: ui.confirmBeforeSubmit,
          onChanged: uiNotifier.setConfirmBeforeSubmit,
        ),
        if (reminders != null)
          _switch(
            title: 'Recordatorios de repaso',
            subtitle: PracticeReminderService.isSupported
                ? 'Notificación local si tienes notas vencidas.'
                : 'Disponible en Android e iOS.',
            // El interruptor se desactiva, pero el motivo debe leerse (AA).
            subtitleColor: PracticeReminderService.isSupported
                ? null
                : Theme.of(context).colorScheme.onSurfaceVariant,
            value: reminders && PracticeReminderService.isSupported,
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
        const _FieldLabel('Modo de respuesta'),
        RadioGroup<GameInputMode>(
          groupValue: ui.inputMode,
          onChanged: (value) {
            if (value != null) uiNotifier.setInputMode(value);
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
        if (srs != null) ...[
          const _FieldLabel(
            'Intensidad SRS',
            subtitle: 'Ajusta la frecuencia de repaso entre sesiones.',
          ),
          RadioGroup<SrsIntensityProfile>(
            groupValue: srs,
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
        if (pool != null) ...[
          const _FieldLabel(
            'Notas en práctica',
            subtitle:
                'Elige qué alturas pueden salir en los modos generales '
                '(mínimo 1). Los modos especiales siguen sus propias reglas.',
          ),
          Wrap(
            spacing: DesignTokens.spacingSm,
            runSpacing: DesignTokens.spacingSm,
            children: [
              for (final note in chromaticNotes)
                FilterChip(
                  label: Text(formatNoteLabel(note, naming)),
                  selected: pool.contains(note),
                  onSelected: (_) => ref
                      .read(practiceNotePoolProvider.notifier)
                      .toggleNote(note),
                ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: pool.length >= chromaticNotes.length
                  ? null
                  : () =>
                        ref.read(practiceNotePoolProvider.notifier).selectAll(),
              child: const Text('Seleccionar las 12'),
            ),
          ),
        ],
      ],
    );
  }
}

/// 3 · Sonido: rejilla de timbres con preescucha, volumen con valor y
/// «Probar sonido».
class SettingsSoundGroup extends ConsumerWidget {
  const SettingsSoundGroup({super.key});

  Future<void> _preview(WidgetRef ref, String id) async {
    final audio = ref.read(audioPlayerServiceProvider);
    audio.captureUserGesture();
    if (!await audio.waitUntilReady()) return;
    final prefs = await ref.read(audioPreferencesProvider.future);
    audio.setMasterVolume(prefs.masterVolume);
    await audio.playTones(
      const [261.63],
      duration: prefs.toneDurationSec,
      instrument: id,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(audioPreferencesProvider).valueOrNull;
    if (prefs == null) return const LinearProgressIndicator();
    final notifier = ref.read(audioPreferencesProvider.notifier);
    final theme = Theme.of(context);
    final fixed = prefs.instrumentMode == InstrumentMode.fixed;
    final volume = (prefs.masterVolume * 100).round();

    return SettingsGroup(
      key: const ValueKey('settings-sound'),
      icon: Icons.volume_up_rounded,
      title: 'Sonido',
      children: [
        const _FieldLabel(
          'Timbre por defecto',
          subtitle:
              'Durante el juego puedes cambiar el timbre solo para esa sesión '
              'desde el icono de la barra superior.',
        ),
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
          onSelectionChanged: (s) => notifier.setInstrumentMode(s.first),
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        InstrumentTimbreGrid(
          keyPrefix: 'settings-timbre',
          selected: fixed ? prefs.fixedInstrumentId : null,
          onPick: (id) async {
            await notifier.setFixedInstrument(id);
            if (!fixed) await notifier.setInstrumentMode(InstrumentMode.fixed);
            await _preview(ref, id);
          },
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        Text(
          'Al elegir un timbre suena una preescucha.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const _FieldLabel('Volumen'),
        Row(
          children: [
            const ExcludeSemantics(child: Icon(Icons.volume_down_rounded)),
            Expanded(
              child: Slider(
                key: const ValueKey('settings-volume'),
                value: prefs.masterVolume,
                divisions: 20,
                label: '$volume %',
                semanticFormatterCallback: (v) => '${(v * 100).round()} %',
                onChanged: notifier.setMasterVolume,
              ),
            ),
            ExcludeSemantics(
              child: SizedBox(
                width: 52,
                child: Text(
                  '$volume %',
                  key: const ValueKey('settings-volume-value'),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)
                      .merge(DesignTokens.tabularNumbers),
                ),
              ),
            ),
          ],
        ),
        _switch(
          title: 'Variación de octavas',
          subtitle:
              'Las notas pueden sonar una octava arriba o abajo en cada ronda.',
          value: prefs.octaveVariationEnabled,
          onChanged: notifier.setOctaveVariationEnabled,
        ),
        _switch(
          title: 'Limpieza tonal (cluster)',
          subtitle: 'Sonido breve entre rondas para evitar anclaje tonal.',
          value: prefs.clusterEnabled,
          onChanged: notifier.setClusterEnabled,
        ),
        if (prefs.clusterEnabled) ...[
          const _FieldLabel('Duración del cluster'),
          SegmentedButton<double>(
            segments: const [
              ButtonSegment(value: 2.0, label: Text('2 s')),
              ButtonSegment(value: 3.0, label: Text('3 s')),
              ButtonSegment(value: 5.0, label: Text('5 s')),
            ],
            selected: {prefs.clusterDurationSec},
            onSelectionChanged: (s) => notifier.setClusterDuration(s.first),
          ),
        ],
        const _FieldLabel('Duración del tono'),
        SegmentedButton<double>(
          segments: const [
            ButtonSegment(value: 0.5, label: Text('0,5 s')),
            ButtonSegment(value: 1.0, label: Text('1 s')),
            ButtonSegment(value: 1.5, label: Text('1,5 s')),
          ],
          selected: {prefs.toneDurationSec},
          onSelectionChanged: (s) => notifier.setToneDuration(s.first),
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        const AudioTestButton(),
      ],
    );
  }
}

/// 4 · Apariencia: Claro, Oscuro o Sistema.
class SettingsAppearanceGroup extends ConsumerWidget {
  const SettingsAppearanceGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(uiPreferencesProvider).valueOrNull;
    if (ui == null) return const LinearProgressIndicator();
    final theme = Theme.of(context);
    return SettingsGroup(
      key: const ValueKey('settings-appearance'),
      icon: Icons.palette_outlined,
      title: 'Apariencia',
      children: [
        const _FieldLabel('Tema de la app'),
        SegmentedButton<AppThemePreference>(
          segments: [
            for (final option in const [
              AppThemePreference.light,
              AppThemePreference.dark,
              AppThemePreference.system,
            ])
              ButtonSegment(value: option, label: Text(option.label)),
          ],
          selected: {ui.themePreference},
          onSelectionChanged: (s) => ref
              .read(uiPreferencesProvider.notifier)
              .setThemePreference(s.first),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        Text(
          'La sesión de práctica siempre se muestra en oscuro.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Restablece los ajustes a sus valores por defecto. No toca el progreso
/// SRS, el historial, los recordatorios ni la cuenta.
Future<void> resetSettingsToDefaults(WidgetRef ref) async {
  await ref.read(uiPreferencesProvider.notifier).save(const UiPreferences());
  await ref
      .read(audioPreferencesProvider.notifier)
      .save(const AudioPreferences());
  await ref
      .read(practiceSessionPreferencesProvider.notifier)
      .save(const PracticeSessionPreferences());
  await ref
      .read(srsIntensityProfileProvider.notifier)
      .setProfile(SrsIntensityProfile.fromId(null));
  await ref.read(practiceNotePoolProvider.notifier).selectAll();
  await ref
      .read(noteNamingModeProvider.notifier)
      .setMode(NoteNamingMode.letter);
}

/// 5 · Más: tutorial y restablecer ajustes.
class SettingsMoreGroup extends ConsumerWidget {
  const SettingsMoreGroup({super.key});

  Future<void> _replayTutorial(BuildContext context) async {
    final prefs = AppPreferences(await SharedPreferences.getInstance());
    await prefs.setOnboardingComplete(false);
    if (!context.mounted) return;
    context.go(AppRoutes.onboarding);
    refreshAppRouter();
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          key: const ValueKey('settings-reset-sheet'),
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.spacingLg,
            0,
            DesignTokens.spacingLg,
            DesignTokens.spacingLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  '¿Restablecer los ajustes?',
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingSm),
              const Text(
                'Sonido, sesión, apariencia y accesibilidad vuelven a los '
                'valores por defecto. Tu progreso no se toca.',
              ),
              const SizedBox(height: DesignTokens.spacingLg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          DesignTokens.touchTargetMin,
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingMd),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('settings-reset-confirm'),
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          DesignTokens.touchTargetMin,
                        ),
                      ),
                      child: const Text('Restablecer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await resetSettingsToDefaults(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ajustes restablecidos.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsGroup(
      key: const ValueKey('settings-more'),
      icon: Icons.more_horiz_rounded,
      title: 'Más',
      children: [
        ListTile(
          key: const ValueKey('settings-tutorial'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Ver el tutorial otra vez'),
          subtitle: const Text('Cómo funciona y prueba de respuesta'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _replayTutorial(context),
        ),
        ListTile(
          key: const ValueKey('settings-reset'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Restablecer ajustes'),
          subtitle: const Text(
            'Vuelve a los valores por defecto. Tu progreso no se toca.',
          ),
          onTap: () => _confirmReset(context, ref),
        ),
      ],
    );
  }
}
