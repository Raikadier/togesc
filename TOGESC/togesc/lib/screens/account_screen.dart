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
import '../widgets/account_data_section.dart';
import '../widgets/account_monetization_views.dart';
import '../widgets/sync_diagnostics_card.dart';
import '../widgets/togesc_ui.dart';

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

    return TogescScaffold(
      title: 'Cuenta y sincronizacion',
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.marginMobile),
        children: [
          TogescCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tune_rounded),
              title: const Text('Ajustes de practica'),
              subtitle: const Text('Sonido, sesion, apariencia y accesibilidad'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoutes.settings),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          if (!available) ...[
            const SizedBox(height: DesignTokens.spacingLg),
            const AccountOfflineView(),
          ] else if (_recoveryMode || _view == _AccountView.updatePassword) ...[
            TogescCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AccountSectionTitle(title: 'Nueva contrasena'),
                  const SizedBox(height: DesignTokens.spacingLg),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva contrasena',
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingLg),
                  FilledButton(
                    onPressed: _busy ? null : _updatePassword,
                    child: const Text('Guardar contrasena'),
                  ),
                ],
              ),
            ),
          ] else if (signedIn) ...[
            TogescCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor:
                      DesignTokens.primaryContainer.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.person_rounded,
                    color: DesignTokens.primaryContainer,
                  ),
                ),
                title: Text(email),
                subtitle: Text(
                  cloudSync
                      ? 'Progreso sincronizado en la nube'
                      : hasPro
                          ? 'Progreso vinculado a esta cuenta'
                          : 'SRS local (sync Pro requiere suscripcion)',
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            const SyncDiagnosticsCard(),
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
            if (SubscriptionConfig.isActive && !hasPro) ...[
              const SizedBox(height: DesignTokens.spacingMd),
              AccountInfoBanner(
                icon: Icons.workspace_premium_outlined,
                message: 'La sincronizacion en la nube es una funcion Pro.',
                actionLabel: 'Ver Pro',
                onAction: () => context.push(AppRoutes.paywall),
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
            if (cloudSync || !SubscriptionConfig.isActive)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _syncNow,
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text('Sincronizar ahora'),
                ),
              ),
            if (cloudSync || !SubscriptionConfig.isActive)
              const SizedBox(height: DesignTokens.spacingSm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _signOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesion'),
              ),
            ),
          ] else if (_view == _AccountView.forgotPassword) ...[
            TogescCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AccountSectionTitle(title: 'Recuperar contrasena'),
                  const SizedBox(height: DesignTokens.spacingLg),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: DesignTokens.spacingLg),
                  FilledButton(
                    onPressed: _busy ? null : _sendPasswordReset,
                    child: const Text('Enviar enlace'),
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
            ),
          ] else ...[
            TogescCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AccountSectionTitle(
                    title: _view == _AccountView.signUp
                        ? 'Crear cuenta'
                        : 'Iniciar sesion',
                    subtitle:
                        'Opcional. Vincula tu progreso SRS entre dispositivos. '
                        'Puedes seguir entrenando sin cuenta.',
                  ),
                  const SizedBox(height: DesignTokens.spacingLg),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: DesignTokens.spacingMd),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contrasena'),
                  ),
                  const SizedBox(height: DesignTokens.spacingLg),
                  FilledButton(
                    onPressed: _busy ? null : _submitAuth,
                    child: Text(
                      _view == _AccountView.signUp ? 'Crear cuenta' : 'Entrar',
                    ),
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
