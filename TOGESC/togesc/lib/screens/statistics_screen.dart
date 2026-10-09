import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/togesc_colors.dart';
import '../app/router.dart';
import '../constants/game_constants.dart';
import '../constants/note_naming.dart';
import '../models/note_progress_summary.dart';
import '../models/practice_session_log.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/clock_provider.dart';
import '../providers/practice_focus_provider.dart';
import '../providers/session_history_provider.dart';
import '../providers/srs_provider.dart';
import '../providers/today_session_provider.dart';
import '../services/progress_export_download.dart';
import '../services/progress_export_service.dart';
import '../utils/session_history_stats.dart';
import '../widgets/info_views.dart';
import '../widgets/note_srs_detail_card.dart';
import '../widgets/progress_v2/global_accuracy_header.dart';
import '../widgets/progress_v2/note_mastery_grid.dart';
import '../widgets/progress_v2/progress_access.dart';
import '../widgets/progress_v2/progress_kpi_row.dart';
import '../widgets/progress_v2/progress_metrics.dart';
import '../widgets/progress_v2/recent_sessions_list.dart';
import '../widgets/progress_v2/session_history_page.dart';
import '../widgets/session_evolution_chart.dart';
import '../widgets/stats_free_dashboard.dart';
import '../widgets/togesc_ui.dart';

