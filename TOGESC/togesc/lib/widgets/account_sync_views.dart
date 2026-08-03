import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_tokens.dart';
import '../app/togesc_colors.dart';
import '../constants/note_naming.dart';
import '../models/sync_diagnostics.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/sync_provider.dart';
import '../services/practice_reminder_service.dart';
import 'togesc_ui.dart';

/// Cabecera de perfil en cuenta (Stitch sync settings).
class AccountProfileHeader extends StatelessWidget {
  final String email;
  final String? userId;
  final bool isSynced;

  const AccountProfileHeader({
    super.key,
    required this.email,
    required this.isSynced,
    this.userId,
  });

  String get _shortId {
    if (userId == null || userId!.length < 4) return '';
    final len = userId!.length > 8 ? 8 : userId!.length;
    return '#${userId!.substring(0, len)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = TogescColors.of(context);

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: DesignTokens.borderRadiusMd,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.surfaceContainerLowest,
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 40,
              color: DesignTokens.onPrimary,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: DesignTokens.spacingSm),
                Wrap(
                  spacing: DesignTokens.spacingSm,
                  runSpacing: DesignTokens.spacingXs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingMd,
                        vertical: DesignTokens.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: (isSynced
                                ? colors.correct
                                : colors.selection)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: (isSynced
                                  ? colors.correct
                                  : colors.selection)
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSynced
                                ? Icons.cloud_done_rounded
                                : Icons.cloud_sync_rounded,
                            size: 16,
                            color: isSynced
                                ? colors.correct
                                : colors.selection,
                          ),
                          const SizedBox(width: DesignTokens.spacingXs),
                          Text(
                            isSynced ? 'Sincronizado' : 'Pendiente',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isSynced
                                  ? colors.correct
                                  : colors.selection,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_shortId.isNotEmpty)
                      Text(
                        'ID: $_shortId',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner upsell sync Pro (Stitch).
class AccountSyncProBanner extends StatelessWidget {
  final VoidCallback onTap;

  const AccountSyncProBanner({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: DesignTokens.borderRadiusXl,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.stars_rounded,
              color: scheme.secondary,
              size: 22,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingMd),
          Expanded(
            child: Text(
              'La sincronización automática es una función Pro exclusiva.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
            ),
          ),
          const SizedBox(width: DesignTokens.spacingSm),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMd,
                vertical: DesignTokens.spacingSm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: DesignTokens.borderRadiusXl,
              ),
            ),
            child: const Text('Ver más'),
          ),
        ],
      ),
    );
  }
}

