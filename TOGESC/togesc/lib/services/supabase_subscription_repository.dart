import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/subscription_status.dart';

const String userSubscriptionsTable = 'user_subscriptions';

/// Lee entitlements server-owned desde Supabase.
class SupabaseSubscriptionRepository {
  SupabaseSubscriptionRepository({
    required SupabaseClient client,
    required String userId,
  }) : _client = client,
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

  /// El servidor fija duracion y elegibilidad; nunca acepta un plan del cliente.
  Future<SubscriptionStatus> startTrial() async {
    final row = await _client.rpc('start_subscription_trial');
    if (row is! Map<String, dynamic>) {
      throw StateError('Respuesta de trial no valida');
    }
    return SubscriptionStatus.fromJson(row);
  }
}
