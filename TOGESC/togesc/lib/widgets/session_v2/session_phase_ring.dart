import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import 'session_phase.dart';

/// Anillo central de la sesión v2: overline de fase, anillo de 150 (170 en
/// escritorio), titular y subtítulo.
///
/// El bloque de texto es una región viva: el lector de pantalla anuncia cada
/// cambio de fase («Incorrecto. Era Re, respondiste Mi…»).
class SessionPhaseRing extends StatelessWidget {
  final SessionPhase phase;
  final SessionPhaseCopy copy;

  /// Nombre de nota grande dentro del anillo (fase `result`).
  final String? noteLabel;

  /// Diámetro del anillo ([DesignTokens.sessionRingSize] o la de escritorio).
  final double size;

  /// Sin animación de barras (movimiento reducido del sistema o de Ajustes).
  final bool reduceMotion;

  /// Acción opcional bajo el subtítulo (empezar, reanudar, siguiente…).
  final Widget? footer;

  const SessionPhaseRing({
    super.key,
    required this.phase,
    required this.copy,
    this.noteLabel,
    this.size = DesignTokens.sessionRingSize,
    this.reduceMotion = false,
    this.footer,
  });

  Widget _center() {
    final color = copy.color;
    switch (phase) {
      case SessionPhase.listen:
        return SessionListeningBars(color: color, animate: !reduceMotion);
      case SessionPhase.answer:
        return Icon(Icons.hearing_rounded, size: size * 0.32, color: color);
      case SessionPhase.result:
        final label = noteLabel ?? '';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              key: const ValueKey('session-ring-note'),
              style: DesignTokens.bigNumber.copyWith(
                color: color,
                fontSize: label.length > 3 ? 34 : 44,
              ),
            ),
          ),
        );
      case SessionPhase.cluster:
        return Icon(Icons.waves_rounded, size: size * 0.3, color: color);
      case SessionPhase.paused:
        return Icon(Icons.pause_rounded, size: size * 0.32, color: color);
      case SessionPhase.idle:
        return Icon(Icons.play_arrow_rounded, size: size * 0.36, color: color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = reduceMotion ? Duration.zero : DesignTokens.motionMedium;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          container: true,
          liveRegion: true,
          label: copy.announcement,
          child: ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  copy.overline.toUpperCase(),
                  key: const ValueKey('session-phase-overline'),
                  style: DesignTokens.overlineLarge.copyWith(color: copy.color),
                ),
                const SizedBox(height: DesignTokens.spacingMd),
                AnimatedContainer(
                  duration: duration,
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: copy.color.withValues(alpha: 0.08),
                    border: Border.all(
                      color: copy.color.withValues(alpha: 0.55),
                      width: 3,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: _center(),
                ),
                const SizedBox(height: DesignTokens.spacingLg),
                Text(
                  copy.headline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: DesignTokens.sessionTextPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                if (copy.subtitle != null) ...[
                  const SizedBox(height: DesignTokens.spacingSm),
                  Text(
                    copy.subtitle!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: DesignTokens.sessionTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (footer != null) ...[
          const SizedBox(height: DesignTokens.spacingLg),
          footer!,
        ],
      ],
    );
  }
}

/// Cinco barras de ecualizador (keyframe scaleY .3 → 1, 1 s, desfase .15 s).
/// Con [animate] en `false` se dibujan estáticas.
class SessionListeningBars extends StatefulWidget {
  final Color color;
  final bool animate;

  const SessionListeningBars({
    super.key,
    required this.color,
    this.animate = true,
  });

  @override
  State<SessionListeningBars> createState() => _SessionListeningBarsState();
}

class _SessionListeningBarsState extends State<SessionListeningBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  static const _staticScales = [0.45, 0.8, 1.0, 0.7, 0.4];

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant SessionListeningBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _scale(int index) {
    if (!widget.animate) return _staticScales[index];
    final t = (_controller.value - index * 0.15) % 1.0;
    // Ida y vuelta suave entre .3 y 1.
    final wave = 0.5 - 0.5 * math.cos(t * 2 * math.pi);
    return 0.3 + 0.7 * wave;
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        key: const ValueKey('session-listening-bars'),
        width: 64,
        height: 48,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(5, (i) {
                return Container(
                  width: 6,
                  height: 48 * _scale(i),
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
