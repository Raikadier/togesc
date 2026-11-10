import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/togesc_colors.dart';
import '../app/router.dart';
import '../constants/game_constants.dart';
import '../constants/note_naming.dart';
import '../constants/subscription_constants.dart';
import '../models/note_progress_summary.dart';
import '../models/practice_session_log.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/audio_preferences_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/clock_provider.dart';
import '../providers/practice_focus_provider.dart';
import '../providers/session_history_provider.dart';
import '../providers/srs_provider.dart';
import '../providers/today_session_provider.dart';
import '../services/progress_export_download.dart';
import '../services/progress_export_service.dart';
import '../utils/session_history_stats.dart';
import '../widgets/info_views.dart';
import '../widgets/note_srs_detail_card.dart' show startFocusedNotePractice;
import '../widgets/progress_v2/global_accuracy_header.dart';
import '../widgets/progress_v2/mastery_overview.dart';
import '../widgets/progress_v2/note_detail_sheet.dart';
import '../widgets/progress_v2/note_extremes.dart';
import '../widgets/progress_v2/progress_access.dart';
import '../widgets/progress_v2/progress_kpi_row.dart';
import '../widgets/progress_v2/progress_metrics.dart';
import '../widgets/progress_v2/progress_tabs.dart';
import '../widgets/progress_v2/recent_sessions_list.dart';
import '../widgets/session_history_card.dart';
import '../widgets/session_evolution_chart.dart';
import '../widgets/staggered_entrance.dart';
import '../widgets/stats_free_dashboard.dart';
import '../widgets/togesc_ui.dart';

/// Progreso v2.1 (SPEC §2.3): pestañas «Resumen | Historial».
///
/// - Resumen: precisión global (cuenta al cargar) con meta, KPI (Pendientes
///   abre la sesión de hoy), dominio por nota (rueda o rejilla; las dos en
///   escritorio, gratis D7), «Tus extremos» (Pro) y últimas sesiones.
/// - Historial (Pro, D7): precisión por sesión, evolución por periodo,
///   exportación y lista completa. Sin Pro, la invitación a Pro.
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  /// Ancho máximo del contenido en web/escritorio (rueda y rejilla caben
  /// lado a lado).
  static const double maxContentWidth = 960;

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  StatsPeriod _period = StatsPeriod.days7;
  ProgressTab _tab = ProgressTab.summary;

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

    void openNote(NoteProgressSummary summary) =>
        _showNoteDetail(context, summary, naming, learningThreshold);

    final mastery = MasteryOverview(
      summaries: summaries,
      consolidatedCount: graduated,
      inProgressCount: learningPhase,
      namingMode: naming,
      learningThreshold: learningThreshold,
      onNoteTap: openNote,
    );

    var index = 0;
    Widget rise(Widget child) =>
        StaggeredEntrance(index: index++, child: child);

    final summaryTab = <Widget>[
      if (isNewUser) ...[
        _ProgressEmptyState(onStart: () => context.go(AppRoutes.home)),
        const SizedBox(height: DesignTokens.spacingLg),
        mastery,
      ] else ...[
        rise(GlobalAccuracyHeader(accuracy: accuracy, delta: delta)),
        const SizedBox(height: DesignTokens.spacingLg),
        rise(
          ProgressKpiRow(
            meanLatencySec: approximateMeanLatencySec(summaries),
            attempts: totalSeen,
            pending: overdueCount,
            onReviewPending: () => _startTodaySession(context),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingLg),
        rise(mastery),
        const SizedBox(height: DesignTokens.spacingLg),
        rise(
          NoteExtremes(
            summaries: summaries,
            unlocked: proAccess,
            onUnlock: () => _openPaywall(context),
            onNoteTap: openNote,
            namingMode: naming,
            learningThreshold: learningThreshold,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingLg),
        rise(
          RecentSessionsList(
            entries: history,
            now: now,
            historyUnlocked: proAccess,
            onOpenHistory: () => _openHistory(context, proAccess),
          ),
        ),
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

    final historyTab = <Widget>[
      if (proAccess) ...[
        SessionAccuracyBars(entries: history),
        const SizedBox(height: DesignTokens.spacingLg),
      ],
      ..._buildProSection(context, history, now, proAccess),
      if (proAccess) ...[
        const SizedBox(height: DesignTokens.spacingLg),
        const SessionHistoryCard(),
      ],
    ];

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
      const SizedBox(height: DesignTokens.spacingMd),
      Align(
        alignment: Alignment.centerLeft,
        child: ProgressTabs(
          selected: _tab,
          onChanged: (tab) => setState(() => _tab = tab),
        ),
      ),
      const SizedBox(height: DesignTokens.spacingLg),
      Semantics(
        key: ValueKey('progress-panel-${_tab.name}'),
        role: SemanticsRole.tabPanel,
        label: _tab.label,
        explicitChildNodes: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _tab == ProgressTab.summary ? summaryTab : historyTab,
        ),
      ),
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
    context.push(
      '${AppRoutes.paywall}?feature=${SubscriptionConstants.historyFeatureKey}',
    );
  }

  /// «Historial» en Últimas sesiones: con Pro cambia de pestaña; sin Pro,
  /// paywall (D7).
  void _openHistory(BuildContext context, bool proAccess) {
    if (!proAccess) {
      _openPaywall(context);
      return;
    }
    setState(() => _tab = ProgressTab.history);
  }

  /// KPI «Pendientes»: la sesión de hoy, con el foco del plan.
  void _startTodaySession(BuildContext context) {
    ref.read(audioPlayerServiceProvider).captureUserGesture();
    final plan = ref.read(todaySessionPlanProvider);
    ref.read(practiceFocusNoteProvider.notifier).state = null;
    setPracticeFocusNotes(ref, plan.focusNoteNames);
    context.push('${AppRoutes.game}/${GameMode.singleNote.id}');
  }

  /// «Escuchar» de la hoja de detalle: la nota en la octava 4.
  Future<void> _playNote(String note) async {
    final audio = ref.read(audioPlayerServiceProvider);
    audio.captureUserGesture();
    try {
      await audio.waitUntilReady();
      final prefs = await ref.read(audioPreferencesProvider.future);
      final (frequencies, _) = ref
          .read(audioGeneratorProvider)
          .getNoteFrequencies([note], varyOctaves: false);
      audio.setMasterVolume(prefs.masterVolume);
      await audio.playTones(
        frequencies,
        duration: prefs.toneDurationSec,
        instrument: prefs.playbackInstrument(),
      );
    } catch (_) {
      // Sin audio disponible: la hoja sigue funcionando.
    }
  }

  void _showNoteDetail(
    BuildContext context,
    NoteProgressSummary summary,
    NoteNamingMode naming,
    int learningThreshold,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => NoteDetailSheet(
        summary: summary,
        namingMode: naming,
        learningThreshold: learningThreshold,
        onListen: () => _playNote(summary.note),
        onPractice: () {
          Navigator.of(sheetContext).pop();
          startFocusedNotePractice(
            context: context,
            ref: ref,
            note: summary.note,
          );
        },
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
