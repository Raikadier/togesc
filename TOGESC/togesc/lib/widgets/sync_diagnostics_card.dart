import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sync_diagnostics.dart';
import '../providers/sync_provider.dart';

/// Panel de estado de sincronizacion (Fase 4 DoD).
class SyncDiagnosticsCard extends ConsumerWidget {
  const SyncDiagnosticsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnosticsAsync = ref.watch(syncDiagnosticsProvider);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return diagnosticsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const SizedBox.shrink(),
      data: (SyncDiagnostics d) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      d.isInSync ? Icons.cloud_done : Icons.cloud_sync,
                      color: d.isInSync ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Estado de sync',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(d.statusLabel, style: TextStyle(color: muted)),
                if (d.localSession != null) ...[
                  const SizedBox(height: 4),
                  Text('Local: ${d.localSession}', style: TextStyle(fontSize: 12, color: muted)),
                ],
                if (d.remoteSession != null) ...[
                  Text('Nube: ${d.remoteSession}', style: TextStyle(fontSize: 12, color: muted)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
