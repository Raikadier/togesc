import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../app/togesc_colors.dart';
import '../models/subscription_status.dart';
import '../providers/session_history_provider.dart';
import '../providers/srs_provider.dart';
import '../providers/subscription_provider.dart';
import '../utils/session_history_stats.dart';
import '../services/progress_export_download.dart';
import '../services/progress_export_service.dart';
import '../services/subscription_access.dart';
import '../widgets/info_views.dart';
import '../widgets/note_accuracy_radar_chart.dart';
import '../widgets/session_evolution_chart.dart';
import '../widgets/session_history_card.dart';
import '../widgets/stats_bento_grid.dart';
import '../widgets/stats_free_dashboard.dart';
import '../widgets/togesc_ui.dart';

/// Pantalla de estadisticas del sistema SRS (dashboard Stitch).
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final status = ref.watch(subscriptionStatusProvider).valueOrNull;
    final advancedStats = SubscriptionAccess.canViewAdvancedStats(
      status ?? const SubscriptionStatus.free(),
    );
    final summaries = ref.watch(noteProgressSummariesProvider);

    if (stats.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Aún no hay estadísticas disponibles.')),
      );
    }

    final accuracy = stats['accuracy_percentage'] as double? ?? 0.0;
    final totalSeen = stats['total_seen'] as int? ?? 0;
    final learningPhase = stats['learning_phase'] as int? ?? 0;
    final graduated = stats['graduated'] as int? ?? 0;
    final totalNotes = stats['total_notes'] as int? ?? 12;
    final overdueCount = stats['overdue_count'] as int? ?? 0;
    final history = ref.watch(sessionHistoryProvider).valueOrNull ?? [];
    final weeklySummaries = buildDailyPracticeSummaries(history);
    final hasWeeklyActivity = weeklySummaries.any((day) => day.hasActivity);

    final sortedByAccuracy = List.of(summaries)
      ..sort((a, b) => a.accuracyPercent.compareTo(b.accuracyPercent));
    final hardest = sortedByAccuracy.take(3).toList();
    final easiest = sortedByAccuracy.reversed.take(3).toList();
    final scheme = Theme.of(context).colorScheme;
    final colors = TogescColors.of(context);

    return Scaffold(
      body: TogescPageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatsDashboardHeader(isPro: advancedStats),
            const SizedBox(height: DesignTokens.spacingLg),
            StatsBentoHeader(
              accuracy: accuracy,
              totalSeen: totalSeen,
              overdueCount: overdueCount,
              onReviewNow: () => startReviewPractice(context, ref),
            ),
            const SizedBox(height: DesignTokens.spacingLg),
            TogescCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estado del dominio',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: DesignTokens.spacingMd),
                  Row(
                    children: [
                      Expanded(
                        child: _DomainStatBox(
                          label: 'En aprendizaje',
                          value: '$learningPhase/$totalNotes',
                          color: scheme.secondary,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacingMd),
                      Expanded(
                        child: _DomainStatBox(
                          label: 'Dominadas',
                          value: '$graduated/$totalNotes',
                          color: colors.correct,
                        ),
                      ),
                    ],
                  ),
                  if (advancedStats) ...[
                    const SizedBox(height: DesignTokens.spacingLg),
                    NoteAccuracyRadarChart(summaries: summaries),
                    Text(
                      'Distribucion de precision por nota',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!advancedStats) ...[
              const SizedBox(height: DesignTokens.spacingLg),
              StatsFreeAdvancedLockSection(
                onUnlock: () => context.push(AppRoutes.paywall),
              ),
              const SizedBox(height: DesignTokens.spacingMd),
              StatsFreeProUpsellCard(
                onTap: () => context.push(AppRoutes.paywall),
              ),
            ],
            if (hasWeeklyActivity) ...[
              const SizedBox(height: DesignTokens.spacingMd),
              SessionEvolutionChart(summaries: weeklySummaries),
            ],
            const SizedBox(height: DesignTokens.spacingMd),
            const SessionHistoryCard(),
            const SizedBox(height: DesignTokens.spacingMd),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.statisticsNotes),
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('Ver progreso por nota (12)'),
            ),
            if (advancedStats && hardest.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.spacingMd),
              TogescCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dificultad alta',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    ...hardest.map(
                      (s) => StatsNoteRow(summary: s, highlightError: true),
                    ),
                  ],
                ),
              ),
            ],
            if (advancedStats && easiest.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.spacingMd),
              TogescCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mayor dominio',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    ...easiest.map((s) => StatsNoteRow(summary: s)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.spacingLg),
            if (advancedStats)
              OutlinedButton.icon(
                onPressed: () => _exportProgress(context, ref),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Exportar progreso (CSV)'),
              ),
            if (advancedStats) const SizedBox(height: DesignTokens.spacingMd),
            OutlinedButton.icon(
              onPressed: () => confirmAndResetProgress(context, ref),
              icon: Icon(Icons.restart_alt_rounded, color: DesignTokens.error),
              label: Text(
                'Reiniciar progreso',
                style: TextStyle(color: DesignTokens.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportProgress(BuildContext context, WidgetRef ref) {
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

class _DomainStatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DomainStatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: DesignTokens.borderRadiusMd,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.outline),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
