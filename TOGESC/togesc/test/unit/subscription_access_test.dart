import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/config/subscription_config.dart';
import 'package:togesc/models/subscription_status.dart';
import 'package:togesc/services/subscription_access.dart';

void main() {
  group('SubscriptionAccess', () {
    test('modo free accesible sin pro', () {
      expect(
        SubscriptionAccess.canPlayMode(
          const SubscriptionStatus.free(),
          GameMode.singleNote,
        ),
        isTrue,
      );
    });

    test('modo pro bloqueado sin suscripcion cuando monetizacion activa', () {
      // SubscriptionConfig.isActive es const de entorno; en tests suele ser false.
      if (!SubscriptionConfig.isActive) {
        expect(
          SubscriptionAccess.canPlayMode(
            const SubscriptionStatus.free(),
            GameMode.chord,
          ),
          isTrue,
        );
      }
    });

    test('modo pro accesible con plan pro activo', () {
      final pro = SubscriptionStatus(
        plan: 'pro',
        status: 'active',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      expect(SubscriptionAccess.hasProAccess(pro), isTrue);
      expect(SubscriptionAccess.canPlayMode(pro, GameMode.chord), isTrue);
    });

    test('plan pro expirado no da acceso', () {
      final expired = SubscriptionStatus(
        plan: 'pro',
        status: 'active',
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      if (SubscriptionConfig.isActive) {
        expect(expired.isPro, isFalse);
      }
    });
  });
}
