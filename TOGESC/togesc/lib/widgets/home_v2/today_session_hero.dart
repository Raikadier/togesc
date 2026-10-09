import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../providers/today_session_provider.dart';
import '../../utils/today_session.dart';

/// Texto del hero derivado solo de datos reales del SRS (D10).
///
/// - Sin notas de foco (SRS vacío o cargando): primera sesión.
/// - Ninguna nota vista: usuario nuevo, se empieza por notas naturales.
/// - Menos de 3 vistas: se dice cuántas tienen datos.
/// - Todas vistas: el motivo real de la selección (atrasadas, en
///   aprendizaje o menor precisión).
String todayHeroCopy(List<TodayFocusNote> focus) {
  if (focus.isEmpty) {
    return 'Tu primera sesión le dará al SRS los datos para elegir tu foco.';
  }
  final seen = focus.where((f) => f.accuracyPercent != null).length;
  if (seen == 0) {
    return 'Aún no hay datos de precisión: empezarás por notas naturales '
        'para que el SRS conozca tu oído.';
  }
  if (seen < focus.length) {
    final notas = seen == 1 ? '1 nota' : '$seen notas';
    return 'El SRS solo tiene datos de $notas; el resto del foco son notas '
        'nuevas.';
  }
  final count = focus.length == 3 ? 'las tres notas' : 'las notas';
  if (focus.any((f) => f.isCritical || f.isOverdue)) {
    return 'El SRS priorizó $count atrasadas o con menor precisión.';
  }
  if (focus.any((f) => f.isLearning)) {
    return 'El SRS priorizó $count en aprendizaje o con menor precisión.';
  }
  return 'El SRS priorizó $count con menor precisión.';
}

/// Card hero «Sesión de hoy» (#2A0640) del Home v2.
class TodaySessionHero extends StatelessWidget {
  final TodaySessionPlan plan;
  final VoidCallback onStart;
  final VoidCallback onAdjust;

  const TodaySessionHero({
    super.key,
    required this.plan,
    required this.onStart,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rounds = plan.rounds;
    final minutes = plan.estimatedMinutes;

    final String summarySemantics;
    if (rounds > 0) {
      summarySemantics = minutes == null
          ? '$rounds rondas'
          : '$rounds rondas, unos $minutes minutos estimados';
    } else {
      summarySemantics = 'Sesión sin límite de rondas';
    }

    return Container(
      key: const ValueKey('today-session-hero'),
      decoration: BoxDecoration(
        color: DesignTokens.hero,
        borderRadius: DesignTokens.borderRadiusHero,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            right: -24,
            top: -18,
            child: ExcludeSemantics(
              child: Icon(
                Icons.graphic_eq_rounded,
                size: 150,
                color: Color(0x14FFFFFF),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'SESIÓN DE HOY',
                  semanticsLabel: 'Sesión de hoy',
                  style: DesignTokens.overline.copyWith(
                    color: DesignTokens.onHeroAccent,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingSm),
                Semantics(
                  label: summarySemantics,
                  excludeSemantics: true,
                  child: _RoundsSummary(rounds: rounds, minutes: minutes),
                ),
                const SizedBox(height: DesignTokens.spacingMd),
                Text(
                  todayHeroCopy(plan.focusNotes),
                  key: const ValueKey('today-hero-copy'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: DesignTokens.onHero.withValues(alpha: 0.86),
                    height: 1.4,
                  ),
                ),
                if (plan.focusNotes.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.spacingLg),
                  Row(
                    children: [
                      for (var i = 0; i < plan.focusNotes.length; i++) ...[
                        if (i > 0) const SizedBox(width: DesignTokens.spacingSm),
                        Expanded(
                          child: FocusNoteMiniCard(note: plan.focusNotes[i]),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: DesignTokens.ctaHeight,
                  child: FilledButton.icon(
                    key: const ValueKey('today-start-cta'),
                    onPressed: onStart,
                    style: FilledButton.styleFrom(
                      backgroundColor: DesignTokens.ctaAmber,
                      foregroundColor: DesignTokens.onCtaAmber,
                      shape: RoundedRectangleBorder(
                        borderRadius: DesignTokens.borderRadiusCta,
                      ),
                      textStyle: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 26),
                    label: const Text('Empezar sesión'),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                Center(
                  child: TextButton(
                    key: const ValueKey('today-adjust-link'),
                    onPressed: onAdjust,
                    style: TextButton.styleFrom(
                      foregroundColor: DesignTokens.onHeroAccent,
                      minimumSize: const Size(
                        DesignTokens.touchTargetMin,
                        DesignTokens.touchTargetMin,
                      ),
                    ),
                    child: const Text(
                      'Ajustar enfoque y duración',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationColor: DesignTokens.onHeroAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundsSummary extends StatelessWidget {
  final int rounds;
  final int? minutes;

  const _RoundsSummary({required this.rounds, required this.minutes});

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: DesignTokens.onHero.withValues(alpha: 0.86),
          fontWeight: FontWeight.w600,
        );
    if (rounds <= 0) {
      return Text('Sin límite de rondas', style: secondary);
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: DesignTokens.spacingSm,
      children: [
        Text(
          '$rounds',
          style: DesignTokens.bigNumber.copyWith(color: DesignTokens.onHero),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            minutes == null
                ? 'rondas'
                : 'rondas · ≈ $minutes min (estimado)',
            style: secondary,
          ),
        ),
      ],
    );
  }
}

/// Mini-card de una nota de foco: nombre, barra de 3 px y %.
class FocusNoteMiniCard extends StatelessWidget {
  final TodayFocusNote note;

  const FocusNoteMiniCard({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final pct = note.accuracyPercent;
    final textTheme = Theme.of(context).textTheme;
    final semantics = pct == null
        ? 'Nota ${note.note}: nueva, sin datos de precisión'
        : 'Nota ${note.note}: ${pct.round()} % de precisión';

    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Container(
        key: ValueKey('focus-note-${note.note}'),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: DesignTokens.borderRadiusCell,
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.note,
              style: textTheme.titleMedium?.copyWith(
                color: DesignTokens.onHero,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: DesignTokens.borderRadiusPill,
              child: SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  value: pct == null ? 0 : (pct / 100).clamp(0.0, 1.0),
                  backgroundColor: const Color(0x29FFFFFF),
                  color: pct == null
                      ? DesignTokens.onHeroAccent
                      : masteryBarColorOnDark(pct),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              pct == null ? 'Nueva' : '${pct.round()}%',
              style: textTheme.labelMedium?.copyWith(
                color: DesignTokens.onHero.withValues(alpha: 0.86),
                fontWeight: FontWeight.w700,
              ).merge(DesignTokens.tabularNumbers),
            ),
          ],
        ),
      ),
    );
  }
}
