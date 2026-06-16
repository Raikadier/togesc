import 'package:flutter/foundation.dart' show kIsWeb;

/// Credenciales de monetizacion inyectadas en build (--dart-define).
abstract final class SubscriptionConfig {
  static const monetizationEnabled = bool.fromEnvironment(
    'MONETIZATION_ENABLED',
    defaultValue: false,
  );

  static const revenueCatAppleKey = String.fromEnvironment(
    'REVENUECAT_APPLE_KEY',
  );
  static const revenueCatGoogleKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_KEY',
  );

  static const stripeCheckoutUrl = String.fromEnvironment(
    'STRIPE_CHECKOUT_URL',
  );
  static const stripePortalUrl = String.fromEnvironment(
    'STRIPE_PORTAL_URL',
  );

  static bool get isMobileStoreConfigured =>
      !kIsWeb &&
      (revenueCatAppleKey.isNotEmpty || revenueCatGoogleKey.isNotEmpty);

  static bool get isStripeConfigured =>
      kIsWeb && stripeCheckoutUrl.isNotEmpty;

  static bool get isActive =>
      monetizationEnabled &&
      (isMobileStoreConfigured || isStripeConfigured);
}
