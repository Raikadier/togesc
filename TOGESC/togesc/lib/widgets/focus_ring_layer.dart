import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../app/design_tokens.dart';

/// Anillo de foco global (v2.1 §1.3, lote F de v2.2): 3 px a 2 px del
/// control enfocado con el teclado, en `primary` (claro) o #DA9CFF (oscuro).
///
/// Va encima de toda la app (en `MaterialApp.builder`) y sigue al foco
/// primario, así cubre botones, teclas, tarjetas, chips e interruptores sin
/// tocar cada estilo. Solo se pinta en modo de foco por teclado
/// (`FocusHighlightMode.traditional`), nunca al tocar.
class FocusRingLayer extends StatefulWidget {
  const FocusRingLayer({super.key, required this.child});

  final Widget child;

  static const double gap = 2;
  static const double width = 3;

  @override
  State<FocusRingLayer> createState() => _FocusRingLayerState();
}

class _FocusRingLayerState extends State<FocusRingLayer> {
  final _repaint = ValueNotifier<(Rect, Color)?>(null);
  bool _watching = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_update);
    FocusManager.instance.addHighlightModeListener(_onMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_update);
    FocusManager.instance.removeHighlightModeListener(_onMode);
    _repaint.dispose();
    super.dispose();
  }

  void _onMode(FocusHighlightMode _) => _update();

  (Rect, Color)? _currentRing() {
    final manager = FocusManager.instance;
    if (manager.highlightMode != FocusHighlightMode.traditional) return null;
    final node = manager.primaryFocus;
    final ctx = node?.context;
    // Los ámbitos (rutas, Shortcuts) no son controles: no llevan anillo.
    if (node == null || ctx == null || node is FocusScopeNode) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final overlay = context.findRenderObject();
    if (overlay is! RenderBox) return null;
    final rect = node.rect;
    if (rect.isEmpty) return null;
    return (
      MatrixUtils.transformRect(overlay.getTransformTo(null)..invert(), rect),
      FocusRingColor.of(ctx),
    );
  }

  void _update() {
    if (!mounted) return;
    _repaint.value = _currentRing();
    // El control puede moverse (scroll, animación) sin que cambie el foco:
    // mientras hay anillo se revisa tras cada frame, sin pedir frames nuevos.
    if (_repaint.value != null && !_watching) {
      _watching = true;
      SchedulerBinding.instance.addPostFrameCallback(_afterFrame);
    }
  }

  void _afterFrame(Duration _) {
    _watching = false;
    _update();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _RingPainter(_repaint)),
          ),
        ),
      ],
    );
  }
}

/// Color del anillo para una zona con fondo propio (el hero morado, por
/// ejemplo), donde el `primary` del tema no llega a 3:1.
class FocusRingColor extends InheritedWidget {
  const FocusRingColor({super.key, required this.color, required super.child});

  final Color color;

  /// Color para el control de [context]: el de la zona si lo hay; si no,
  /// `primary` en claro y #DA9CFF en oscuro (sesión incluida).
  static Color of(BuildContext context) {
    final zone = context.dependOnInheritedWidgetOfExactType<FocusRingColor>();
    if (zone != null) return zone.color;
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? DesignTokens.darkPrimary
        : theme.colorScheme.primary;
  }

  @override
  bool updateShouldNotify(FocusRingColor old) => old.color != color;
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.ring) : super(repaint: ring);

  final ValueNotifier<(Rect, Color)?> ring;

  @override
  void paint(Canvas canvas, Size size) {
    final value = ring.value;
    if (value == null) return;
    final (r, color) = value;
    // Trazo centrado en 2 + 1,5 px: cubre la banda de 2 a 5 px.
    const offset = FocusRingLayer.gap + FocusRingLayer.width / 2;
    final shape = RRect.fromRectAndRadius(
      r.inflate(offset),
      const Radius.circular(DesignTokens.radiusMd + offset),
    );
    canvas.drawRRect(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = FocusRingLayer.width
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.ring != ring;
}
