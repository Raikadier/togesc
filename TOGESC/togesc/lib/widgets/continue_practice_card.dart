import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../constants/game_constants.dart';
import '../constants/subscription_constants.dart';
import '../models/last_practice_session.dart';
import '../models/subscription_status.dart';
import '../services/subscription_access.dart';
import 'togesc_ui.dart';

/// CTA para retomar la ultima sesion de practica desde Home.
class ContinuePracticeCard extends StatelessWidget {
  final LastPracticeSession session;
  final SubscriptionStatus subscriptionStatus;
  final VoidCallback onContinue;

  const ContinuePracticeCard({
    super.key,
    required this.session,
    required this.subscriptionStatus,
    required this.onContinue,
  });

  bool get _locked => !canOpenLastPracticeSession(
        session: session,
        subscriptionStatus: subscriptionStatus,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return TogescCard(
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle_outline_rounded,
                color: scheme.primaryContainer,
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Continuar practica',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              if (_locked) const _ProBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            session.label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onContinue,
            child: Text(_locked ? 'Ver TOGESC Pro' : 'Continuar'),
          ),
        ],
      ),
    );
  }
}

bool canOpenLastPracticeSession({
  required LastPracticeSession session,
  required SubscriptionStatus subscriptionStatus,
}) {
  final mode = session.mode;
  if (mode == null || session.route.isEmpty) return false;

  if (session.kind == PracticeKind.speed) {
    return SubscriptionAccess.canPlayMode(
      subscriptionStatus,
      GameMode.speedTraining,
    );
  }
  return SubscriptionAccess.canPlayMode(subscriptionStatus, mode);
}

/// Navega a la ultima sesion o al paywall si el modo requiere Pro.
void openLastPracticeSession({
  required BuildContext context,
  required LastPracticeSession session,
  required SubscriptionStatus subscriptionStatus,
  required void Function(String route) onOpenRoute,
}) {
  final mode = session.mode;
  if (mode == null || session.route.isEmpty) return;

  if (!canOpenLastPracticeSession(
    session: session,
    subscriptionStatus: subscriptionStatus,
  )) {
    final feature = session.kind == PracticeKind.speed
        ? 'Entrenamiento de velocidad'
        : SubscriptionConstants.modeProLabel(mode);
    context.push(
      '${AppRoutes.paywall}?feature=${Uri.encodeComponent(feature)}',
    );
    return;
  }

  onOpenRoute(session.route);
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(DesignTokens.spacingSm),
        border: Border.all(
          color: scheme.secondary.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        'PRO',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
