import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_tokens.dart';
import '../models/practice_session_log.dart';
import '../providers/engagement_stats_provider.dart';
import '../providers/session_history_provider.dart';
import '../providers/srs_provider.dart';
import 'account_sync_views.dart' show accountSyncStatusInk;
import 'home_v2/ear_map_card.dart' show consolidatedNoteCount;
import 'paywall_views.dart';
import 'togesc_ui.dart';

/// Cabecera del Perfil v2.1 (SPEC §2.5): avatar de 64 px y el estado de la
/// cuenta. Sin cuenta, explica dónde vive el progreso y ofrece entrar.
class ProfileIdentityHeader extends StatelessWidget {
  const ProfileIdentityHeader({
    super.key,
    this.email,
    this.verified = true,
    this.onSignIn,
  });

  /// Email de la sesión; null si se entrena sin cuenta.
  final String? email;
  final bool verified;

  /// Abre la hoja de acceso; null si no hay backend de cuentas.
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final signedIn = email != null;

    return Column(
      key: const ValueKey('profile-header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: signedIn
                      ? scheme.primary
                      : scheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  signedIn
                      ? Icons.person_rounded
                      : Icons.person_outline_rounded,
                  size: 34,
                  color: signedIn ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      signedIn ? email! : 'Entrenando sin cuenta',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    signedIn
                        ? (verified
                              ? 'Cuenta verificada'
                              : 'Pendiente de verificar el email')
                        : 'Tu progreso vive en este dispositivo',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!signedIn && onSignIn != null) ...[
          const SizedBox(height: DesignTokens.spacingMd),
          FilledButton.icon(
            key: const ValueKey('profile-sign-in'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, DesignTokens.touchTargetMin),
            ),
            onPressed: onSignIn,
            icon: const Icon(Icons.login_rounded),
            label: const Text('Entrar o crear cuenta'),
          ),
        ],
      ],
    );
  }
}

/// «Tu oído en cifras»: racha, notas consolidadas y sesiones. Solo datos
/// reales del dispositivo (D10).
class ProfileEarStats extends ConsumerWidget {
  const ProfileEarStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final streak = ref.watch(engagementStatsProvider).currentStreakDays;
    final consolidated = consolidatedNoteCount(
      ref.watch(noteProgressSummariesProvider),
    );
    final sessions = ref.watch(sessionHistoryProvider).valueOrNull?.length ?? 0;

    final tiles = [
      _StatTile(
        key: const ValueKey('profile-stat-streak'),
        value: '$streak',
        label: streak == 1 ? 'Día de racha' : 'Días de racha',
      ),
      _StatTile(
        key: const ValueKey('profile-stat-consolidated'),
        value: '$consolidated/${chromaticNotes.length}',
        label: 'Notas consolidadas',
        semanticValue: '$consolidated de ${chromaticNotes.length}',
      ),
      _StatTile(
        key: const ValueKey('profile-stat-sessions'),
        value: '$sessions',
        label: sessions == 1 ? 'Sesión' : 'Sesiones',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Tu oído en cifras',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: DesignTokens.spacingSm),
              Expanded(child: tiles[i]),
            ],
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    super.key,
    required this.value,
    required this.label,
    this.semanticValue,
  });

  final String value;
  final String label;
  final String? semanticValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      container: true,
      label: '$label: ${semanticValue ?? value}',
      excludeSemantics: true,
      child: TogescCard(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card `hero` del plan: «Plan actual», los 3 beneficios de Pro y el botón
/// blanco hacia el paywall o la gestión de la suscripción (D8).
class ProfilePlanCard extends StatelessWidget {
  const ProfilePlanCard({
    super.key,
    required this.hasPro,
    required this.onOpen,
  });

  final bool hasPro;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('profile-plan'),
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      decoration: BoxDecoration(
        color: DesignTokens.hero,
        borderRadius: DesignTokens.borderRadiusHero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan actual'.toUpperCase(),
            style: DesignTokens.overline.copyWith(
              color: DesignTokens.onHeroAccent,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXs),
          Text(
            hasPro ? 'TOGESC Pro' : 'Gratis',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: DesignTokens.onHero,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          for (final b in paywallBenefits)
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.spacingSm),
              child: Row(
                children: [
                  Icon(
                    hasPro ? Icons.check_circle_rounded : b.icon,
                    size: 20,
                    color: DesignTokens.onHeroAccent,
                  ),
                  const SizedBox(width: DesignTokens.spacingSm),
                  Expanded(
                    child: Text(
                      b.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DesignTokens.onHeroMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: DesignTokens.spacingSm),
          FilledButton(
            key: const ValueKey('account-pro-entry'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(DesignTokens.touchTargetMin),
              backgroundColor: DesignTokens.onHero,
              foregroundColor: DesignTokens.hero,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
              shape: RoundedRectangleBorder(
                borderRadius: DesignTokens.borderRadiusCta,
              ),
            ),
            onPressed: onOpen,
            child: Text(hasPro ? 'Gestionar TOGESC Pro' : 'Ver TOGESC Pro'),
          ),
        ],
      ),
    );
  }
}

/// Estado de sincronización con icono y texto (nunca solo color).
enum ProfileSyncState { deviceOnly, signedOut, pending, synced }

class ProfileSyncStatus extends StatelessWidget {
  const ProfileSyncStatus({super.key, required this.state});

  final ProfileSyncState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (icon, title, detail, color) = switch (state) {
      ProfileSyncState.deviceOnly => (
        Icons.phone_android_rounded,
        'Solo en este dispositivo',
        'Este build no tiene cuentas en la nube.',
        scheme.onSurfaceVariant,
      ),
      ProfileSyncState.signedOut => (
        Icons.cloud_off_rounded,
        'Sin sincronizar',
        'Entra en tu cuenta para guardar el progreso en la nube.',
        scheme.onSurfaceVariant,
      ),
      ProfileSyncState.pending => (
        Icons.cloud_upload_rounded,
        'Cambios pendientes',
        'Hay progreso local que aún no se ha subido.',
        accountSyncStatusInk(context, synced: false),
      ),
      ProfileSyncState.synced => (
        Icons.cloud_done_rounded,
        'Sincronizado',
        'Tu progreso está guardado en la nube.',
        accountSyncStatusInk(context, synced: true),
      ),
    };

    return Semantics(
      key: const ValueKey('profile-sync-status'),
      container: true,
      liveRegion: true,
      child: TogescCard(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        child: Row(
          children: [
            ExcludeSemantics(child: Icon(icon, color: color)),
            const SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
