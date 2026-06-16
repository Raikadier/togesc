import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/supabase_config.dart';
import '../models/subscription_status.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/hybrid_progress_repository.dart';
import '../services/progress_repository.dart';
import '../services/subscription_access.dart';
import '../services/supabase_progress_repository.dart';
import '../services/srs_system.dart';

/// Provider para el repositorio de progreso (local + sync opcional Supabase).
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final local = SharedPreferencesProgressRepository();

  if (!SupabaseConfig.isConfigured) return local;

  return HybridProgressRepository(
    local: local,
    remoteFactory: () async {
      final client = ref.read(supabaseClientProvider);
      final userId = ref.read(currentUserIdProvider);
      if (client == null || userId == null) return null;

      final status = ref.read(subscriptionStatusProvider).valueOrNull ??
          const SubscriptionStatus.free();
      if (!SubscriptionAccess.canUseCloudSync(status)) return null;

      return SupabaseProgressRepository(client: client, userId: userId);
    },
  );
});

/// Fusion local/remoto tras iniciar sesion.
final progressSyncOnSignInProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final repo = ref.read(progressRepositoryProvider);
    if (repo is HybridProgressRepository) {
      await repo.mergeOnSignIn();
      await repo.flushPendingSync();
      ref.invalidate(srsSystemProvider);
      ref.invalidate(syncPendingProvider);
    }
  };
});

/// Flush de sync pendiente (reconexion / resume app).
final progressFlushPendingProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    final repo = ref.read(progressRepositoryProvider);
    if (repo is! HybridProgressRepository) return true;
    final ok = await repo.flushPendingSync();
    if (ok) ref.invalidate(srsSystemProvider);
    return ok;
  };
});

final syncPendingProvider = FutureProvider<bool>((ref) async {
  final repo = ref.read(progressRepositoryProvider);
  if (repo is HybridProgressRepository) {
    return repo.hasPendingSync;
  }
  return false;
});

/// Provider para el sistema SRS.
final srsSystemProvider =
    AsyncNotifierProvider<SRSNotifier, SRSSystem>(SRSNotifier.new);

class SRSNotifier extends AsyncNotifier<SRSSystem> {
  @override
  Future<SRSSystem> build() async {
    final repo = ref.read(progressRepositoryProvider);
    final srs = SRSSystem(repository: repo);
    await srs.loadProgress();
    return srs;
  }

  Future<void> saveProgress() async {
    final srs = state.valueOrNull;
    if (srs != null) await srs.saveProgress();
    final repo = ref.read(progressRepositoryProvider);
    if (repo is HybridProgressRepository) {
      await repo.flushPendingSync();
      ref.invalidate(syncPendingProvider);
    }
  }

  Future<void> resetProgress() async {
    final srs = state.valueOrNull;
    if (srs != null) {
      await srs.resetProgress();
      ref.invalidateSelf();
    }
  }
}

/// Provider para estadisticas (derivado del SRS).
final srsStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final srsAsync = ref.watch(srsSystemProvider);
  return srsAsync.when(
    data: (srs) => srs.getStatistics(),
    loading: () => {},
    error: (_, _) => {},
  );
});

/// Provider para recomendaciones de practica.
final practiceRecommendationsProvider = Provider<Map<String, dynamic>>((ref) {
  final srsAsync = ref.watch(srsSystemProvider);
  return srsAsync.when(
    data: (srs) => srs.getPracticeRecommendations(),
    loading: () => {},
    error: (_, _) => {},
  );
});
