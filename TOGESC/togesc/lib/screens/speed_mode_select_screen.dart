import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../constants/game_constants.dart';
import '../providers/speed_best_streak_provider.dart';
import '../providers/speed_difficulty_provider.dart';
import '../widgets/speed_mode_select_views.dart';
import '../widgets/speed_session_views.dart';
import '../widgets/togesc_ui.dart';

/// Pantalla de selección de modo para entrenamiento de velocidad.
class SpeedModeSelectScreen extends ConsumerWidget {
  const SpeedModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final difficulty = ref.watch(speedDifficultyProvider);
    final bests = ref.watch(speedBestStreakProvider).valueOrNull ?? const {};

    return TogescScaffold(
      title: 'Velocidad — Elige modo',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.marginMobile),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= DesignTokens.shellBreakpoint;
            // v2.1: primero la dificultad (tarjetas radio) y después el
            // modo, que arranca la ráfaga al tocarlo.
            final selector = SpeedDifficultySelector(
              selected: difficulty,
              bestStreaks: bests,
              onChanged: (value) {
                ref.read(speedDifficultyProvider.notifier).state = value;
              },
            );
            const how = SpeedHowItWorksCard();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SpeedModeSelectHero(),
                const SizedBox(height: DesignTokens.spacingLg),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 13, child: selector),
                      const SizedBox(width: DesignTokens.spacingLg),
                      const Expanded(flex: 10, child: how),
                    ],
                  )
                else
                  selector,
                const SizedBox(height: DesignTokens.spacingLg),
                Semantics(
                  header: true,
                  child: Text(
                    'Elige el modo para empezar'.toUpperCase(),
                    style: DesignTokens.overline.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingMd),
                _SpeedModeBento(
                  wide: wide,
                  onStart: (mode) => _start(context, mode),
                ),
                if (!wide) ...[
                  const SizedBox(height: DesignTokens.spacingLg),
                  how,
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void _start(BuildContext context, GameMode mode) {
    context.pushReplacement('${AppRoutes.speedGame}/${mode.id}');
  }
}

class _SpeedModeBento extends StatelessWidget {
  final bool wide;
  final void Function(GameMode mode) onStart;

  const _SpeedModeBento({required this.wide, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final gap = DesignTokens.spacingMd;

    Widget card({
      required GameMode mode,
      required String title,
      required String subtitle,
      required IconData icon,
      SpeedModeCardVariant variant = SpeedModeCardVariant.standard,
      bool compact = false,
      bool showCta = true,
    }) {
      return SpeedModeOptionCard(
        title: title,
        subtitle: subtitle,
        icon: icon,
        variant: variant,
        compact: compact,
        showCta: showCta,
        onTap: () => onStart(mode),
      );
    }

    final single = card(
      mode: GameMode.singleNote,
      title: 'Una nota',
      subtitle:
          'Identifica notas individuales aisladas en una ráfaga de alta velocidad.',
      icon: Icons.music_note_rounded,
    );
    final interval = card(
      mode: GameMode.interval,
      title: 'Intervalo',
      subtitle:
          'Reconoce la distancia exacta entre dos notas bajo presión extrema.',
      icon: Icons.straighten_rounded,
    );
    final chord = card(
      mode: GameMode.chord,
      title: 'Acorde',
      subtitle: 'Tríadas lanzadas en ráfagas rápidas.',
      icon: Icons.layers_rounded,
      compact: true,
      showCta: false,
    );
    final chaos = card(
      mode: GameMode.random,
      title: 'Modo Chaos',
      subtitle: 'La prueba definitiva: 1 a 5 notas mezcladas sin aviso.',
      icon: Icons.shuffle_rounded,
      variant: SpeedModeCardVariant.chaos,
      compact: true,
      showCta: false,
    );
    final blackKeys = card(
      mode: GameMode.sharpsOnly,
      title: 'Teclas negras',
      subtitle: 'Entrenamiento enfocado en semitonos y accidentales.',
      icon: Icons.piano_rounded,
      variant: SpeedModeCardVariant.darkKeys,
      compact: true,
      showCta: false,
    );

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          single,
          SizedBox(height: gap),
          interval,
          SizedBox(height: gap),
          chord,
          SizedBox(height: gap),
          chaos,
          SizedBox(height: gap),
          blackKeys,
        ],
      );
    }

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: single),
              SizedBox(width: gap),
              Expanded(child: interval),
            ],
          ),
        ),
        SizedBox(height: gap),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: chord),
              SizedBox(width: gap),
              Expanded(child: chaos),
              SizedBox(width: gap),
              Expanded(child: blackKeys),
            ],
          ),
        ),
      ],
    );
  }
}
