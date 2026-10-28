import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../config/subscription_config.dart';
import '../providers/analytics_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/srs_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/sync_provider.dart';
import '../widgets/account_auth_sheet.dart';
import '../widgets/account_auth_views.dart';
import '../widgets/account_data_section.dart';
import '../widgets/account_sync_views.dart';
import '../widgets/account_monetization_views.dart';
import '../widgets/info_views.dart';
import '../widgets/profile_views.dart';
import '../widgets/togesc_ui.dart';

/// Perfil v2.1 (SPEC §2.5): identidad, cifras del oído, plan, estado de
/// sincronización, preferencias en línea y datos. La cuenta es opcional.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _newPasswordController = TextEditingController();
  bool _busy = false;
  String? _message;
  bool _recoveryMode = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;

    final password = _newPasswordController.text;
    if (password.length < 6) {
      setState(
        () => _message = 'La contraseña debe tener al menos 6 caracteres.',
      );
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      await client.auth.updateUser(UserAttributes(password: password));
      setState(() {
        _recoveryMode = false;
        _message = 'Contraseña actualizada correctamente.';
      });
    } on AuthException catch (e) {
      setState(() => _message = e.message);
    } catch (_) {
      setState(() => _message = 'No se pudo actualizar la contraseña.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resendVerification() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;

    final email = ref.read(currentUserEmailProvider);
    if (email == null) return;

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      await client.auth.resend(type: OtpType.signup, email: email);
      setState(() => _message = 'Email de verificación reenviado.');
    } on AuthException catch (e) {
      setState(() => _message = e.message);
    } catch (_) {
      setState(() => _message = 'No se pudo reenviar el email.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      await client.auth.signOut();
      ref.invalidate(progressRepositoryProvider);
      ref.invalidate(syncDiagnosticsProvider);
      ref.invalidate(syncPendingProvider);
      ref.invalidate(subscriptionStatusProvider);
      if (mounted) {
        setState(
          () => _message = 'Sesión cerrada. Tu progreso local se conserva.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'No se pudo cerrar sesión.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncNow() async {
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      await ref.read(syncNowProvider)();
      final diagnostics = await ref.refresh(syncDiagnosticsProvider.future);
      ref.invalidate(srsSystemProvider);
      await ref
          .read(analyticsServiceProvider)
          .syncCompleted(inSync: diagnostics.isInSync);
      if (mounted) {
        setState(() {
          _message = diagnostics.isInSync
              ? 'Sincronización completada.'
              : diagnostics.statusLabel;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Error al sincronizar. Revisa tu conexión.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateChangesProvider, (prev, next) {
      next.whenData((state) {
        if (state.event == AuthChangeEvent.passwordRecovery && mounted) {
          setState(() {
            _recoveryMode = true;
            _message = 'Introduce tu nueva contraseña.';
          });
        }
      });
    });

    final available = ref.watch(supabaseAvailableProvider);
    final email = ref.watch(currentUserEmailProvider);
    final signedIn = email != null;
    final verified = ref.watch(emailVerifiedProvider);
    final cloudSync = ref.watch(cloudSyncAvailableProvider);
    final pending = ref.watch(syncPendingProvider).valueOrNull ?? false;
    final hasPro = ref.watch(hasProAccessProvider);
    final syncDiagnostics = ref.watch(syncDiagnosticsProvider).valueOrNull;
    final isSynced = syncDiagnostics?.isInSync ?? cloudSync;
    final syncState = !available
        ? ProfileSyncState.deviceOnly
        : !signedIn
        ? ProfileSyncState.signedOut
        : (pending || !isSynced)
        ? ProfileSyncState.pending
        : ProfileSyncState.synced;
    const gap = SizedBox(height: DesignTokens.spacingLg);

    return Scaffold(
      body: SafeArea(
        child: TogescPageBody(
          scrollable: false,
          child: ListView(
            children: [
              ProfileIdentityHeader(
                email: email,
                verified: verified,
                onSignIn: available ? _openAuthSheet : null,
              ),
              if (_recoveryMode) ...[
                gap,
                AccountAuthFormCard(
                  badge: 'Recuperación',
                  title: 'Nueva contraseña',
                  children: [
                    AccountAuthTextField(
                      controller: _newPasswordController,
                      label: 'Nueva contraseña',
                      obscureText: true,
                    ),
                    const SizedBox(height: DesignTokens.spacingLg),
                    AccountAuthPrimaryButton(
                      label: 'Guardar contraseña',
                      onPressed: _busy ? null : _updatePassword,
                    ),
                  ],
                ),
              ],
              gap,
              const ProfileEarStats(),
              gap,
              // D8: Pro sale de la nav; Perfil es su entrada permanente.
              ProfilePlanCard(
                hasPro: hasPro,
                onOpen: () => context.push(
                  hasPro ? AppRoutes.subscription : AppRoutes.paywall,
                ),
              ),
              gap,
              ProfileSyncStatus(state: syncState),
              if (signedIn) ...[
                if (!verified) ...[
                  const SizedBox(height: DesignTokens.spacingMd),
                  AccountInfoBanner(
                    icon: Icons.mark_email_unread_outlined,
                    message:
                        'Verifica tu email para activar la cuenta por completo.',
                    actionLabel: 'Reenviar',
                    onAction: _busy ? null : _resendVerification,
                  ),
                ],
                if (pending) ...[
                  const SizedBox(height: DesignTokens.spacingMd),
                  AccountInfoBanner(
                    icon: Icons.cloud_upload_outlined,
                    message: 'Hay cambios locales pendientes de subir.',
                    actionLabel: 'Subir ahora',
                    onAction: _busy ? null : _syncNow,
                  ),
                ],
                const SizedBox(height: DesignTokens.spacingMd),
                const AccountSyncDiagnosticsPanel(),
                const SizedBox(height: DesignTokens.spacingMd),
                AccountSyncActionButtons(
                  showSync: cloudSync || !SubscriptionConfig.isActive,
                  busy: _busy,
                  onSync: _syncNow,
                  onSignOut: _signOut,
                  signOutLabel: 'Cerrar sesión',
                ),
              ],
              gap,
              const AccountPracticePreferencesCard(),
              const SizedBox(height: DesignTokens.spacingMd),
              AccountSettingsShortcutCard(
                onTap: () => context.push(AppRoutes.settings),
              ),
              gap,
              AccountDataSection(
                busy: _busy,
                onBusyChanged: (value) => setState(() => _busy = value),
                onMessage: (value) => setState(() => _message = value),
              ),
              gap,
              const InfoSectionHeader(title: 'Información'),
              InfoLinkCard(
                icon: Icons.info_outline_rounded,
                title: 'Acerca de TOGESC',
                subtitle: 'Pedagogía, tutorial y enlaces útiles',
                onTap: () => context.push(AppRoutes.about),
              ),
              if (_message != null) ...[
                gap,
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _message!,
                    key: const ValueKey('account-message'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAuthSheet() async {
    final message = await showAccountAuthSheet(context);
    if (message != null && mounted) setState(() => _message = message);
  }
}
