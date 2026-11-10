import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/design_tokens.dart';
import '../../app/togesc_colors.dart';
import '../../constants/note_naming.dart';
import '../../models/note_progress_summary.dart';
import '../../models/practice_session_log.dart' show chromaticNotes;
import '../../utils/srs_level.dart';
import '../progress_v2/note_mastery_grid.dart' show NoteMasteryCell;

/// Mapa del oído (SPEC v2.1 §1.1): rueda de 12 segmentos en orden cromático,
/// C arriba y en sentido horario. Cada segmento es una barra radial con el %
/// de precisión y el color de `masteryColor`.
///
/// - Cada segmento es enfocable (Tab, en orden cromático) y se activa con
///   Enter o Espacio, con toque o con clic. Lleva su propio `Semantics`
///   («C sostenido, 42 %, crítica, nivel 1 de 5»).
/// - El centro muestra [centerValue] y [centerCaption]; al pasar el ratón o
///   enfocar un segmento, la nota, su nivel y su %.
/// - Entrada escalonada (escala .55 → 1 con `easeSpring`, 45 ms por
///   segmento y 120 ms iniciales). Sin animación con movimiento reducido.
/// - Las notas sin resumen o sin intentos se dibujan como «sin datos».
class EarMapWheel extends StatefulWidget {
  const EarMapWheel({
    super.key,
    required this.summaries,
    this.namingMode = NoteNamingMode.letter,
    this.learningThreshold = 5,
    this.centerValue,
    this.centerCaption,
    this.selectedNote,
    this.onSelect,
    this.onHover,
    this.onDark = false,
    this.compact = false,
  });

  /// Resúmenes por nota. El orden da igual: se colocan por clase de altura.
  final List<NoteProgressSummary> summaries;
  final NoteNamingMode namingMode;
  final int learningThreshold;

  /// Texto grande del centro en reposo («68 %», «5/12»).
  final String? centerValue;

  /// Texto pequeño bajo [centerValue] («Precisión global», «consolidadas»).
  final String? centerCaption;

  /// Nota marcada como activa (contorno `brand`), p. ej. la fila de detalle.
  final String? selectedNote;

  /// Activación de un segmento (toque, clic, Enter o Espacio).
  final ValueChanged<NoteProgressSummary>? onSelect;

  /// Segmento bajo el ratón o con foco; `null` al salir.
  final ValueChanged<NoteProgressSummary?>? onHover;

  /// Sobre la card `hero` o un fondo oscuro fijo: pista blanca al 8 % y
  /// texto claro, sin depender del tema.
  final bool onDark;

  /// Variante compacta: anillo más grueso (r0 70, r1 132).
  final bool compact;

  /// Duración de la entrada de cada segmento.
  static const Duration segmentDuration = Duration(milliseconds: 900);

  /// Retardo antes del primer segmento.
  static const Duration entranceDelay = Duration(milliseconds: 120);

  /// Duración total de la entrada escalonada.
  static Duration get entranceDuration =>
      entranceDelay + DesignTokens.staggerWheel * 11 + segmentDuration;

  @override
  State<EarMapWheel> createState() => _EarMapWheelState();
}

/// Geometría del mapa en unidades del viewBox de 320.
class _WheelGeometry {
  const _WheelGeometry({required this.compact});

  final bool compact;

  static const double center = DesignTokens.earMapViewBox / 2;

  /// Medio hueco angular a cada lado del segmento (~2,6°).
  static const double gap = 0.045;
  static const double step = math.pi / 6;

  double get r0 =>
      compact ? DesignTokens.earMapInnerCompact : DesignTokens.earMapInner;
  double get r1 =>
      compact ? DesignTokens.earMapOuterCompact : DesignTokens.earMapOuter;
  double get labelRadius => compact ? 148 : 146;

  /// Borde exterior de la zona táctil: incluye la etiqueta.
  double get hitOuter => center;

  double startAngle(int i) => i * step - step / 2 + gap;
  double endAngle(int i) => (i + 1) * step - step / 2 - gap;
  double midAngle(int i) => i * step;

