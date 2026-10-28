import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../app/togesc_colors.dart';
import '../models/practice_session_log.dart';
import '../utils/session_history_stats.dart';
import 'togesc_ui.dart';

/// Grafico de barras de precision diaria (Fase 7C-3).
class SessionEvolutionChart extends StatelessWidget {
  const SessionEvolutionChart({
    super.key,
    required this.summaries,
    this.title = 'Evolución 7 días',
  });

  final List<DayPracticeSummary> summaries;

  /// Título de la card (el periodo lo elige la pantalla).
  final String title;

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final maxRounds = summaries
        .map((day) => day.rounds)
        .fold<int>(0, (max, value) => value > max ? value : max);

    return TogescCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Precisión diaria y rondas practicadas (historial local).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: summaries.map((day) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _DayBar(summary: day, maxRounds: maxRounds),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({required this.summary, required this.maxRounds});

  final DayPracticeSummary summary;
  final int maxRounds;

  Color _barColor(double accuracy, ColorScheme scheme, TogescColors colors) {
    if (!summary.hasActivity) {
      return scheme.onSurfaceVariant.withValues(alpha: 0.15);
    }
    if (accuracy >= 80) return colors.correct;
    if (accuracy >= 50) return colors.selection;
    return colors.incorrect;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = TogescColors.of(context);
    final barHeightFactor = maxRounds <= 0 || !summary.hasActivity
        ? 0.08
        : (summary.rounds / maxRounds).clamp(0.12, 1.0);
    final accuracy = summary.accuracyPercent;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (summary.hasActivity)
          Text(
            '${accuracy.round()}%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: _barColor(accuracy, scheme, colors),
              fontWeight: FontWeight.w600,
            ),
          )
        else
          const SizedBox(height: 14),
        const SizedBox(height: 4),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: barHeightFactor,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _barColor(accuracy, scheme, colors),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          weekdayShortLabel(summary.day),
          style: theme.textTheme.labelMedium,
        ),
        if (summary.hasActivity)
          Text(
            '${summary.rounds}r',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// Barras rellenas de precisión por sesión (Progreso v2.1, pestaña
/// Historial): las [maxSessions] más recientes, de la más antigua a la más
/// reciente. Alto = precisión; verde a partir del 75 %. El gráfico lleva un
/// texto alternativo con cada sesión (Semantics de imagen).
class SessionAccuracyBars extends StatelessWidget {
  const SessionAccuracyBars({
    super.key,
    required this.entries,
    this.maxSessions = 8,
  });

  /// Historial (en cualquier orden); se ordena por fecha de fin.
  final List<PracticeSessionLog> entries;
  final int maxSessions;

  /// Sesiones que se dibujan, de la más antigua a la más reciente.
  static List<PracticeSessionLog> visible(
    List<PracticeSessionLog> entries, {
    int maxSessions = 8,
  }) {
    final played = entries.where((e) => e.roundsCompleted > 0).toList()
      ..sort((a, b) => b.endedAt.compareTo(a.endedAt));
    return played.take(maxSessions).toList().reversed.toList();
  }

  /// Texto alternativo: «Precisión por sesión: Una nota, 9/10, 80 %; …».
  static String semanticsFor(List<PracticeSessionLog> sessions) {
    if (sessions.isEmpty) return 'Precisión por sesión: sin sesiones';
    final parts = [
      for (final s in sessions)
        '${s.modeLabel}, ${_shortDate(s.endedAt)}, '
            '${s.accuracyPercent.round()} %',
    ];
    return 'Precisión por sesión, de la más antigua a la más reciente: '
        '${parts.join('; ')}';
  }

  static String _shortDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day}/${local.month}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = TogescColors.of(context);
    final sessions = visible(entries, maxSessions: maxSessions);

    return TogescCard(
      child: Column(
        key: const Key('progress-history-chart'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Precisión por sesión',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ),
              Text(
                'Más antigua → más reciente',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          if (sessions.isEmpty)
            Text(
              'Aún no hay sesiones registradas.',
              style: theme.textTheme.bodyMedium,
            )
          else
            Semantics(
              container: true,
              label: semanticsFor(sessions),
              image: true,
              excludeSemantics: true,
              child: SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < sessions.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _SessionBar(
                            session: sessions[i],
                            index: i,
                            high: colors.correct,
                            normal: scheme.primary.withValues(alpha: 0.55),
                            track: colors.muted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionBar extends StatelessWidget {
  const _SessionBar({
    required this.session,
    required this.index,
    required this.high,
    required this.normal,
    required this.track,
  });

  final PracticeSessionLog session;
  final int index;
  final Color high;
  final Color normal;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = session.accuracyPercent;
    final color =
        pct >= DesignTokens.masteryGreenThreshold ? high : normal;
    final target = (pct / 100).clamp(0.04, 1.0);
    final delay = DesignTokens.staggerStep * index;
    final duration = motionDuration(
      context,
      const Duration(milliseconds: 600),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${pct.round()}',
          style: theme.textTheme.labelSmall
              ?.copyWith(fontWeight: FontWeight.w700)
              .merge(DesignTokens.tabularNumbers),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: track,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: target),
                duration: duration == Duration.zero
                    ? Duration.zero
                    : duration + delay,
                curve: duration == Duration.zero
                    ? Curves.linear
                    : Interval(
                        delay.inMilliseconds /
                            (duration + delay).inMilliseconds,
                        1,
                        curve: DesignTokens.easeOut,
                      ),
                builder: (context, value, _) => FractionallySizedBox(
                  heightFactor: value,
                  widthFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          SessionAccuracyBars._shortDate(session.endedAt),
          maxLines: 1,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
