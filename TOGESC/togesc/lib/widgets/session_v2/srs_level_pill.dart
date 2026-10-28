import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../utils/srs_level.dart';

/// Píldora «{nota} SRS 3/5 → 4/5» con 5 puntos de nivel (fase `result`).
///
/// Los puntos no son la única señal: el texto «n/5» siempre está visible y
/// la píldora expone una etiqueta semántica completa.
class SrsLevelPill extends StatelessWidget {
  final String noteLabel;
  final SrsLevelChange change;

  const SrsLevelPill({
    super.key,
    required this.noteLabel,
    required this.change,
  });

  Color get _trendColor {
    if (change.improved) return DesignTokens.sessionSuccess;
    if (change.dropped) return DesignTokens.sessionError;
    return DesignTokens.sessionAccent;
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: DesignTokens.sessionTextPrimary,
          fontWeight: FontWeight.w700,
        ).merge(DesignTokens.tabularNumbers);
    final semantics = '$noteLabel: nivel SRS de ${change.before} a '
        '${change.after} de $srsMaxLevel';

    return Semantics(
      label: semantics,
      container: true,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMd,
            vertical: DesignTokens.spacingSm,
          ),
          decoration: BoxDecoration(
            color: DesignTokens.sessionChip,
            borderRadius: DesignTokens.borderRadiusPill,
            border: Border.all(color: DesignTokens.sessionBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(noteLabel, style: textStyle),
              const SizedBox(width: DesignTokens.spacingSm),
              Text(
                'SRS ${change.before}/$srsMaxLevel → '
                '${change.after}/$srsMaxLevel',
                style: textStyle?.copyWith(
                  color: DesignTokens.sessionTextLabel,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingSm),
              SrsLevelDots(level: change.after, color: _trendColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cinco puntos de nivel SRS (rellenos hasta [level]).
class SrsLevelDots extends StatelessWidget {
  final int level;
  final Color color;
  final double dotSize;

  const SrsLevelDots({
    super.key,
    required this.level,
    this.color = DesignTokens.sessionAccent,
    this.dotSize = 7,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(srsMaxLevel, (i) {
        final filled = i < level;
        return Container(
          width: dotSize,
          height: dotSize,
          margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : Colors.transparent,
            border: Border.all(
              color: filled ? color : DesignTokens.sessionTextSecondary,
              width: 1.2,
            ),
          ),
        );
      }),
    );
  }
}
