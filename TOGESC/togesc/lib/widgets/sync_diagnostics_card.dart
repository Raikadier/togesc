import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_tokens.dart';
import '../models/sync_diagnostics.dart';
import '../providers/sync_provider.dart';
import 'togesc_ui.dart';

class _SyncStatusVisual {
  const _SyncStatusVisual({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color background;
}

_SyncStatusVisual _visualFor(SyncDiagnostics d) {
  if (!d.cloudSyncEnabled) {
    return const _SyncStatusVisual(
      label: 'Sync Pro',
      icon: Icons.lock_outline_rounded,
      color: DesignTokens.onSurfaceVariant,
      background: DesignTokens.surfaceContainer,
    );
  }
  if (!d.hasSession) {
    return const _SyncStatusVisual(
      label: 'Sin sesion',
      icon: Icons.person_off_outlined,
      color: DesignTokens.onSurfaceVariant,
      background: DesignTokens.surfaceContainer,
    );
  }
  if (!d.remoteReachable) {
    return const _SyncStatusVisual(
      label: 'Sin conexion',
      icon: Icons.cloud_off_rounded,
      color: DesignTokens.error,
      background: DesignTokens.errorContainer,
    );
  }
  if (d.pendingUpload) {
    return const _SyncStatusVisual(
      label: 'Pendiente',
      icon: Icons.cloud_upload_rounded,
      color: DesignTokens.selection,
      background: DesignTokens.surfaceContainerLow,
    );
  }
  if (d.isInSync) {
    return const _SyncStatusVisual(
      label: 'Sincronizado',
      icon: Icons.cloud_done_rounded,
      color: DesignTokens.correct,
      background: DesignTokens.surfaceContainerLow,
    );
  }
  return const _SyncStatusVisual(
    label: 'Desalineado',
    icon: Icons.cloud_sync_rounded,
    color: DesignTokens.incorrect,
    background: DesignTokens.errorContainer,
  );
}

/// Panel de estado de sincronizacion (Fase 4 DoD).
class SyncDiagnosticsCard extends ConsumerWidget {
  const SyncDiagnosticsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnosticsAsync = ref.watch(syncDiagnosticsProvider);
    final theme = Theme.of(context);

    return diagnosticsAsync.when(
      loading: () => const TogescCard(
        child: SizedBox(
          height: 88,
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (SyncDiagnostics d) {
        final visual = _visualFor(d);

        return TogescCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: visual.background,
                      borderRadius: DesignTokens.borderRadiusMd,
                    ),
                    child: Icon(visual.icon, color: visual.color, size: 22),
                  ),
                  const SizedBox(width: DesignTokens.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estado de sync',
                          style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: DesignTokens.spacingXs),
                        Text(
                          d.statusLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: DesignTokens.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(
                    label: visual.label,
                    color: visual.color,
                    backgroundColor: visual.background,
                  ),
                ],
              ),
              if (d.localSession != null || d.remoteSession != null) ...[
                const SizedBox(height: DesignTokens.spacingMd),
                const Divider(height: 1, color: DesignTokens.outlineVariant),
                const SizedBox(height: DesignTokens.spacingMd),
                if (d.localSession != null)
                  _SessionRow(
                    label: 'Local',
                    value: d.localSession!,
                    icon: Icons.smartphone_rounded,
                  ),
                if (d.remoteSession != null)
                  _SessionRow(
                    label: 'Nube',
                    value: d.remoteSession!,
                    icon: Icons.cloud_outlined,
                  ),
              ],
              if (d.pendingUpload) ...[
                const SizedBox(height: DesignTokens.spacingMd),
                Row(
                  children: [
                    Icon(
                      Icons.sync_rounded,
                      size: 18,
                      color: DesignTokens.selection,
                    ),
                    const SizedBox(width: DesignTokens.spacingSm),
                    Expanded(
                      child: Text(
                        'Hay cambios locales esperando subida.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: DesignTokens.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingMd,
        vertical: DesignTokens.spacingXs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SessionRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: DesignTokens.primaryContainer),
          const SizedBox(width: DesignTokens.spacingSm),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DesignTokens.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.labelLarge?.copyWith(
                fontFamily: 'monospace',
                color: DesignTokens.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
