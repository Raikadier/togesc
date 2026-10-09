import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../constants/game_constants.dart';
import '../../constants/subscription_constants.dart';
import '../../models/last_practice_session.dart';
import '../../models/subscription_status.dart';
import '../../providers/subscription_provider.dart';
import '../../services/subscription_access.dart';

/// Comprueba si el usuario puede jugar un modo (Free / Pro).
///
/// Es un provider para que los tests puedan simular la monetización activa
/// (en tests `SubscriptionConfig.isActive` es `false` y todo está abierto).
final homeModeAccessProvider = Provider<bool Function(GameMode)>((ref) {
  final status = ref.watch(subscriptionStatusProvider).valueOrNull ??
      const SubscriptionStatus.free();
  return (mode) => SubscriptionAccess.canPlayMode(status, mode);
});

/// Ruta del paywall con la función bloqueada como `feature` (D8).
String paywallRouteFor(GameMode mode) {
  final feature = SubscriptionConstants.modeProLabel(mode);
  return '${AppRoutes.paywall}?feature=${Uri.encodeComponent(feature)}';
}

/// Modo que hay que comprobar para abrir [session] (velocidad es Pro).
GameMode? accessModeForSession(LastPracticeSession session) {
  if (session.kind == PracticeKind.speed) return GameMode.speedTraining;
  return session.mode;
}

/// Si [session] se puede reabrir con el acceso actual.
bool canOpenLastPracticeSession({
  required LastPracticeSession session,
  required bool Function(GameMode) canPlay,
}) {
  final mode = accessModeForSession(session);
  if (mode == null || session.route.isEmpty) return false;
  return canPlay(mode);
}

/// Reabre la última sesión o lleva al paywall si el modo requiere Pro.
void openLastPracticeSession({
  required BuildContext context,
  required LastPracticeSession session,
  required bool Function(GameMode) canPlay,
}) {
  final mode = accessModeForSession(session);
  if (mode == null || session.route.isEmpty) return;
  if (!canPlay(mode)) {
    context.push(paywallRouteFor(mode));
    return;
  }
  context.push(session.route);
}