  /// Sector anular en coordenadas del viewBox; ángulo 0 arriba, horario.
  static Path sector(double r0, double r1, double a0, double a1) {
    Offset p(double r, double a) =>
        Offset(center + r * math.sin(a), center - r * math.cos(a));
    // Flutter mide los ángulos desde +x en sentido horario.
    final start = a0 - math.pi / 2;
    final sweep = a1 - a0;
    final outer = Rect.fromCircle(
      center: const Offset(center, center),
      radius: r1,
    );
    final inner = Rect.fromCircle(
      center: const Offset(center, center),
      radius: r0,
    );
    final p0 = p(r1, a0);
    return Path()
      ..moveTo(p0.dx, p0.dy)
      ..arcTo(outer, start, sweep, false)
      ..arcTo(inner, start + sweep, -sweep, false)
      ..close();
  }

  Offset labelCenter(int i) {
    final a = midAngle(i);
    return Offset(
      center + labelRadius * math.sin(a),
      center - labelRadius * math.cos(a),
    );
  }
}

/// Datos ya resueltos de un segmento.
class _Segment {
  const _Segment({
    required this.summary,
    required this.label,
    required this.seen,
    required this.pct,
    required this.level,
  });

  final NoteProgressSummary summary;
  final String label;
  final bool seen;
  final double pct;
  final int level;

  /// Fracción radial rellena: mínimo 6 % para que se vea el segmento.
  double get fill => seen ? math.max(0.06, pct / 100).clamp(0.0, 1.0) : 0.06;
}

