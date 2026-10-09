import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/togesc_colors.dart';
import '../../utils/relative_time.dart';
import '../../utils/today_session.dart';

/// Detalle de la fila «Retomar»: «8 rondas · hace 2 h» (o solo la hora si la
/// última entrada al modo no llegó a registrar rondas).
String resumeDetailText(ResumeSessionInfo info, DateTime now) {
  final when = formatRelativeTimeEs(info.at, now: now);
  final rounds = info.rounds;
  if (rounds == null || rounds <= 0) return when;
  final roundsLabel = rounds == 1 ? '1 ronda' : '$rounds rondas';
  return '$roundsLabel · $when';
}

/// Fila «Retomar «modo»» con borde discontinuo y chevron.
class ResumeRow extends StatelessWidget {
  final ResumeSessionInfo info;
  final DateTime now;
  final bool locked;
  final VoidCallback onTap;

  const ResumeRow({
    super.key,
    required this.info,
    required this.now,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = TogescColors.of(context);
    final detail = resumeDetailText(info, now);
    final title = 'Retomar «${info.label}»';

    return Semantics(
      button: true,
      label: '$title. $detail${locked ? '. Requiere Pro' : ''}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('home-resume-row'),
          onTap: onTap,
          borderRadius: DesignTokens.borderRadiusCard,
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: colors.cardBorder,
              radius: DesignTokens.radiusCard,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingLg,
                vertical: DesignTokens.spacingMd,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.muted,
                      borderRadius: DesignTokens.borderRadiusCell,
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      size: 20,
                      color: colors.brand,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detail,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (locked) ...[
                    Icon(
                      Icons.lock_rounded,
                      size: 18,
                      color: colors.proAccent,
                    ),
                    const SizedBox(width: DesignTokens.spacingXs),
                  ],
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 6.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    ).deflate(0.75);
    final path = Path()..addRRect(rect);
    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dash),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
