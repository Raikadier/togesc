import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../services/analytics_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService.fromRef(
    client: ref.watch(supabaseClientProvider),
    userId: ref.watch(currentUserIdProvider),
  );
});

final trackAppOpenProvider = Provider<Future<void> Function()>((ref) {
  return () => ref.read(analyticsServiceProvider).appOpen();
});
