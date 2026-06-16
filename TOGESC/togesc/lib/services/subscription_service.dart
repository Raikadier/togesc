import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/subscription_config.dart';
import '../constants/subscription_constants.dart';
import '../models/subscription_status.dart';
import 'mobile_purchases_service.dart';
import 'supabase_subscription_repository.dart';

/// Orquesta suscripcion: Supabase cache + RevenueCat / Stripe.
class SubscriptionService {
  SubscriptionService({
    required SupabaseClient? client,
    required String? userId,
    MobilePurchasesService? mobilePurchases,
  })  : _client = client,
        _userId = userId,
        _mobile = mobilePurchases ?? MobilePurchasesService();

  final SupabaseClient? _client;
  final String? _userId;
  final MobilePurchasesService _mobile;

  SupabaseSubscriptionRepository? get _repo {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null) return null;
    return SupabaseSubscriptionRepository(client: client, userId: userId);
  }

  Future<void> initialize() async {
    final userId = _userId;
    if (userId != null) {
      await _mobile.configure(userId: userId);
    }
  }

  Future<SubscriptionStatus> loadStatus() async {
    if (!SubscriptionConfig.isActive) {
      return const SubscriptionStatus(
        plan: 'pro',
        status: 'active',
        source: 'manual',
      );
    }

    final repo = _repo;
    if (repo == null) return const SubscriptionStatus.free();

    var status = await repo.load();

    if (!kIsWeb && _mobile.isAvailable) {
      final mobileStatus = await _mobile.fetchStatus();
      if (mobileStatus != null) {
        await repo.upsert(mobileStatus);
        status = mobileStatus;
      }
    }

    return status;
  }

  Future<SubscriptionStatus?> purchasePro() async {
    if (!SubscriptionConfig.isActive) return null;

    if (kIsWeb) {
      await openStripeCheckout();
      return null;
    }

    final mobileStatus = await _mobile.purchasePro();
    if (mobileStatus != null) {
      await _repo?.upsert(mobileStatus);
    }
    return mobileStatus;
  }

  Future<SubscriptionStatus?> restorePurchases() async {
    if (!SubscriptionConfig.isActive) return null;

    if (kIsWeb) {
      await openStripePortal();
      return await loadStatus();
    }

    final mobileStatus = await _mobile.restorePurchases();
    if (mobileStatus != null) {
      await _repo?.upsert(mobileStatus);
    }
    return mobileStatus;
  }

  Future<void> openStripeCheckout({String? email}) async {
    final baseUrl = SubscriptionConfig.stripeCheckoutUrl;
    if (baseUrl.isEmpty || _userId == null) return;

    final params = {
      ...Uri.parse(baseUrl).queryParameters,
      'client_reference_id': _userId,
      if (email != null && email.isNotEmpty) 'prefilled_email': email,
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> openStripePortal() async {
    final url = SubscriptionConfig.stripePortalUrl;
    if (url.isEmpty || _userId == null) return;

    final uri = Uri.parse(url).replace(
      queryParameters: {
        ...Uri.parse(url).queryParameters,
        'client_reference_id': _userId,
      },
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> startTrial() async {
    final repo = _repo;
    if (!SubscriptionConfig.isActive || repo == null) return;

    final trialEnds = DateTime.now().add(
      const Duration(days: SubscriptionConstants.trialDays),
    );

    await repo.upsert(
      SubscriptionStatus(
        plan: 'pro',
        status: 'trialing',
        source: 'manual',
        trialEndsAt: trialEnds,
        expiresAt: trialEnds,
      ),
    );
  }
}
