import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../constants/game_constants.dart';
import '../widgets/speed_mode_select_views.dart';
import '../widgets/speed_session_views.dart';
import '../widgets/togesc_ui.dart';

/// Pantalla de seleccion de modo para entrenamiento de velocidad.
class SpeedModeSelectScreen extends StatelessWidget {
  const SpeedModeSelectScreen({super.key});

  static const _modes = [
    (
      GameMode.singleNote,
      Icons.music_note_rounded,
      'Identifica notas individuales',
    ),
    (
      GameMode.interval,
      Icons.music_note_outlined,
      'Dos notas simultaneas',
    ),
    (
      GameMode.chord,
      Icons.piano_rounded,
      'Tres notas simultaneas',
    ),
    (
      GameMode.random,
      Icons.casino_rounded,
      'Entre 1 y 5 notas al azar',
    ),
    (
      GameMode.sharpsOnly,
      Icons.tag_rounded,
      'C#, D#, F#, G#, A#',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return TogescScaffold(
      title: 'Velocidad - Elige modo',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.marginMobile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SpeedModeSelectHero(),
            const SizedBox(height: DesignTokens.spacingLg),
            for (final (mode, icon, subtitle) in _modes)
              SpeedModeOptionCard(
                title: mode.displayName,
                subtitle: subtitle,
                icon: icon,
                onTap: () => _start(context, mode),
              ),
          ],
        ),
      ),
    );
  }

  void _start(BuildContext context, GameMode mode) {
    context.pushReplacement('${AppRoutes.speedGame}/${mode.id}');
  }
}
