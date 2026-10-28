import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../app/togesc_colors.dart';

/// Temporizador en anillo del modo velocidad (v2.1, SPEC §2.4.2).
///
/// Anillo de 168 px en el acento de velocidad (#FF8A65 en la sesión). Con
/// menos de 2 s o menos del 30 % del límite pasa al estado bajo: anillo y
/// cifra en `incorrect` (#EF9A9A), la etiqueta «¡Rápido!» y un latido de
/// la cifra (sin latido con movimiento reducido).
class CountdownTimerWidget extends StatefulWidget {
  final double remainingTime;
  final double totalTime;

  const CountdownTimerWidget({
    super.key,
    required this.remainingTime,
    required this.totalTime,
  });

  static const double size = 168;

  /// Estado bajo: queda menos de 2 s o menos del 30 % del límite.
  static bool isLow(double remaining, double total) =>
      remaining < 2.0 || remaining < total * 0.3;

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBeat();
  }

  @override
  void didUpdateWidget(CountdownTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBeat();
  }

  void _syncBeat() {
    final low = CountdownTimerWidget.isLow(
      widget.remainingTime,
      widget.totalTime,
    );
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (low && !reduced && widget.remainingTime > 0) {
      if (!_beat.isAnimating) _beat.repeat(reverse: true);
    } else if (_beat.isAnimating || _beat.value != 0) {
      _beat
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = TogescColors.of(context);
    final total = widget.totalTime;
    final remaining = widget.remainingTime.clamp(0.0, total > 0 ? total : 0.0);
    final progress = total > 0 ? (remaining / total).clamp(0.0, 1.0) : 0.0;
    final low = CountdownTimerWidget.isLow(remaining, total);
    final color = low ? colors.incorrect : colors.speedAccent;
    final value = remaining.toStringAsFixed(1).replaceAll('.', ',');
    final wholeSeconds = remaining.ceil();

    return Semantics(
      key: const ValueKey('speed-timer'),
      label:
          'Tiempo restante: $wholeSeconds '
          '${wholeSeconds == 1 ? 'segundo' : 'segundos'}',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: CountdownTimerWidget.size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: progress,
            track: scheme.surfaceContainerHigh,
            color: color,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 1, end: 1.08).animate(
                    CurvedAnimation(parent: _beat, curve: Curves.easeInOut),
                  ),
                  child: Text(
                    value,
                    key: const ValueKey('speed-timer-value'),
                    style: theme.textTheme.displaySmall
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          height: 1,
                          color: low ? colors.incorrect : scheme.onSurface,
                        )
                        .merge(DesignTokens.tabularNumbers),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                Text(
                  low ? '¡Rápido!' : 'segundos',
                  key: const ValueKey('speed-timer-caption'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: low ? colors.incorrect : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.color,
  });

  final double progress;
  final Color track;
  final Color color;

  static const double stroke = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, base..color = track);
    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      base
        ..color = color
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.color != color;
}
