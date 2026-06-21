import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../models/subscription_status.dart';
import '../providers/session_history_provider.dart';
import '../providers/srs_provider.dart';
import '../providers/subscription_provider.dart';
import '../utils/session_history_stats.dart';
import '../services/progress_export_download.dart';
import '../services/progress_export_service.dart';
import '../services/subscription_access.dart';
import '../widgets/account_monetization_views.dart';
import '../widgets/info_views.dart';
import '../widgets/session_evolution_chart.dart';
import '../widgets/session_history_card.dart';
import '../widgets/togesc_ui.dart';

/// Pantalla de estadisticas del sistema SRS.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  Color _accuracyColor(double accuracy) {
    if (accuracy >= 80) return DesignTokens.correct;
    if (accuracy >= 50) return DesignTokens.selection;
    return DesignTokens.incorrect;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(srsStatisticsProvider);
    final status = ref.watch(subscriptionStatusProvider).valueOrNull;
    final advancedStats = SubscriptionAccess.canViewAdvancedStats(
      status ?? const SubscriptionStatus.free(),
    );

    if (stats.isEmpty) {
      return const TogescScaffold(
        title: 'Estadisticas',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final accuracy = stats['accuracy_percentage'] as double? ?? 0.0;
    final totalSeen = stats['total_seen'] as int? ?? 0;
    final learningPhase = stats['learning_phase'] as int? ?? 0;
    final graduated = stats['graduated'] as int? ?? 0;
    final totalNotes = stats['total_notes'] as int? ?? 12;
    final overdueCount = stats['overdue_count'] as int? ?? 0;
    final hardestNotes = stats['hardest_notes'] as List<dynamic>? ?? [];
    final easiestNotes = stats['easiest_notes'] as List<dynamic>? ?? [];
    final history = ref.watch(sessionHistoryProvider).valueOrNull ?? [];
    final weeklySummaries = buildDailyPracticeSummaries(history);
    final hasWeeklyActivity = weeklySummaries.any((day) => day.hasActivity);
    final accuracyColor = _accuracyColor(accuracy);

    return TogescScaffold(
      title: 'Estadisticas',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.marginMobile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TogescCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen General',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: DesignTokens.spacingLg),
                  StatsMetricRow(
                    icon: Icons.percent_rounded,
                    label: 'Precision global',
                    value: '$accuracy%',
                    color: accuracyColor,
                  ),
                  StatsMetricRow(
                    icon: Icons.visibility_rounded,
                    label: 'Total de intentos',
                    value: '$totalSeen',
                    color: DesignTokens.primaryContainer,
                  ),
                  StatsMetricRow(
                    icon: Icons.school_rounded,
                    label: 'En aprendizaje',
                    value: '$learningPhase / $totalNotes',
                    color: DesignTokens.selection,
                  ),
                  StatsMetricRow(
                    icon: Icons.check_circle_rounded,
                    label: 'Consolidadas',
                    value: '$graduated / $totalNotes',
                    color: DesignTokens.correct,
                  ),
                  if (overdueCount > 0)
                    StatsMetricRow(
                      icon: Icons.warning_amber_rounded,
                      label: 'Pendientes de revision',
                      value: '$overdueCount',
                      color: DesignTokens.incorrect,
                    ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            TogescCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progreso', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: DesignTokens.spacingMd),
                  ClipRRect(
                    borderRadius: DesignTokens.borderRadiusMd,
                    child: LinearProgressIndicator(
                      value: totalNotes > 0 ? graduated / totalNotes : 0,
                      backgroundColor: DesignTokens.surfaceContainer,
                      color: DesignTokens.primaryContainer,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingSm),
                  Text(
                    '$graduated de $totalNotes notas consolidadas',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DesignTokens.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            if (hasWeeklyActivity) ...[
              SessionEvolutionChart(summaries: weeklySummaries),
              const SizedBox(height: DesignTokens.spacingMd),
            ],
            const SessionHistoryCard(),
            const SizedBox(height: DesignTokens.spacingMd),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.statisticsNotes),
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('Ver progreso por nota (12)'),
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            if (!advancedStats)
              ProLockedFeatureCard(
                onTap: () => context.push(AppRoutes.paywall),
              ),
            if (advancedStats && hardestNotes.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.spacingMd),
              StatsNotesSection(
                title: 'Notas Mas Dificiles',
                notes: hardestNotes.cast<String>(),
                color: DesignTokens.incorrect,
                icon: Icons.trending_up_rounded,
              ),
            ],
            if (advancedStats && easiestNotes.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.spacingMd),
              StatsNotesSection(
                title: 'Notas Mas Faciles',
                notes: easiestNotes.cast<String>(),
                color: DesignTokens.correct,
                icon: Icons.trending_down_rounded,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descarga CSV iniciada')),
      );
    } else {
      Clipboard.setData(ClipboardData(text: csv));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progreso copiado al portapapeles')),
      );
    }
  }
}
