import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/observability_config.dart';
import '../config/supabase_config.dart';

const String analyticsEventsTable = 'analytics_events';

/// Eventos de producto hacia Supabase (Fase 6).
class AnalyticsService {
  AnalyticsService({SupabaseClient? client, String? userId})
      : _client = client,
        _userId = userId;

  final SupabaseClient? _client;
  final String? _userId;

  factory AnalyticsService.fromRef({
    required SupabaseClient? client,
    required String? userId,
  }) {
    return AnalyticsService(client: client, userId: userId);
  }

  bool get isAvailable =>
      ObservabilityConfig.analyticsEnabled &&
      SupabaseConfig.isConfigured &&
      _client != null;

  Future<void> track(String eventName, [Map<String, Object?> properties = const {}]) async {
    if (!isAvailable) return;

    try {
      await _client!.from(analyticsEventsTable).insert({
        'user_id': _userId,
        'event_name': eventName,
        'properties': properties,
      });
    } catch (_) {
      // Analytics no debe bloquear la app.
    }
  }

  Future<void> appOpen() => track('app_open');

  Future<void> modeStarted(String modeId, String modeName) => track(
        'mode_started',
        {'mode_id': modeId, 'mode_name': modeName},
      );

  Future<void> roundCompleted({
    required String modeId,
    required bool correct,
  }) =>
      track('round_completed', {
        'mode_id': modeId,
        'correct': correct,
      });

  Future<void> paywallViewed({String? feature}) => track(
        'paywall_viewed',
        feature != null ? {'feature': feature} : const {},
      );

  Future<void> subscriptionTrialStarted() => track('subscription_trial_started');

  Future<void> syncCompleted({required bool inSync}) => track(
        'sync_completed',
        {'in_sync': inSync},
      );

  Future<void> csatSubmitted({
    required int rating,
    String? comment,
  }) =>
      track('csat_submitted', {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });
}
