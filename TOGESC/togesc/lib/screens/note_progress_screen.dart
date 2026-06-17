import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../models/subscription_status.dart';
import '../providers/srs_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/subscription_access.dart';
import '../widgets/account_monetization_views.dart';
import '../widgets/note_srs_detail_card.dart';
import '../widgets/togesc_ui.dart';

/// Detalle SRS de las 12 notas musicales.
class NoteProgressScreen extends ConsumerWidget {
  const NoteProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(noteProgressSummariesProvider);
    final status = ref.watch(subscriptionStatusProvider).valueOrNull;
    final advanced = SubscriptionAccess.canViewAdvancedStats(
      status ?? const SubscriptionStatus.free(),
    );

    if (summaries.isEmpty) {
      return const TogescScaffold(
        title: 'Progreso por nota',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return TogescScaffold(
      title: 'Progreso por nota',
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.marginMobile),
        children: [
          Text(
            'Estado de cada clase de altura en el sistema SRS.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          if (!advanced)
            ProLockedFeatureCard(
              onTap: () => context.push(AppRoutes.paywall),
            ),
          if (!advanced) const SizedBox(height: DesignTokens.spacingMd),
          for (final summary in summaries) ...[
            NoteSrsDetailCard(
              summary: summary,
              showAdvanced: advanced,
              onPractice: advanced
                  ? () => startFocusedNotePractice(
                        context: context,
                        ref: ref,
                        note: summary.note,
                      )
                  : () => context.push(AppRoutes.paywall),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
          ],
        ],
      ),
    );
  }
}
