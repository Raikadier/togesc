import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/supabase_config.dart';
import '../providers/auth_provider.dart';
import '../services/hybrid_progress_repository.dart';
import '../services/progress_repository.dart';
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
      ref.invalidate(srsSystemProvider);
    }
  };
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
