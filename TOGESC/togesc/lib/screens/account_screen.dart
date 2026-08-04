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
import '../widgets/account_auth_views.dart';
import '../widgets/account_data_section.dart';
import '../widgets/account_sync_views.dart';
import '../widgets/account_monetization_views.dart';
import '../widgets/info_views.dart';
import '../widgets/togesc_ui.dart';

enum _AccountView { signIn, signUp, forgotPassword, updatePassword }

/// Cuenta opcional y sincronización de progreso (Fase 4).
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  _AccountView _view = _AccountView.signIn;
  bool _busy = false;
  String? _message;
  bool _recoveryMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.length < 6) {
      setState(() {
        _message = 'Introduce email y contraseña (min. 6 caracteres).';
      });
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      if (_view == _AccountView.signUp) {
        await client.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: Uri.base.origin,
        );
        setState(() {
          _message =
              'Cuenta creada. Revisa tu email para verificar la cuenta.';
        });
      } else {
        await client.auth.signInWithPassword(email: email, password: password);
      }

      if (client.auth.currentUser != null) {
        await ref.read(progressSyncOnSignInProvider)();
        ref.invalidate(subscriptionStatusProvider);
        ref.invalidate(syncDiagnosticsProvider);
        ref.invalidate(syncPendingProvider);
        if (mounted) {
          setState(() {
            _message = _view == _AccountView.signUp
                ? 'Sesión iniciada. Progreso local vinculado cuando sea posible.'
                : 'Sesión iniciada. Progreso sincronizado.';
          });
        }
      }
    } on AuthException catch (e) {
      setState(() => _message = e.message);
    } catch (_) {
      setState(() => _message = 'No se pudo completar la operación.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _message = 'Introduce tu email.');
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: Uri.base.origin,
      );
      setState(() {
        _message = 'Revisa tu email para restablecer la contraseña.';
        _view = _AccountView.signIn;
      });
    } on AuthException catch (e) {
      setState(() => _message = e.message);
    } catch (_) {
      setState(() => _message = 'No se pudo enviar el enlace.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _updatePassword() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;

    final password = _newPasswordController.text;
    if (password.length < 6) {
      setState(() => _message = 'La contraseña debe tener al menos 6 caracteres.');
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
        _view = _AccountView.signIn;
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
        setState(() => _message = 'Sesión cerrada. Tu progreso local se conserva.');
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
      await ref.read(analyticsServiceProvider).syncCompleted(
            inSync: diagnostics.isInSync,
          );
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
            _view = _AccountView.updatePassword;
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
    final pendingAsync = ref.watch(syncPendingProvider);
    final hasPro = ref.watch(hasProAccessProvider);
    final userId = ref.watch(currentUserIdProvider);
    final syncDiagnostics = ref.watch(syncDiagnosticsProvider).valueOrNull;
    final isSynced = syncDiagnostics?.isInSync ?? cloudSync;

    return Scaffold(
      body: SafeArea(
        child: TogescPageBody(
          scrollable: false,
          child: ListView(
            children: [
          Text(
            'Cuenta',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          if (!available) ...[
            const AccountOfflineView(),
            const SizedBox(height: DesignTokens.spacingLg),
            AccountSettingsShortcutCard(
              onTap: () => context.push(AppRoutes.settings),
            ),
          ] else if (_recoveryMode || _view == _AccountView.updatePassword) ...[
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
          ] else if (signedIn) ...[
            AccountProfileHeader(
              email: email,
              userId: userId,
              isSynced: isSynced && !(pendingAsync.valueOrNull ?? false),
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            if (SubscriptionConfig.isActive && !hasPro) ...[
              AccountSyncProBanner(
                onTap: () => context.push(AppRoutes.paywall),
              ),
              const SizedBox(height: DesignTokens.spacingMd),
            ],
            const AccountSyncDiagnosticsPanel(),
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
            pendingAsync.when(
              data: (pending) {
                if (!pending) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: DesignTokens.spacingMd),
                  child: AccountInfoBanner(
                    icon: Icons.cloud_upload_outlined,
                    message: 'Hay cambios locales pendientes de subir.',
                    actionLabel: 'Subir ahora',
                    onAction: _busy ? null : _syncNow,
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: DesignTokens.spacingLg),
            const AccountPracticePreferencesCard(),
            const SizedBox(height: DesignTokens.spacingMd),
            AccountSettingsShortcutCard(
              onTap: () => context.push(AppRoutes.settings),
            ),
            const SizedBox(height: DesignTokens.spacingLg),
            AccountSyncActionButtons(
              showSync: cloudSync || !SubscriptionConfig.isActive,
              busy: _busy,
              onSync: _syncNow,
              onSignOut: _signOut,
              signOutLabel: 'Cerrar sesión',
            ),
          ] else if (_view == _AccountView.forgotPassword) ...[
            AccountAuthFormCard(
              badge: 'Cuenta',
              title: 'Recuperar contraseña',
              subtitle: 'Te enviaremos un enlace a tu email.',
              children: [
                AccountAuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: DesignTokens.spacingLg),
                AccountAuthPrimaryButton(
                  label: 'Enviar enlace',
                  onPressed: _busy ? null : _sendPasswordReset,
                ),
                const SizedBox(height: DesignTokens.spacingSm),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _view = _AccountView.signIn;
                            _message = null;
                          }),
                  child: const Text('Volver al inicio de sesión'),
                ),
              ],
            ),
          ] else ...[
            AccountAuthFormCard(
              badge: 'Cuenta',
              title: _view == _AccountView.signUp
                  ? 'Crear cuenta'
                  : 'Iniciar sesión',
              subtitle:
                  'Opcional. Vincula tu progreso SRS entre dispositivos. '
                  'Puedes seguir entrenando sin cuenta.',
              children: [
                AccountAuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: DesignTokens.spacingMd),
                AccountAuthTextField(
                  controller: _passwordController,
                  label: 'Contraseña',
                  obscureText: true,
                ),
                const SizedBox(height: DesignTokens.spacingLg),
                AccountAuthPrimaryButton(
                  label: _view == _AccountView.signUp
                      ? 'Crear cuenta'
                      : 'Entrar',
                  onPressed: _busy ? null : _submitAuth,
                ),
                const SizedBox(height: DesignTokens.spacingSm),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _view = _view == _AccountView.signUp
                                ? _AccountView.signIn
                                : _AccountView.signUp;
                            _message = null;
                          }),
                  child: Text(
                    _view == _AccountView.signUp
                        ? 'Ya tengo cuenta — iniciar sesión'
                        : 'No tengo cuenta — registrarme',
                  ),
                ),
                if (_view == _AccountView.signIn)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _view = _AccountView.forgotPassword;
                              _message = null;
                            }),
                    child: const Text('Olvidé mi contraseña'),
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingLg),
            AccountSettingsShortcutCard(
              onTap: () => context.push(AppRoutes.settings),
            ),
          ],
          const SizedBox(height: DesignTokens.spacingLg),
          AccountDataSection(
            busy: _busy,
            onBusyChanged: (value) => setState(() => _busy = value),
            onMessage: (value) => setState(() => _message = value),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          const InfoSectionHeader(title: 'Información'),
          InfoLinkCard(
            icon: Icons.info_outline_rounded,
            title: 'Acerca de TOGESC',
            subtitle: 'Pedagogía, tutorial y enlaces útiles',
            onTap: () => context.push(AppRoutes.about),
          ),
          if (_message != null) ...[
            const SizedBox(height: DesignTokens.spacingLg),
            Text(
              _message!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
            ],
          ),
        ),
      ),
    );
  }
}
