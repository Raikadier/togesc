import 'package:flutter/material.dart';

import '../app/design_tokens.dart';

/// Entrada de bloque (SPEC v2.1 §1.2): sube 12 px y aparece en 600 ms con
/// `easeOut`, retrasada [index] × [step].
///
/// Con movimiento reducido el hijo se muestra en su sitio, sin retardo.
/// Solo anima la primera vez que se monta.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.step = DesignTokens.staggerStep,
    this.duration = defaultDuration,
    this.offset = defaultOffset,
  });

  final int index;
  final Widget child;
  final Duration step;
  final Duration duration;

  /// Desplazamiento vertical inicial en píxeles lógicos.
  final double offset;

  static const Duration defaultDuration = Duration(milliseconds: 600);
  static const double defaultOffset = 12;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;
  bool _started = false;

  Duration get _delay => widget.step * widget.index;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _delay + widget.duration,
    );
    final total = _controller.duration!.inMicroseconds;
    final begin = total == 0 ? 0.0 : _delay.inMicroseconds / total;
    _t = CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, 1, curve: DesignTokens.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (motionDuration(context, widget.duration) == Duration.zero) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = _t.value;
        if (v >= 1) return child!;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - v)),
            child: child,
          ),
        );
      },
    );
  }
}
