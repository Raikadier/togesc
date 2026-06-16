import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/subscription_config.dart';
import '../constants/subscription_constants.dart';
import '../models/subscription_status.dart';

/// Integracion RevenueCat (iOS / Android).
class MobilePurchasesService {
  bool _configured = false;

  bool get isAvailable =>
      !kIsWeb && SubscriptionConfig.isMobileStoreConfigured;

  Future<void> configure({required String userId}) async {
    if (!isAvailable || _configured) return;

    final apiKey = defaultTargetPlatform == TargetPlatform.iOS
        ? SubscriptionConfig.revenueCatAppleKey
        : SubscriptionConfig.revenueCatGoogleKey;

    if (apiKey.isEmpty) return;

    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
    await Purchases.configure(
      PurchasesConfiguration(apiKey)..appUserID = userId,
    );
    _configured = true;
  }

  Future<SubscriptionStatus?> fetchStatus() async {
    if (!isAvailable || !_configured) return null;

    try {
      final info = await Purchases.getCustomerInfo();
      return _statusFromCustomerInfo(info);
    } catch (_) {
      return null;
    }
  }

  Future<SubscriptionStatus?> purchasePro() async {
    if (!isAvailable || !_configured) return null;

    try {
      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages;
      if (packages == null || packages.isEmpty) return null;
      final package = packages.first;

      final info = await Purchases.purchasePackage(package);
      return _statusFromCustomerInfo(info);
    } catch (_) {
      return null;
    }
  }

  Future<SubscriptionStatus?> restorePurchases() async {
    if (!isAvailable || !_configured) return null;

    try {
      final info = await Purchases.restorePurchases();
      return _statusFromCustomerInfo(info);
    } catch (_) {
      return null;
    }
  }

  SubscriptionStatus? _statusFromCustomerInfo(CustomerInfo info) {
    final entitlement =
        info.entitlements.all[SubscriptionConstants.proEntitlementId];
    if (entitlement?.isActive != true) {
      return const SubscriptionStatus.free();
    }

    final expiration = entitlement!.expirationDate;
    DateTime? expiresAt;
    if (expiration != null) {
      expiresAt = DateTime.tryParse(expiration);
    }

    final isTrial = entitlement.periodType == PeriodType.trial;

    return SubscriptionStatus(
      plan: 'pro',
      status: isTrial ? 'trialing' : 'active',
      source: 'revenuecat',
      trialEndsAt: isTrial ? expiresAt : null,
      expiresAt: expiresAt,
    );
  }
}
