import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/subscription_config.dart';
import '../models/subscription_status.dart';
import '../providers/auth_provider.dart';
import '../services/cached_subscription_store.dart';
import '../services/mobile_purchases_service.dart';
import '../services/subscription_access.dart';
import '../services/subscription_service.dart';

final cachedSubscriptionStoreProvider = Provider((ref) {
  return CachedSubscriptionStore();
});

final mobilePurchasesServiceProvider = Provider((ref) {
  return MobilePurchasesService();
});

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(
    client: ref.watch(supabaseClientProvider),
    userId: ref.watch(currentUserIdProvider),
    mobilePurchases: ref.watch(mobilePurchasesServiceProvider),
  );
});

/// Estado de suscripcion del usuario (Supabase + tiendas).
final subscriptionStatusProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionStatus>(
  SubscriptionNotifier.new,
);

class SubscriptionNotifier extends AsyncNotifier<SubscriptionStatus> {
  SubscriptionStatus? lastKnown;

  Future<void> _cacheStatus(SubscriptionStatus status) async {
    lastKnown = status;
    await ref.read(cachedSubscriptionStoreProvider).save(status);
  }

  @override
  Future<SubscriptionStatus> build() async {
    ref.listen(currentUserIdProvider, (prev, next) {
      if (prev != next) {
        ref.invalidateSelf();
      }
    });

    lastKnown = await ref.read(cachedSubscriptionStoreProvider).load();

    final service = ref.read(subscriptionServiceProvider);
    await service.initialize();
    final status = await service.loadStatus();
    await _cacheStatus(status);
    return status;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final status = await ref.read(subscriptionServiceProvider).loadStatus();
      await _cacheStatus(status);
      state = AsyncData(status);
    } catch (error, stackTrace) {
      if (lastKnown != null) {
        state = AsyncData(lastKnown!);
      } else {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  Future<bool> purchasePro() async {
    final result =
        await ref.read(subscriptionServiceProvider).purchasePro();
    await refresh();
    return result?.isPro ?? false;
  }

  Future<bool> restorePurchases() async {
    final result =
        await ref.read(subscriptionServiceProvider).restorePurchases();
    await refresh();
    return result?.isPro ?? false;
  }

  Future<void> startTrial() async {
    await ref.read(subscriptionServiceProvider).startTrial();
    await refresh();
  }

  Future<void> openStripeCheckout() async {
    final email = ref.read(currentUserEmailProvider);
    await ref.read(subscriptionServiceProvider).openStripeCheckout(email: email);
  }

  Future<void> openStripePortal() async {
    await ref.read(subscriptionServiceProvider).openStripePortal();
  }
}

/// Acceso Pro efectivo (respeta MONETIZATION_ENABLED).
final hasProAccessProvider = Provider<bool>((ref) {
  if (!SubscriptionConfig.isActive) return true;
  final status = ref.watch(subscriptionStatusProvider);
  return status.when(
    data: SubscriptionAccess.hasProAccess,
    loading: () => false,
    error: (_, _) => false,
  );
});
