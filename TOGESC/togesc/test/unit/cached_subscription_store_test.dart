import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:togesc/models/subscription_status.dart';
import 'package:togesc/services/cached_subscription_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CachedSubscriptionStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('persiste y recupera estado Pro', () async {
      const status = SubscriptionStatus(plan: 'pro', status: 'active');
      final store = CachedSubscriptionStore();

      await store.save(status);
      final loaded = await store.load();

      expect(loaded?.isPro, isTrue);
    });
  });
}
