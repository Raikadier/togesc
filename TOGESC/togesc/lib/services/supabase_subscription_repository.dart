import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/subscription_status.dart';

const String userSubscriptionsTable = 'user_subscriptions';

/// Lee y escribe el cache de suscripcion en Supabase (RLS).
class SupabaseSubscriptionRepository {
  SupabaseSubscriptionRepository({
    required SupabaseClient client,
    required String userId,
  })  : _client = client,
        _userId = userId;

  final SupabaseClient _client;
  final String _userId;

  Future<SubscriptionStatus> load() async {
    try {
      final row = await _client
          .from(userSubscriptionsTable)
          .select()
          .eq('user_id', _userId)
          .maybeSingle();
      if (row == null) return const SubscriptionStatus.free();
      return SubscriptionStatus.fromJson(row);
    } catch (_) {
      return const SubscriptionStatus.free();
    }
  }

  Future<void> upsert(SubscriptionStatus status, {String? externalId}) async {
    await _client.from(userSubscriptionsTable).upsert({
      'user_id': _userId,
      'plan': status.plan,
      'status': status.status,
      'source': status.source,
      if (externalId != null) 'external_id': externalId,
      if (status.trialEndsAt != null)
        'trial_ends_at': status.trialEndsAt!.toIso8601String(),
      if (status.expiresAt != null)
        'expires_at': status.expiresAt!.toIso8601String(),
    });
  }
}
