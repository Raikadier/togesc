import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';

/// Acción elegida en la hoja «Sesión en pausa».
enum SessionPauseAction { resume, restart, exit, finish }

/// Hoja «Sesión en pausa» (SPEC v2.1 §2.2.6): se abre con el botón de
/// pausa, con `Esc` o al volver con la sesión en curso. Cerrarla sin elegir
/// (arrastre, velo o `Esc`) equivale a «Continuar».
///
/// [canFinish] añade «Terminar y ver resumen» (sesiones sin límite de
/// rondas, que no llegan solas al resumen).
Future<SessionPauseAction> showSessionPauseSheet({
  required BuildContext context,
  required int round,
  required int targetRounds,
  required int correctRounds,
  bool canFinish = false,
}) async {
  final action = await showModalBottomSheet<SessionPauseAction>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: DesignTokens.sessionSurface,
    builder: (context) => SessionPauseSheet(
      round: round,
      targetRounds: targetRounds,
      correctRounds: correctRounds,
      canFinish: canFinish,
    ),
  );
  return action ?? SessionPauseAction.resume;
}

class SessionPauseSheet extends StatelessWidget {
  const SessionPauseSheet({
    super.key,
    required this.round,
    required this.targetRounds,
    required this.correctRounds,
    this.canFinish = false,
  });

  final int round;
  final int targetRounds;
  final int correctRounds;
  final bool canFinish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roundText =
        targetRounds > 0 ? 'Ronda $round de $targetRounds' : 'Ronda $round';
    final hits = correctRounds == 1 ? '1 acierto' : '$correctRounds aciertos';

    ButtonStyle secondary() => OutlinedButton.styleFrom(
          foregroundColor: DesignTokens.sessionTextPrimary,
          side: const BorderSide(color: DesignTokens.sessionBorder),
          minimumSize: const Size.fromHeight(DesignTokens.touchTargetMin),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusCta,
          ),
        );

    return Padding(
      key: const ValueKey('session-pause-sheet'),
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.marginMobile,
        0,
        DesignTokens.marginMobile,
        DesignTokens.marginMobile,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Sesión en pausa',
              style: theme.textTheme.titleLarge?.copyWith(
                color: DesignTokens.sessionTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXs),
          Text(
            '$roundText · $hits',
            key: const ValueKey('session-pause-progress'),
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: DesignTokens.sessionTextSecondary)
                .merge(DesignTokens.tabularNumbers),
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            'El SRS ya guardó cada respuesta. «Salir sin guardar» no '
            'registra esta sesión en tu historial.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: DesignTokens.sessionTextSecondary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingLg + 4),
          FilledButton.icon(
            key: const ValueKey('session-pause-resume'),
            autofocus: true,
            onPressed: () =>
                Navigator.of(context).pop(SessionPauseAction.resume),
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.sessionAmber,
              foregroundColor: DesignTokens.sessionOnAccent,
              minimumSize: const Size.fromHeight(DesignTokens.touchTargetMin),
              shape: RoundedRectangleBorder(
                borderRadius: DesignTokens.borderRadiusCta,
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Continuar'),
          ),
          if (canFinish) ...[
            const SizedBox(height: DesignTokens.spacingSm),
            OutlinedButton.icon(
              key: const ValueKey('session-pause-finish'),
              onPressed: () =>
                  Navigator.of(context).pop(SessionPauseAction.finish),
              style: secondary(),
              icon: const Icon(Icons.flag_rounded),
              label: const Text('Terminar y ver resumen'),
            ),
          ],
          const SizedBox(height: DesignTokens.spacingSm),
          OutlinedButton.icon(
            key: const ValueKey('session-pause-restart'),
            onPressed: () =>
                Navigator.of(context).pop(SessionPauseAction.restart),
            style: secondary(),
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Reiniciar la sesión'),
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          OutlinedButton.icon(
            key: const ValueKey('session-pause-exit'),
            onPressed: () => Navigator.of(context).pop(SessionPauseAction.exit),
            style: secondary(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Salir sin guardar'),
          ),
        ],
      ),
    );
  }
}
