import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/subscription_status.dart';
import '../../providers/subscription_provider.dart';
import '../../services/subscription_access.dart';

/// Acceso a lo Pro de Progreso (D7): historial completo, gráficas de
/// evolución y exportación. La rejilla de 12 notas es gratis y no depende
/// de este provider.
///
/// Es un provider aparte para poder simular un usuario gratis en los tests:
/// sin `MONETIZATION_ENABLED`, `SubscriptionAccess` trata a todos como Pro.
final progressProAccessProvider = Provider<bool>((ref) {
  final status = ref.watch(subscriptionStatusProvider).valueOrNull;
  return SubscriptionAccess.canViewAdvancedStats(
    status ?? const SubscriptionStatus.free(),
  );
});
