import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import 'session_phase.dart';

/// Anillo central de la sesión v2: overline de fase, anillo de 150 (170 en
/// escritorio), titular y subtítulo.
///
/// El bloque de texto es una región viva: el lector de pantalla anuncia cada
/// cambio de fase («Incorrecto. Era Re, respondiste Mi…»).
///
/// Movimiento v2.1:
/// - En `listen`, un arco de progreso se llena de forma lineal durante
///   [listenDuration] con el color de la fase.
/// - Al entrar en `result`, el anillo emite un halo de 1,2 s con el color
///   del resultado.
/// Con movimiento reducido no hay arco ni halo.
class SessionPhaseRing extends StatefulWidget {
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

  /// Duración del arco de `listen` (la de la fase en la sesión).
  final Duration listenDuration;

  /// Duración del halo de `result`.
  static const Duration glowDuration = Duration(milliseconds: 1200);

  const SessionPhaseRing({
    super.key,
    required this.phase,
    required this.copy,
    this.noteLabel,
    this.size = DesignTokens.sessionRingSize,
    this.reduceMotion = false,
    this.footer,
    this.listenDuration = DesignTokens.sessionListenDuration,
  });

  @override
  State<SessionPhaseRing> createState() => _SessionPhaseRingState();
}

class _SessionPhaseRingState extends State<SessionPhaseRing>
    with TickerProviderStateMixin {
  late final AnimationController _arc = AnimationController(vsync: this);
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: SessionPhaseRing.glowDuration,
  );
  bool _started = false;

  SessionPhase get phase => widget.phase;
  SessionPhaseCopy get copy => widget.copy;
  double get size => widget.size;

  bool get _reduced =>
      widget.reduceMotion ||
      motionDuration(context, widget.listenDuration) == Duration.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _onPhase(null);
  }

  @override
  void didUpdateWidget(covariant SessionPhaseRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase) _onPhase(oldWidget.phase);
  }

  void _onPhase(SessionPhase? previous) {
    if (_reduced) {
      _arc.value = 0;
      _glow.value = 0;
      return;
    }
    if (phase == SessionPhase.listen) {
      _arc.duration = widget.listenDuration;
      _arc.forward(from: 0);
    } else {
      _arc.stop();
      _arc.value = 0;
    }
    if (phase == SessionPhase.result && previous != SessionPhase.result) {
      _glow.forward(from: 0);
    } else if (phase != SessionPhase.result) {
      _glow.stop();
      _glow.value = 0;
    }
  }

  @override
  void dispose() {
    _arc.dispose();
    _glow.dispose();
    super.dispose();
  }

  Widget _center() {
    final color = copy.color;
    switch (phase) {
      case SessionPhase.listen:
        return SessionListeningBars(color: color, animate: !_reduced);
      case SessionPhase.answer:
        return Icon(Icons.hearing_rounded, size: size * 0.32, color: color);
      case SessionPhase.result:
        final label = widget.noteLabel ?? '';
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
        return Icon(Icons.headphones_rounded, size: size * 0.34, color: color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration =
        _reduced ? Duration.zero : DesignTokens.durationMedium;

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
                AnimatedBuilder(
                  animation: Listenable.merge([_arc, _glow]),
                  builder: (context, child) {
                    final g = _glow.value;
                    // Halo: sale de 0 a 26 px y se desvanece (ease-out).
                    final eased = Curves.easeOut.transform(g);
                    final glowing = g > 0 && g < 1;
                    return CustomPaint(
                      key: const ValueKey('session-ring-arc'),
                      foregroundPainter: _ArcPainter(
                        progress: phase == SessionPhase.listen ? _arc.value : 0,
                        color: copy.color,
                      ),
                      child: AnimatedContainer(
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
                          boxShadow: glowing
                              ? [
                                  BoxShadow(
                                    color: copy.color.withValues(
                                      alpha: 0.55 * (1 - eased),
                                    ),
                                    spreadRadius: 26 * eased,
                                  ),
                                ]
                              : const [],
                        ),
                        alignment: Alignment.center,
                        child: child,
                      ),
                    );
                  },
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
        if (widget.footer != null) ...[
          const SizedBox(height: DesignTokens.spacingLg),
          widget.footer!,
        ],
      ],
    );
  }
}

/// Arco de progreso sobre el borde del anillo, desde arriba y en sentido
/// horario.
class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    const stroke = 3.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.progress != progress || old.color != color;
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