/// Progreso v2 (pantalla 1c): precisión global, KPI, rejilla de 12 notas
/// (gratis, D7), últimas sesiones y, debajo, la sección Pro de evolución.
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  /// Ancho máximo del contenido en web/escritorio.
  static const double maxContentWidth = 720;

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  StatsPeriod _period = StatsPeriod.days7;

  @override
  Widget build(BuildContext context) {
    final srsState = ref.watch(srsSystemProvider);
    if (srsState.isLoading && !srsState.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (srsState.hasError && !srsState.hasValue) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No se pudo cargar tu progreso.'),
              const SizedBox(height: DesignTokens.spacingMd),
              FilledButton.icon(
                onPressed: () => ref.invalidate(srsSystemProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final stats = ref.watch(srsStatisticsProvider);
    if (stats.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Aún no hay estadísticas disponibles.')),
      );
    }

    final proAccess = ref.watch(progressProAccessProvider);
    final summaries = ref.watch(noteProgressSummariesProvider);
    final history = ref.watch(sessionHistoryProvider).valueOrNull ?? const [];
    final delta = ref.watch(weeklyAccuracyDeltaProvider);
    final now = ref.watch(clockProvider)();
    final naming =
        ref.watch(noteNamingModeProvider).valueOrNull ?? NoteNamingMode.letter;
    final learningThreshold = ref
            .watch(appPreferencesProvider)
            .valueOrNull
            ?.srsIntensityProfile
            .learningThreshold ??
        learningGraduationThreshold;

    final accuracy = (stats['accuracy_percentage'] as num?)?.toDouble() ?? 0.0;
    final totalSeen = stats['total_seen'] as int? ?? 0;
    final learningPhase = stats['learning_phase'] as int? ?? 0;
    final graduated = stats['graduated'] as int? ?? 0;
    final overdueCount = stats['overdue_count'] as int? ?? 0;
    final isNewUser = totalSeen == 0 && history.isEmpty;

    final grid = NoteMasteryGrid(
      summaries: summaries,
      consolidatedCount: graduated,
      inProgressCount: learningPhase,
      namingMode: naming,
      learningThreshold: learningThreshold,
      onNoteTap: (summary) => _showNoteDetail(context, summary, proAccess),
    );

    final children = <Widget>[
      Semantics(
        header: true,
        child: Text(
          'Progreso',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: -0.4,
              ),
        ),
      ),
      const SizedBox(height: DesignTokens.spacingLg),
      if (isNewUser) ...[
        _ProgressEmptyState(onStart: () => context.go(AppRoutes.home)),
        const SizedBox(height: DesignTokens.spacingLg),
        grid,
      ] else ...[
        GlobalAccuracyHeader(accuracy: accuracy, delta: delta),
        const SizedBox(height: DesignTokens.spacingLg),
        ProgressKpiRow(
          meanLatencySec: approximateMeanLatencySec(summaries),
          attempts: totalSeen,
          pending: overdueCount,
          onReviewPending: () => _startReviewPractice(context),
        ),
        const SizedBox(height: DesignTokens.spacingLg),
        grid,
        const SizedBox(height: DesignTokens.spacingLg),
        RecentSessionsList(
          entries: history,
          now: now,
          historyUnlocked: proAccess,
          onOpenHistory: () => _openHistory(context, proAccess),
        ),
        const SizedBox(height: DesignTokens.spacingLg),
        ..._buildProSection(context, history, now, proAccess),
        const SizedBox(height: DesignTokens.spacingLg),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => confirmAndResetProgress(context, ref),
            icon: Icon(
              Icons.restart_alt_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            label: Text(
              'Reiniciar progreso',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ],
    ];

    return Scaffold(
      body: SafeArea(
        top: false,
        child: TogescPageBody(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: StatisticsScreen.maxContentWidth,
              ),
              child: Column(
                key: const Key('progress-content'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Sección Pro (D7): evolución por periodo y exportación. Gratis: candado.
  List<Widget> _buildProSection(
    BuildContext context,
    List<PracticeSessionLog> history,
    DateTime now,
    bool proAccess,
  ) {
    final theme = Theme.of(context);
    final header = Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              'Evolución',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingSm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: DesignTokens.pro,
            borderRadius: DesignTokens.borderRadiusPill,
          ),
          child: Text(
            'PRO',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );

    if (!proAccess) {
      return [
        header,
        const SizedBox(height: DesignTokens.spacingSm),
        StatsFreeProUpsellCard(onTap: () => _openPaywall(context)),
      ];
    }

    final summaries = buildPracticeSummariesForPeriod(
      history,
      period: _period,
      now: now,
    );
    final hasActivity = summaries.any((day) => day.hasActivity);

    return [
      header,
      const SizedBox(height: DesignTokens.spacingSm),
      Align(
        alignment: Alignment.centerLeft,
        child: SegmentedButton<StatsPeriod>(
          segments: [
            for (final p in StatsPeriod.values)
              ButtonSegment(value: p, label: Text(p.label)),
          ],
          selected: {_period},
          onSelectionChanged: (next) {
            if (next.isEmpty) return;
            setState(() => _period = next.first);
          },
        ),
      ),
      const SizedBox(height: DesignTokens.spacingMd),
      if (hasActivity)
        SessionEvolutionChart(
          summaries: summaries,
          title: 'Precisión diaria · ${_period.label}',
        )
      else
        TogescCard(
          child: Text(
            'Sin sesiones en este periodo.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      const SizedBox(height: DesignTokens.spacingMd),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => _exportProgress(context),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Exportar progreso (CSV)'),
        ),
      ),
    ];
  }

  void _openPaywall(BuildContext context) {
    context.push('${AppRoutes.paywall}?feature=historial');
  }

  void _openHistory(BuildContext context, bool proAccess) {
    if (!proAccess) {
      _openPaywall(context);
      return;
    }
    Navigator.of(context).push(SessionHistoryPage.route());
  }

  void _startReviewPractice(BuildContext context) {
    ref.read(practiceFocusNoteProvider.notifier).state = null;
    context.push('${AppRoutes.game}/${GameMode.singleNote.id}');
  }

  void _showNoteDetail(
    BuildContext context,
    NoteProgressSummary summary,
    bool proAccess,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.spacingLg,
            0,
            DesignTokens.spacingLg,
            DesignTokens.spacingLg,
          ),
          child: NoteSrsDetailCard(
            summary: summary,
            showAdvanced: proAccess,
            onPractice: () {
              Navigator.of(sheetContext).pop();
              startFocusedNotePractice(
                context: context,
                ref: ref,
                note: summary.note,
              );
            },
          ),
        ),
      ),
    );
  }

  void _exportProgress(BuildContext context) {
    final srs = ref.read(srsSystemProvider).valueOrNull;
    if (srs == null) return;

    final csv = ProgressExportService.buildCsv(srs);
    if (kIsWeb) {
      downloadCsvWeb(csv);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Descarga CSV iniciada')));
    } else {
      Clipboard.setData(ClipboardData(text: csv));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progreso copiado al portapapeles')),
      );
    }
  }
}

class _ProgressEmptyState extends StatelessWidget {
  const _ProgressEmptyState({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      key: const Key('progress-empty-state'),
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      decoration: BoxDecoration(
        color: TogescColors.of(context).tile,
        borderRadius: DesignTokens.borderRadiusCard,
        border: Border.all(color: TogescColors.of(context).cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.insights_rounded, color: scheme.primary, size: 32),
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            'Aún no hay progreso',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXs),
          Text(
            'Haz tu primera sesión y aquí verás tu precisión, tu latencia '
            'y el dominio de cada una de las 12 notas.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Empezar a practicar'),
          ),
        ],
      ),
    );
  }
}
