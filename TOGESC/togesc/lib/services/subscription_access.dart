import '../constants/game_constants.dart';
import '../constants/subscription_constants.dart';
import '../config/subscription_config.dart';
import '../models/subscription_status.dart';

/// Reglas de acceso Free vs Pro.
abstract final class SubscriptionAccess {
  static bool hasProAccess(SubscriptionStatus status) {
    if (!SubscriptionConfig.isActive) return true;
    return status.isPro;
  }

  static bool canPlayMode(SubscriptionStatus status, GameMode mode) {
    if (!SubscriptionConfig.isActive) return true;
    if (SubscriptionConstants.isModeFree(mode)) return true;
    return hasProAccess(status);
  }

  static bool canUseCloudSync(SubscriptionStatus status) {
    if (!SubscriptionConfig.isActive) return true;
    return hasProAccess(status);
  }

  static bool canViewAdvancedStats(SubscriptionStatus status) {
    if (!SubscriptionConfig.isActive) return true;
    return hasProAccess(status);
  }
}
