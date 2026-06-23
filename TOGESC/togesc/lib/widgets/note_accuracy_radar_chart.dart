import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../models/note_progress_summary.dart';

/// Radar de precision por las 12 notas (Stitch).
class NoteAccuracyRadarChart extends StatelessWidget {
  final List<NoteProgressSummary> summaries;

  const NoteAccuracyRadarChart({super.key, required this.summaries});

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 220,
      child: CustomPaint(
        painter: _RadarPainter(summaries: summaries),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<NoteProgressSummary> summaries;

  _RadarPainter({required this.summaries});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 16;
    final gridPaint = Paint()
      ..color = DesignTokens.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final level in [0.33, 0.66, 1.0]) {
      canvas.drawCircle(center, radius * level, gridPaint);
    }

    final n = summaries.length;
    if (n == 0) return;

    final points = <Offset>[];
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / n);
      final value = (summaries[i].accuracyPercent / 100).clamp(0.0, 1.0);
      final r = radius * (0.15 + value * 0.85);
      points.add(
        Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        ),
      );
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
        gridPaint,
      );
    }

    final fillPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      fillPath.lineTo(points[i].dx, points[i].dy);
    }
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = DesignTokens.primary.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      fillPath,
      Paint()
        ..color = DesignTokens.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final nodePaint = Paint()..color = DesignTokens.primary;
    for (final p in points) {
      canvas.drawCircle(p, 3, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.summaries != summaries;
}
