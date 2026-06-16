import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/supabase_config.dart';
import '../models/subscription_status.dart';
import '../models/sync_diagnostics.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/hybrid_progress_repository.dart';
import '../services/subscription_access.dart';
import '../services/supabase_progress_repository.dart';
import '../services/sync_coordinator.dart';
import 'srs_provider.dart';

final syncCoordinatorProvider = Provider<SyncCoordinator?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;

  final repo = ref.watch(progressRepositoryProvider);
  if (repo is! HybridProgressRepository) return null;

  final status = ref.watch(subscriptionStatusProvider).valueOrNull ??
      const SubscriptionStatus.free();

  return SyncCoordinator(
    hybrid: repo,
    local: repo.local,
    remoteFactory: () async {
      final client = ref.read(supabaseClientProvider);
      final userId = ref.read(currentUserIdProvider);
      if (client == null || userId == null) return null;
      if (!SubscriptionAccess.canUseCloudSync(status)) return null;
      return SupabaseProgressRepository(client: client, userId: userId);
    },
    cloudSyncEnabled: SubscriptionAccess.canUseCloudSync(status),
    hasSession: ref.watch(currentUserIdProvider) != null,
  );
});

final syncDiagnosticsProvider = FutureProvider<SyncDiagnostics>((ref) async {
  ref.watch(currentUserIdProvider);
  ref.watch(hasProAccessProvider);
  ref.watch(syncPendingProvider);

  final coordinator = ref.watch(syncCoordinatorProvider);
  if (coordinator == null) {
    return const SyncDiagnostics(
      cloudSyncEnabled: false,
      hasSession: false,
    );
  }
  return coordinator.diagnose();
});

final syncNowProvider = Provider<Future<SyncDiagnostics> Function()>((ref) {
  return () async {
    final coordinator = ref.read(syncCoordinatorProvider);
    if (coordinator == null) {
      return const SyncDiagnostics(cloudSyncEnabled: false, hasSession: false);
    }
    final result = await coordinator.syncNow();
    ref.invalidate(syncDiagnosticsProvider);
    ref.invalidate(syncPendingProvider);
    return result;
  };
});

final afterProgressSaveProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final coordinator = ref.read(syncCoordinatorProvider);
    if (coordinator == null) return;
    await coordinator.afterLocalSave();
    ref.invalidate(syncPendingProvider);
  };
});
