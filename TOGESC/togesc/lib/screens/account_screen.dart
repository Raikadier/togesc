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

enum _AccountView { signIn, signUp, forgotPassword, updatePassword }

/// Cuenta opcional y sincronizacion de progreso (Fase 4).
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
        _message = 'Introduce email y contrasena (min. 6 caracteres).';
      });
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      if (_view == _AccountView.signUp) {
        await client.auth.signUp(email: email, password: password);
        setState(() {
          _message =
              'Cuenta creada. Revisa tu email para verificar la cuenta.';
        });
      } else {
        await client.auth.signInWithPassword(email: email, password: password);
      }

      if (client.auth.currentUser != null) {
        await ref.read(progressSyncOnSignInProvider)();
        if (mounted) {
          setState(() {
            _message = _view == _AccountView.signUp
                ? 'Sesion iniciada. Progreso local vinculado cuando sea posible.'
                : 'Sesion iniciada. Progreso sincronizado.';
          });
        }
      }
    } on AuthException catch (e) {
      setState(() => _message = e.message);
    } catch (_) {
      setState(() => _message = 'No se pudo completar la operacion.');
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
        _message = 'Revisa tu email para restablecer la contrasena.';
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
      setState(() => _message = 'La contrasena debe tener al menos 6 caracteres.');
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
        _message = 'Contrasena actualizada correctamente.';
      });
    } on AuthException catch (e) {
      setState(() => _message = e.message);
    } catch (_) {
      setState(() => _message = 'No se pudo actualizar la contrasena.');
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
      setState(() => _message = 'Email de verificacion reenviado.');
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
      if (mounted) {
        setState(() => _message = 'Sesion cerrada. Tu progreso local se conserva.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'No se pudo cerrar sesion.');
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
      final diagnostics = await ref.read(syncNowProvider)();
      ref.invalidate(srsSystemProvider);
      await ref.read(analyticsServiceProvider).syncCompleted(
            inSync: diagnostics.isInSync,
          );
      if (mounted) {
        setState(() {
          _message = diagnostics.isInSync
              ? 'Sincronizacion completada.'
              : diagnostics.statusLabel;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Error al sincronizar. Revisa tu conexion.');
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
            _message = 'Introduce tu nueva contrasena.';
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
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.marginMobile),
        children: [
          Text(
            'Cuenta y sincronizacion',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.primary,
                ),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          AccountSettingsShortcutCard(
            onTap: () => context.push(AppRoutes.settings),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          const InfoSectionHeader(title: 'Informacion'),
          InfoLinkCard(
            icon: Icons.info_outline_rounded,
            title: 'Acerca de TOGESC',
            subtitle: 'Pedagogia, tutorial y enlaces utiles',
            onTap: () => context.push(AppRoutes.about),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          if (!available) ...[
            const SizedBox(height: DesignTokens.spacingLg),
            const AccountOfflineView(),
          ] else if (_recoveryMode || _view == _AccountView.updatePassword) ...[
            AccountAuthFormCard(
              badge: 'RECUPERACION',
              title: 'Nueva contrasena',
              children: [
                AccountAuthTextField(
                  controller: _newPasswordController,
                  label: 'Nueva contrasena',
                  obscureText: true,
                ),
                const SizedBox(height: DesignTokens.spacingLg),
                AccountAuthPrimaryButton(
                  label: 'Guardar contrasena',
                  onPressed: _busy ? null : _updatePassword,
                ),
              ],
            ),
          ] else if (signedIn) ...[
            AccountProfileHeader(
              email: email,
              userId: userId,
              isSynced: isSynced && ! (pendingAsync.valueOrNull ?? false),
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
            AccountSyncActionButtons(
              showSync: cloudSync || !SubscriptionConfig.isActive,
              busy: _busy,
              onSync: _syncNow,
              onSignOut: _signOut,
              signOutLabel: 'Cerrar sesion',
            ),
          ] else if (_view == _AccountView.forgotPassword) ...[
            AccountAuthFormCard(
              badge: 'CUENTA',
              title: 'Recuperar contrasena',
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
                  child: const Text('Volver al inicio de sesion'),
                ),
              ],
            ),
          ] else ...[
            AccountAuthFormCard(
              badge: 'CUENTA',
              title: _view == _AccountView.signUp
                  ? 'Crear cuenta'
                  : 'Iniciar sesion',
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
                  label: 'Contrasena',
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
                        ? 'Ya tengo cuenta — iniciar sesion'
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
                    child: const Text('Olvide mi contrasena'),
                  ),
              ],
            ),
          ],
          const SizedBox(height: DesignTokens.spacingLg),
          AccountDataSection(
            busy: _busy,
            onBusyChanged: (value) => setState(() => _busy = value),
            onMessage: (value) => setState(() => _message = value),
          ),
          if (_message != null) ...[
            const SizedBox(height: DesignTokens.spacingLg),
            Text(
              _message!,
              style: TextStyle(color: DesignTokens.primaryContainer),
            ),
          ],
        ],
      ),
    );
  }
}
