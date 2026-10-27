import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../constants/note_naming.dart';
import '../../models/note_progress_summary.dart';
import '../../utils/session_summary.dart';
import '../../utils/srs_level.dart';
import '../count_up_text.dart';
import '../ear_map/ear_map_wheel.dart';
import '../progress_v2/progress_metrics.dart';
import '../staggered_entrance.dart';
import 'srs_level_pill.dart';

/// Resumen al terminar la sesión (SPEC v2.1 §2.2.7, clave `session-summary`).
///
/// Medalla según la precisión, KPI (precisión, aciertos y tiempo medio
/// medido), cambios de nivel SRS por nota de la sesión, rueda del mapa del
/// oído con los datos ya actualizados y las acciones finales. Todo sale de
/// datos reales (D10): sin tiempo medido se muestra «—».
class SessionSummaryView extends StatelessWidget {
  const SessionSummaryView({
    super.key,
    required this.rounds,
    required this.correctRounds,
    required this.meanResponseTimeSec,
    required this.changes,
    required this.summaries,
    required this.onHome,
    required this.onProgress,
    this.namingMode = NoteNamingMode.letter,
    this.learningThreshold = 5,
  });

  final int rounds;
  final int correctRounds;
  final double? meanResponseTimeSec;
  final List<SessionLevelChange> changes;
  final List<NoteProgressSummary> summaries;
  final VoidCallback onHome;
  final VoidCallback onProgress;
  final NoteNamingMode namingMode;
  final int learningThreshold;

  /// Desfase de las filas de cambios de nivel.
  static const Duration changeStagger = Duration(milliseconds: 90);

  double get accuracyPercent =>
      rounds > 0 ? correctRounds / rounds * 100 : 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medal = SessionMedal.forAccuracy(accuracyPercent);
    final acc = accuracyPercent.round();
    final overline = DesignTokens.overline.copyWith(
      color: DesignTokens.sessionTextLabel,
    );