class _EarMapWheelState extends State<EarMapWheel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: EarMapWheel.entranceDuration,
  );
  late final List<FocusNode> _focusNodes = List.generate(
    chromaticNotes.length,
    (i) => FocusNode(debugLabel: 'ear-map-${chromaticNotes[i]}'),
  );
  int? _hovered;
  int? _focused;
  bool _entranceStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceStarted) return;
    _entranceStarted = true;
    if (motionDuration(context, EarMapWheel.entranceDuration) ==
        Duration.zero) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  List<_Segment> _segments() {
    final byNote = {for (final s in widget.summaries) s.note: s};
    return [
      for (final note in chromaticNotes)
        () {
          final summary =
              byNote[note] ??
              NoteProgressSummary(
                note: note,
                isLearning: true,
                consecutiveCorrect: 0,
                timesSeen: 0,
                timesCorrect: 0,
                weight: 1,
                isOverdue: false,
              );
          return _Segment(
            summary: summary,
            label: formatNoteLabel(note, widget.namingMode),
            seen: summary.timesSeen > 0,
            pct: summary.accuracyPercent,
            level: srsLevelForSummary(
              summary,
              learningThreshold: widget.learningThreshold,
            ),
          );
        }(),
    ];
  }

  void _setHovered(int? index, List<_Segment> segments) {
    if (_hovered == index) return;
    setState(() => _hovered = index);
    widget.onHover?.call(index == null ? null : segments[index].summary);
  }

  void _setFocused(int index, bool focused, List<_Segment> segments) {
    setState(() {
      if (focused) {
        _focused = index;
      } else if (_focused == index) {
        _focused = null;
      }
    });
    widget.onHover?.call(
      focused
          ? segments[index].summary
          : (_hovered == null ? null : segments[_hovered!].summary),
    );
  }

  void _select(int index, List<_Segment> segments) {
    widget.onSelect?.call(segments[index].summary);
  }

  KeyEventResult _onKey(int index, KeyEvent event, List<_Segment> segments) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _select(index, segments);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = TogescColors.of(context);
    final segments = _segments();
    final geometry = _WheelGeometry(compact: widget.compact);

    final track = widget.onDark ? colors.earMapTrackOnHero : colors.earMapTrack;
    final labelColor = widget.onDark ? DesignTokens.onHero : colors.textPrimary;
    final captionColor = widget.onDark
        ? DesignTokens.sessionTextLabel
        : colors.textSecondary;
    final ring = widget.onDark ? DesignTokens.onHeroAccent : colors.brand;
    final highlight = widget.onDark
        ? Colors.white.withValues(alpha: 0.16)
        : Color.alphaBlend(colors.brand.withValues(alpha: 0.14), track);

    final active = _focused ?? _hovered;
    final selectedIndex = widget.selectedNote == null
        ? null
        : chromaticNotes.indexOf(widget.selectedNote!);

    return Semantics(
      key: const ValueKey('ear-map'),
      container: true,
      explicitChildNodes: true,
      label: 'Mapa del oído: dominio de las 12 notas',
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.biggest.shortestSide;
            final scale = side / DesignTokens.earMapViewBox;
            final labelSize = 13 * scale.clamp(0.8, 1.4);

            // Tab en orden cromático (C → B), no geométrico.
            return FocusTraversalGroup(
              policy: WidgetOrderTraversalPolicy(),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: AnimatedBuilder(
                        animation: _entrance,
                        builder: (context, _) => CustomPaint(
                          painter: _EarMapPainter(
                            segments: segments,
                            geometry: geometry,
                            progress: _entrance.value,
                            track: track,
                            highlight: highlight,
                            ring: ring,
                            activeIndex: active,
                            focusedIndex: _focused,
                            selectedIndex: (selectedIndex ?? -1) < 0
                                ? null
                                : selectedIndex,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Etiquetas de nota fuera del anillo.
                  for (var i = 0; i < segments.length; i++)
                    _positionedLabel(
                      geometry.labelCenter(i) * scale,
                      ExcludeSemantics(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            segments[i].label,
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: labelSize,
                              fontWeight: FontWeight.w800,
                              color: labelColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Centro.
                  Positioned.fromRect(
                    rect: Rect.fromCircle(
                      center: Offset(side / 2, side / 2),
                      radius: (geometry.r0 - 8) * scale,
                    ),
                    child: ExcludeSemantics(
                      child: _Center(
                        segment: active == null ? null : segments[active],
                        value: widget.centerValue,
                        caption: widget.centerCaption,
                        valueColor: labelColor,
                        captionColor: captionColor,
                        textTheme: theme.textTheme,
                      ),
                    ),
                  ),
                  // Segmentos interactivos (encima, recortados a su sector).
                  for (var i = 0; i < segments.length; i++)
                    _interactiveSegment(i, segments, geometry, scale),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _positionedLabel(Offset center, Widget child) {
    const box = 48.0;
    return Positioned(
      left: center.dx - box / 2,
      top: center.dy - box / 2,
      width: box,
      height: box,
      child: Center(child: child),
    );
  }

  Widget _interactiveSegment(
    int i,
    List<_Segment> segments,
    _WheelGeometry geometry,
    double scale,
  ) {
    final path = _WheelGeometry.sector(
      geometry.r0,
      geometry.hitOuter,
      i * _WheelGeometry.step - _WheelGeometry.step / 2,
      (i + 1) * _WheelGeometry.step - _WheelGeometry.step / 2,
    ).transform(Matrix4.diagonal3Values(scale, scale, 1).storage);
    final bounds = path.getBounds();
    final local = path.shift(-bounds.topLeft);
    final segment = segments[i];
    final interactive = widget.onSelect != null;

    return Positioned.fromRect(
      rect: bounds,
      child: Semantics(
        key: ValueKey('ear-map-segment-${segment.summary.note}'),
        button: interactive,
        selected: widget.selectedNote == segment.summary.note,
        label: NoteMasteryCell.semanticsLabelFor(
          segment.summary,
          namingMode: widget.namingMode,
          learningThreshold: widget.learningThreshold,
        ),
        onTap: interactive ? () => _select(i, segments) : null,
        excludeSemantics: true,
        child: Focus(
          focusNode: _focusNodes[i],
          canRequestFocus: interactive,
          onFocusChange: (f) => _setFocused(i, f, segments),
          onKeyEvent: (_, event) => _onKey(i, event, segments),
          child: ClipPath(
            clipper: _PathClipper(local),
            child: MouseRegion(
              cursor: interactive
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              onEnter: (_) => _setHovered(i, segments),
              onExit: (_) => _setHovered(null, segments),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: interactive
                    ? () {
                        _focusNodes[i].requestFocus();
                        _select(i, segments);
                      }
                    : null,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PathClipper extends CustomClipper<Path> {
  const _PathClipper(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(covariant _PathClipper oldClipper) =>
      oldClipper.path != path;
}

class _Center extends StatelessWidget {
  const _Center({
    required this.segment,
    required this.value,
    required this.caption,
    required this.valueColor,
    required this.captionColor,
    required this.textTheme,
  });

  final _Segment? segment;
  final String? value;
  final String? caption;
  final Color valueColor;
  final Color captionColor;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final s = segment;
    final String? big;
    final String? small;
    if (s != null) {
      big = s.seen ? '${s.pct.round()} %' : '—';
      small = '${s.label} · nivel ${s.level}/$srsMaxLevel';
    } else {
      big = value;
      small = caption;
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (big != null)
            Text(
              big,
              key: const ValueKey('ear-map-center-value'),
              style: DesignTokens.bigNumber.copyWith(
                fontSize: 30,
                color: valueColor,
              ),
            ),
          if (small != null) ...[
            const SizedBox(height: DesignTokens.spacingXs),
            Text(
              small,
              key: const ValueKey('ear-map-center-caption'),
              style: textTheme.labelMedium?.copyWith(
                color: captionColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EarMapPainter extends CustomPainter {
  _EarMapPainter({
    required this.segments,
    required this.geometry,
    required this.progress,
    required this.track,
    required this.highlight,
    required this.ring,
    required this.activeIndex,
    required this.focusedIndex,
    required this.selectedIndex,
  });

  final List<_Segment> segments;
  final _WheelGeometry geometry;

  /// Progreso de la entrada escalonada (0–1 sobre la duración total).
  final double progress;
  final Color track;
  final Color highlight;
  final Color ring;
  final int? activeIndex;
  final int? focusedIndex;
  final int? selectedIndex;

  /// Escala y opacidad de la entrada del segmento [i] (0,55 → 1).
  (double, double) _entrance(int i) {
    if (progress >= 1) return (1, 1);
    final total = EarMapWheel.entranceDuration.inMicroseconds;
    final start = (EarMapWheel.entranceDelay + DesignTokens.staggerWheel * i)
        .inMicroseconds;
    final local =
        ((progress * total - start) /
                EarMapWheel.segmentDuration.inMicroseconds)
            .clamp(0.0, 1.0);
    final eased = DesignTokens.easeSpring.transform(local);
    return (0.55 + 0.45 * eased, local.clamp(0.0, 1.0));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / DesignTokens.earMapViewBox;
    canvas.save();
    canvas.scale(scale);
    const c = Offset(_WheelGeometry.center, _WheelGeometry.center);

    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      final a0 = geometry.startAngle(i);
      final a1 = geometry.endAngle(i);
      final trackPath = _WheelGeometry.sector(geometry.r0, geometry.r1, a0, a1);

      canvas.drawPath(
        trackPath,
        Paint()..color = i == activeIndex ? highlight : track,
      );

      final (segScale, opacity) = _entrance(i);
      if (opacity > 0) {
        final rf = geometry.r0 + (geometry.r1 - geometry.r0) * s.fill;
        final fillColor = s.seen
            ? masteryColor(s.pct, srsLevel: s.level)
            : track;
        if (s.seen) {
          canvas.save();
          canvas.translate(c.dx, c.dy);
          canvas.scale(segScale);
          canvas.translate(-c.dx, -c.dy);
          canvas.drawPath(
            _WheelGeometry.sector(geometry.r0, rf, a0, a1),
            Paint()..color = fillColor.withValues(alpha: opacity),
          );
          canvas.restore();
        }
      }

      if (i == focusedIndex) {
        canvas.drawPath(
          trackPath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = ring,
        );
      } else if (i == selectedIndex) {
        canvas.drawPath(
          trackPath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = ring,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EarMapPainter old) =>
      old.progress != progress ||
      old.segments != segments ||
      old.track != track ||
      old.activeIndex != activeIndex ||
      old.focusedIndex != focusedIndex ||
      old.selectedIndex != selectedIndex ||
      old.ring != ring ||
      old.highlight != highlight ||
      old.geometry.compact != geometry.compact;
}
