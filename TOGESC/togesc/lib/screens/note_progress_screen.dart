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
    final srsState = ref.watch(srsSystemProvider);
    if (srsState.isLoading && !srsState.hasValue) {
      return const TogescScaffold(
        title: 'Progreso por nota',
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (srsState.hasError && !srsState.hasValue) {
      return TogescScaffold(
        title: 'Progreso por nota',
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No se pudo cargar el progreso por nota.'),
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

    final summaries = ref.watch(noteProgressSummariesProvider);
    final status = ref.watch(subscriptionStatusProvider).valueOrNull;
    final advanced = SubscriptionAccess.canViewAdvancedStats(
      status ?? const SubscriptionStatus.free(),
    );

    if (summaries.isEmpty) {
      return const TogescScaffold(
        title: 'Progreso por nota',
        body: Center(child: Text('Aún no hay progreso por nota.')),
      );
    }

    final wide =
        MediaQuery.sizeOf(context).width >= DesignTokens.shellBreakpoint;
    final margin = wide
        ? DesignTokens.marginDesktop
        : DesignTokens.marginMobile;

    return TogescScaffold(
      title: 'Progreso por nota',
      body: ListView(
        padding: EdgeInsets.all(margin),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: DesignTokens.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Estado de cada clase de altura en el sistema SRS.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            ),
          ),
        ],
      ),
    );
  }
}
