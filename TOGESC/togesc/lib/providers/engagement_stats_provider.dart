import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/engagement_stats.dart';
import '../services/engagement_stats_service.dart';
import 'app_preferences_provider.dart';
import 'session_history_provider.dart';

final engagementStatsProvider = Provider<EngagementStats>((ref) {
  final history = ref.watch(sessionHistoryProvider).valueOrNull ?? [];
  final prefs = ref.watch(appPreferencesProvider).valueOrNull;
  final totalXp = prefs?.totalXp ?? 0;

  return EngagementStatsService.build(
    history: history,
    totalXp: totalXp,
  );
});