    final changesColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('CAMBIOS DE NIVEL SRS', style: overline),
        const SizedBox(height: DesignTokens.spacingSm + 2),
        if (changes.isEmpty)
          Text(
            'Esta sesión no tocó ninguna nota del SRS.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: DesignTokens.sessionTextSecondary,
            ),
          )
        else
          for (var i = 0; i < changes.length; i++)
            StaggeredEntrance(
              index: i,
              step: changeStagger,
              child: _ChangeRow(
                change: changes[i],
                namingMode: namingMode,
              ),
            ),
      ],
    );

    final wheelColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('TU MAPA DEL OÍDO', style: overline),
        const SizedBox(height: DesignTokens.spacingSm + 2),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: EarMapWheel(
              summaries: summaries,
              namingMode: namingMode,
              learningThreshold: learningThreshold,
              compact: true,
            ),
          ),
        ),
      ],
    );

    return SingleChildScrollView(
      key: const ValueKey('session-summary'),
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.marginMobile,
        DesignTokens.spacingLg,
        DesignTokens.marginMobile,
        DesignTokens.marginDesktop,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera con medalla.
              _MedalBadge(medal: medal),
              const SizedBox(height: DesignTokens.spacingMd),
              Text(
                'SESIÓN COMPLETADA',
                textAlign: TextAlign.center,
                style: DesignTokens.overlineLarge.copyWith(
                  color: DesignTokens.sessionAccent,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingXs),
              Semantics(
                liveRegion: true,
                header: true,
                label: 'Sesión completada. ${medal.headline}. '
                    '$correctRounds de $rounds aciertos, $acc por ciento.',
                child: ExcludeSemantics(
                  child: Text(
                    medal.headline,
                    key: const ValueKey('session-summary-headline'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: DesignTokens.sessionTextPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingSm),
              Text(
                sessionSummaryLead(changes),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.sessionTextSecondary,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingLg + 4),
              // KPI.
              Row(
                children: [
                  Expanded(
                    child: _Kpi(
                      key: const ValueKey('session-summary-accuracy'),
                      label: 'Precisión',
                      semantics: 'Precisión, $acc por ciento',
                      child: CountUpText(
                        value: accuracyPercent,
                        format: (v) => '${v.round()} %',
                        style: _kpiStyle,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingSm),
                  Expanded(
                    child: _Kpi(
                      key: const ValueKey('session-summary-hits'),
                      label: 'Aciertos',
                      semantics: 'Aciertos, $correctRounds de $rounds',
                      child: Text('$correctRounds/$rounds', style: _kpiStyle),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingSm),
                  Expanded(
                    child: _Kpi(
                      key: const ValueKey('session-summary-latency'),
                      label: 'Tiempo medio',
                      semantics: meanResponseTimeSec == null
                          ? 'Tiempo medio de respuesta, sin datos'
                          : 'Tiempo medio de respuesta, '
                              '${formatSecondsEs(meanResponseTimeSec!)}',
                      child: Text(
                        meanResponseTimeSec == null
                            ? '—'
                            : formatSecondsEs(meanResponseTimeSec!),
                        style: _kpiStyle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spacingLg + 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 720) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: changesColumn),
                        const SizedBox(width: DesignTokens.marginDesktop),
                        Expanded(child: wheelColumn),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      changesColumn,
                      const SizedBox(height: DesignTokens.spacingLg + 8),
                      wheelColumn,
                    ],
                  );
                },
              ),
              const SizedBox(height: DesignTokens.spacingLg + 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: DesignTokens.spacingMd,
                runSpacing: DesignTokens.spacingSm,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('session-summary-home'),
                    onPressed: onHome,
                    style: FilledButton.styleFrom(
                      backgroundColor: DesignTokens.sessionAmber,
                      foregroundColor: DesignTokens.sessionOnAccent,
                      minimumSize: const Size(200, DesignTokens.touchTargetMin),
                      shape: RoundedRectangleBorder(
                        borderRadius: DesignTokens.borderRadiusCta,
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Volver al inicio'),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('session-summary-progress'),
                    onPressed: onProgress,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DesignTokens.sessionTextPrimary,
                      side: const BorderSide(
                        color: DesignTokens.sessionBorder,
                      ),
                      minimumSize: const Size(200, DesignTokens.touchTargetMin),
                      shape: RoundedRectangleBorder(
                        borderRadius: DesignTokens.borderRadiusCta,
                      ),
                    ),
                    icon: const Icon(Icons.insights_rounded),
                    label: const Text('Ver mi progreso'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _kpiStyle = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w800,
  color: DesignTokens.sessionTextPrimary,
  fontFeatures: [FontFeature.tabularFigures()],
);

class _MedalBadge extends StatelessWidget {
  const _MedalBadge({required this.medal});

  final SessionMedal medal;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          key: const ValueKey('session-summary-medal'),
          tween: Tween(begin: 0.4, end: 1),
          duration: motionDuration(context, const Duration(milliseconds: 600)),
          curve: DesignTokens.easeSpring,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.alphaBlend(
                DesignTokens.sessionAmber.withValues(alpha: 0.16),
                DesignTokens.sessionSurface,
              ),
            ),
            child: Icon(medal.icon, size: 40, color: DesignTokens.sessionAmber),
          ),
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    super.key,
    required this.label,
    required this.semantics,
    required this.child,
  });

  final String label;
  final String semantics;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semantics,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: DesignTokens.spacingMd,
          horizontal: DesignTokens.spacingSm,
        ),
        decoration: BoxDecoration(
          color: DesignTokens.sessionSurface,
          borderRadius: DesignTokens.borderRadiusCard,
          border: Border.all(color: DesignTokens.sessionBorder),
        ),
        child: Column(
          children: [
            FittedBox(fit: BoxFit.scaleDown, child: child),
            const SizedBox(height: DesignTokens.spacingXs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: DesignTokens.sessionTextSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.change, required this.namingMode});

  final SessionLevelChange change;
  final NoteNamingMode namingMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = formatNoteLabel(change.note, namingMode);
    final spoken = spokenNoteName(label);
    final pct = change.accuracyAfter;
    final cell = pct == null
        ? DesignTokens.sessionChip
        : masteryColor(pct, srsLevel: change.after);
    final ink = pct == null
        ? DesignTokens.sessionTextPrimary
        : masteryOnColor(pct, srsLevel: change.after);
    final (IconData icon, Color color, String trend) = change.improved
        ? (Icons.arrow_upward_rounded, DesignTokens.sessionSuccess, 'sube')
        : change.dropped
            ? (Icons.arrow_downward_rounded, DesignTokens.sessionError, 'baja')
            : (Icons.remove_rounded, DesignTokens.sessionTextSecondary, 'igual');

    return Semantics(
      key: ValueKey('session-summary-change-${change.note}'),
      container: true,
      label: '$spoken: nivel ${change.before} a ${change.after} de '
          '$srsMaxLevel, $trend',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXs),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cell,
                borderRadius: DesignTokens.borderRadiusCell,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w800, color: ink),
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spoken,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: DesignTokens.sessionTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Nivel ${change.before} → ${change.after}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: DesignTokens.sessionTextSecondary)
                        .merge(DesignTokens.tabularNumbers),
                  ),
                ],
              ),
            ),
            SrsLevelDots(level: change.after),
            const SizedBox(width: DesignTokens.spacingSm),
            Icon(icon, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}
