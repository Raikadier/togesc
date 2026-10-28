import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/app_theme.dart';
import '../app/design_tokens.dart';
import '../app/router.dart';
import '../app/togesc_colors.dart';
import '../constants/note_naming.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/audio_preferences_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/router_provider.dart';
import '../providers/ui_preferences_provider.dart';
import '../services/app_preferences.dart';
import '../widgets/onboarding_views.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/progress_v2/progress_metrics.dart' show spokenNoteName;

/// Onboarding v2.1 (SPEC §2.7): 4 pasos con indicador, «Saltar», ronda de
/// prueba (paso 3) y preferencias (paso 4). El paso actual se guarda para
/// retomar si se cierra la app a medias.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const int stepCount = 4;

  /// Nota de la ronda de prueba: La 4 (440 Hz).
  static const String tryNote = 'A';
  static const double tryFrequency = 440;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  bool _useSolfege = false;

  /// Tecla respondida en la ronda de prueba (null hasta responder).
  String? _tryAnswer;
  bool _heard = false;

  @override
  void initState() {
    super.initState();
    _restoreStep();
  }

  Future<void> _restoreStep() async {
    final prefs = AppPreferences(await SharedPreferences.getInstance());
    final saved = prefs.onboardingStep.clamp(0, OnboardingScreen.stepCount - 1);
    if (!mounted || saved == _step) return;
    setState(() => _step = saved);
  }

  Future<void> _goTo(int step) async {
    setState(() => _step = step);
    final prefs = AppPreferences(await SharedPreferences.getInstance());
    await prefs.setOnboardingStep(step);
  }

  NoteNamingMode get _naming =>
      _useSolfege ? NoteNamingMode.solfege : NoteNamingMode.letter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wide =
        MediaQuery.sizeOf(context).width >= DesignTokens.shellBreakpoint;
    final margin = wide
        ? DesignTokens.marginDesktop
        : DesignTokens.marginMobile;
    final last = _step == OnboardingScreen.stepCount - 1;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: DesignTokens.contentMaxWidth,
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(margin, 8, margin / 2, 0),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          'TOGESC',
                          style: DesignTokens.logo.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      OnboardingStepDots(
                        current: _step,
                        count: OnboardingScreen.stepCount,
                      ),
                      const Spacer(),
                      Visibility(
                        visible: !last,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: TextButton(
                          key: const ValueKey('onboarding-skip'),
                          onPressed: () => _complete(context),
                          child: const Text('Saltar'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    key: ValueKey('onboarding-step-$_step'),
                    padding: EdgeInsets.all(margin),
                    child: AnimatedSwitcher(
                      duration: motionDuration(
                        context,
                        DesignTokens.motionMedium,
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_step),
                        child: _buildStep(context),
                      ),
                    ),
                  ),
                ),
                _buildFooter(context, margin),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    return switch (_step) {
      0 => const _WelcomeStep(),
      1 => const _HowStep(),
      2 => _buildTryStep(context),
      _ => _buildPreferencesStep(context),
    };
  }

  Widget _buildFooter(BuildContext context, double margin) {
    final last = _step == OnboardingScreen.stepCount - 1;
    final untried = _step == 2 && _tryAnswer == null;
    const minSize = Size(120, DesignTokens.touchTargetMin);

    final Widget next;
    if (last) {
      next = FilledButton(
        key: const ValueKey('onboarding-start'),
        style: FilledButton.styleFrom(minimumSize: minSize),
        onPressed: () => _complete(context),
        child: const Text('Entendido, empezar'),
      );
    } else if (untried) {
      next = OutlinedButton(
        key: const ValueKey('onboarding-next'),
        style: OutlinedButton.styleFrom(minimumSize: minSize),
        onPressed: () => _goTo(_step + 1),
        child: const Text('Seguir sin probar'),
      );
    } else {
      next = FilledButton(
        key: const ValueKey('onboarding-next'),
        style: FilledButton.styleFrom(minimumSize: minSize),
        onPressed: () => _goTo(_step + 1),
        child: const Text('Siguiente'),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(margin, 8, margin, margin),
      child: Row(
        children: [
          if (_step > 0)
            TextButton.icon(
              key: const ValueKey('onboarding-back'),
              style: TextButton.styleFrom(minimumSize: minSize),
              onPressed: () => _goTo(_step - 1),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Atrás'),
            ),
          const Spacer(),
          next,
        ],
      ),
    );
  }

  // ── Paso 3 · ronda de prueba ─────────────────────────────────────────

  Future<void> _playTryNote() async {
    final audio = ref.read(audioPlayerServiceProvider);
    audio.captureUserGesture();
    setState(() => _heard = true);
    if (!await audio.waitUntilReady()) return;
    final prefs = await ref.read(audioPreferencesProvider.future);
    audio.setMasterVolume(prefs.masterVolume);
    await audio.playTones(const [
      OnboardingScreen.tryFrequency,
    ], duration: prefs.toneDurationSec);
  }

  Widget _buildTryStep(BuildContext context) {
    final colors = TogescColors.of(context);
    final answer = _tryAnswer;
    final target = OnboardingScreen.tryNote;
    final targetName = spokenNoteName(formatNoteLabel(target, _naming));

    final OnboardingTryStatus status;
    if (answer == null) {
      status = OnboardingTryStatus(
        icon: Icons.hearing_rounded,
        title: _heard ? '¿Qué nota era?' : 'Escucha y responde',
        detail: _heard
            ? 'Toca la tecla que creas que es. Puedes repetir la nota.'
            : 'Toca «Escuchar la nota» y después la tecla que creas que es.',
      );
    } else if (answer == target) {
      status = OnboardingTryStatus(
        icon: Icons.check_circle_rounded,
        accent: colors.correct,
        title: 'Correcto',
        detail: 'Era $targetName. Así es cada ronda de práctica.',
      );
    } else {
      final answerName = spokenNoteName(formatNoteLabel(answer, _naming));
      status = OnboardingTryStatus(
        icon: Icons.cancel_rounded,
        accent: colors.incorrect,
        title: 'Era $targetName',
        detail:
            'Marcaste $answerName. Fallar es parte del método: el SRS te la '
            'repetirá más.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepHeader(
          overline: 'Paso 3 · Prueba',
          title: 'Una ronda de prueba',
          lead:
              'Escucha una nota y toca la tecla que creas que es. No cuenta '
              'para tu progreso.',
        ),
        const SizedBox(height: DesignTokens.spacingLg),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            key: const ValueKey('onboarding-try-play'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, DesignTokens.touchTargetMin),
            ),
            onPressed: _playTryNote,
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text('Escuchar la nota'),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingLg),
        Theme(
          data: AppTheme.session,
          child: Container(
            key: const ValueKey('onboarding-try-piano'),
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            decoration: BoxDecoration(
              color: DesignTokens.sessionBackground,
              borderRadius: DesignTokens.borderRadiusCard,
            ),
            child: PianoKeyboard(
              variant: PianoKeyboardVariant.session,
              noteNamingMode: _naming,
              disabled: answer != null,
              correctNotes: answer == null ? const {} : {target},
              incorrectNotes: answer == null || answer == target
                  ? const {}
                  : {answer},
              dimOthers: answer != null,
              onNoteTapped: (note) => setState(() => _tryAnswer = note),
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        status,
        if (answer != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('onboarding-try-again'),
              onPressed: () => setState(() => _tryAnswer = null),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Probar otra vez'),
            ),
          ),
      ],
    );
  }

  // ── Paso 4 · preferencias ────────────────────────────────────────────

  Widget _buildPreferencesStep(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ui = ref.watch(uiPreferencesProvider).valueOrNull;
    final notifier = ref.read(uiPreferencesProvider.notifier);
    final preview = _useSolfege
        ? const ['Do', 'Re', 'Mi', 'Fa', 'Sol']
        : const ['C', 'D', 'E', 'F', 'G'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepHeader(
          overline: 'Paso 4 · Preferencias',
          title: 'Antes de empezar',
          lead: 'Puedes cambiarlo después en Ajustes.',
        ),
        const SizedBox(height: DesignTokens.spacingLg),
        Text('Notación', style: theme.textTheme.titleSmall),
        const SizedBox(height: DesignTokens.spacingSm),
        SegmentedButton<bool>(
          key: const ValueKey('onboarding-notation'),
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('C · D · E'),
              tooltip: 'Letras',
            ),
            ButtonSegment(
              value: true,
              label: Text('Do · Re · Mi'),
              tooltip: 'Solfeo',
            ),
          ],
          selected: {_useSolfege},
          onSelectionChanged: (s) => setState(() => _useSolfege = s.first),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        Semantics(
          label: 'Vista previa: ${preview.join(', ')}',
          excludeSemantics: true,
          child: Wrap(
            key: const ValueKey('onboarding-notation-preview'),
            spacing: DesignTokens.spacingSm,
            children: [
              for (final n in preview)
                Chip(label: Text(n), visualDensity: VisualDensity.compact),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.spacingLg),
        if (ui == null)
          const LinearProgressIndicator()
        else ...[
          SwitchListTile(
            key: const ValueKey('onboarding-reduce-motion'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Reducir animaciones'),
            subtitle: const Text('Menos movimiento en toda la app.'),
            value: ui.reduceAnimations,
            onChanged: notifier.setReduceAnimations,
          ),
          SwitchListTile(
            key: const ValueKey('onboarding-large-text'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Texto más grande'),
            subtitle: Text(
              'Aumenta el tamaño de los textos de toda la app.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            value: ui.largeText,
            onChanged: notifier.setLargeText,
          ),
        ],
      ],
    );
  }

  Future<void> _complete(BuildContext context) async {
    ref.read(audioPlayerServiceProvider).captureUserGesture();
    final prefs = AppPreferences(await SharedPreferences.getInstance());
    await prefs.setOnboardingComplete(true);
    await prefs.setOnboardingStep(0);
    await prefs.setNoteNamingMode(_naming);
    ref.invalidate(noteNamingModeProvider);
    refreshAppRouter();
    if (context.mounted) {
      context.go(AppRoutes.home);
    }
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingWelcomeArt(),
        SizedBox(height: DesignTokens.spacingLg),
        OnboardingStepHeader(
          overline: 'Bienvenida',
          title: 'Entrenador de oído absoluto',
          lead:
              'Método con repetición espaciada, variación de estímulos y '
              'limpieza tonal. Tres ideas clave antes de empezar.',
        ),
      ],
    );
  }
}

class _HowStep extends StatelessWidget {
  const _HowStep();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingStepHeader(
          overline: 'Paso 2 · Método',
          title: 'Cómo funciona',
        ),
        SizedBox(height: DesignTokens.spacingLg),
        OnboardingPedagogyBento(),
      ],
    );
  }
}