/// Panel de diagnóstico de sync (Stitch).
class AccountSyncDiagnosticsPanel extends ConsumerWidget {
  const AccountSyncDiagnosticsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnosticsAsync = ref.watch(syncDiagnosticsProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = TogescColors.of(context);

    return diagnosticsAsync.when(
      loading: () => const TogescCard(
        child: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (SyncDiagnostics d) {
        final globalOk = d.isInSync && d.remoteReachable;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Diagnóstico del sistema',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacingMd),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: DesignTokens.borderRadiusXl,
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (globalOk
                              ? colors.correct
                              : colors.selection)
                          .withValues(alpha: 0.12),
                      borderRadius: DesignTokens.borderRadiusMd,
                    ),
                    child: Icon(
                      globalOk
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      color: globalOk
                          ? colors.correct
                          : colors.selection,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estado global',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          globalOk ? 'Operativo y seguro' : d.statusLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: DesignTokens.borderRadiusXl,
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  if (d.localSession != null)
                    _SyncDetailRow(
                      icon: Icons.laptop_rounded,
                      title: 'Última marca local',
                      subtitle: 'Dispositivo actual',
                      value: d.localSession!,
                    ),
                  if (d.localSession != null && d.remoteSession != null)
                    Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  if (d.remoteSession != null)
                    _SyncDetailRow(
                      icon: Icons.cloud_outlined,
                      title: 'Sincronización cloud',
                      subtitle: 'Servidores TOGESC',
                      value: d.remoteSession!,
                    ),
                  if (d.localSession == null && d.remoteSession == null)
                    _SyncDetailRow(
                      icon: Icons.cloud_off_outlined,
                      title: 'Sesiones',
                      subtitle: d.statusLabel,
                      value: '—',
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SyncDetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;

  const _SyncDetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingSm),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: DesignTokens.borderRadiusMd,
            ),
            child: Icon(icon, color: scheme.onSurfaceVariant, size: 20),
          ),
          const SizedBox(width: DesignTokens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingSm,
                vertical: DesignTokens.spacingXs,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: DesignTokens.borderRadiusMd,
              ),
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Preferencias de práctica inline en cuenta (Stitch sync settings).
class AccountPracticePreferencesCard extends ConsumerWidget {
  const AccountPracticePreferencesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final namingAsync = ref.watch(noteNamingModeProvider);
    final remindersAsync = ref.watch(practiceRemindersEnabledProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Preferencias de práctica',
          style: theme.textTheme.titleMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: DesignTokens.borderRadiusXl,
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              namingAsync.when(
                data: (mode) => SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingMd,
                    vertical: DesignTokens.spacingXs,
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(DesignTokens.spacingSm),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.music_note_rounded,
                      color: scheme.primaryContainer,
                    ),
                  ),
                  title: const Text('Notación Do/Re/Mi'),
                  subtitle: const Text(
                    'Usa solfeo en el piano y en las respuestas.',
                  ),
                  value: mode == NoteNamingMode.solfege,
                  onChanged: (value) {
                    ref.read(noteNamingModeProvider.notifier).setMode(
                          value
                              ? NoteNamingMode.solfege
                              : NoteNamingMode.letter,
                        );
                  },
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(DesignTokens.spacingMd),
                  child: LinearProgressIndicator(),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
              remindersAsync.when(
                data: (enabled) => SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingMd,
                    vertical: DesignTokens.spacingXs,
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(DesignTokens.spacingSm),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: scheme.primaryContainer,
                    ),
                  ),
                  title: const Text('Recordatorios diarios'),
                  subtitle: Text(
                    PracticeReminderService.isSupported
                        ? 'Notificación local si tienes notas vencidas.'
                        : 'Disponible en Android e iOS.',
                  ),
                  value: enabled && PracticeReminderService.isSupported,
                  onChanged: PracticeReminderService.isSupported
                      ? (value) async {
                          await ref
                              .read(practiceRemindersEnabledProvider.notifier)
                              .setEnabled(value);
                          if (value) {
                            await PracticeReminderService.instance
                                .requestPermission();
                          } else {
                            await PracticeReminderService.instance.cancel();
                          }
                        }
                      : null,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Atajo a ajustes de practica (Stitch tile).
class AccountSettingsShortcutCard extends StatelessWidget {
  final VoidCallback onTap;

  const AccountSettingsShortcutCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TogescCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.tune_rounded,
            color: scheme.primaryContainer,
          ),
        ),
        title: const Text('Ajustes de práctica'),
        subtitle: const Text('Sonido, sesión, apariencia y accesibilidad'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

/// Botones de accion sync / logout (Stitch).
class AccountSyncActionButtons extends StatelessWidget {
  final bool showSync;
  final bool busy;
  final VoidCallback? onSync;
  final VoidCallback? onSignOut;
  final String? signOutLabel;

  const AccountSyncActionButtons({
    super.key,
    required this.showSync,
    required this.busy,
    required this.onSync,
    required this.onSignOut,
    this.signOutLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSync)
          FilledButton.icon(
            onPressed: busy ? null : onSync,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: DesignTokens.borderRadiusXl,
              ),
            ),
            icon: const Icon(Icons.sync_rounded),
            label: const Text('Sincronizar ahora'),
          ),
        if (showSync) const SizedBox(height: DesignTokens.spacingMd),
        OutlinedButton.icon(
          onPressed: busy ? null : onSignOut,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: DesignTokens.borderRadiusXl,
            ),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.8),
            ),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: Text(signOutLabel ?? 'Cerrar sesión'),
        ),
      ],
    );
  }
}
