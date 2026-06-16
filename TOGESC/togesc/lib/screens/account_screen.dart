import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/router.dart';
import '../config/subscription_config.dart';
import '../providers/analytics_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/srs_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/sync_provider.dart';
import '../widgets/practice_settings_section.dart';
import '../widgets/sync_diagnostics_card.dart';

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
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuenta y sincronizacion'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PracticeSettingsSection(),
          const SizedBox(height: 16),
          if (!available) ...[
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Sincronizacion no disponible',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Este despliegue no tiene Supabase configurado. Puedes '
              'entrenar con normalidad: el progreso se guarda solo en '
              'tu dispositivo.',
              style: TextStyle(color: muted),
            ),
          ] else if (_recoveryMode || _view == _AccountView.updatePassword) ...[
            const Text(
              'Nueva contrasena',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nueva contrasena',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _updatePassword,
              child: const Text('Guardar contrasena'),
            ),
          ] else if (signedIn) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(email),
              subtitle: Text(
                cloudSync
                    ? 'Progreso sincronizado en la nube'
                    : hasPro
                        ? 'Progreso vinculado a esta cuenta'
                        : 'SRS local (sync Pro requiere suscripcion)',
              ),
            ),
            const SizedBox(height: 8),
            const SyncDiagnosticsCard(),
            if (!verified) ...[
              const SizedBox(height: 8),
              MaterialBanner(
                content: const Text(
                  'Verifica tu email para activar la cuenta por completo.',
                ),
                actions: [
                  TextButton(
                    onPressed: _busy ? null : _resendVerification,
                    child: const Text('Reenviar'),
                  ),
                ],
              ),
            ],
            if (SubscriptionConfig.isActive && !hasPro) ...[
              const SizedBox(height: 8),
              MaterialBanner(
                content: const Text(
                  'La sincronizacion en la nube es una funcion Pro.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => context.push(AppRoutes.paywall),
                    child: const Text('Ver Pro'),
                  ),
                ],
              ),
            ],
            pendingAsync.when(
              data: (pending) {
                if (!pending) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: MaterialBanner(
                    content: const Text(
                      'Hay cambios locales pendientes de subir.',
                    ),
                    leading: const Icon(Icons.cloud_upload_outlined),
                    actions: [
                      TextButton(
                        onPressed: _busy ? null : _syncNow,
                        child: const Text('Subir ahora'),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            if (cloudSync || !SubscriptionConfig.isActive)
              FilledButton.icon(
                onPressed: _busy ? null : _syncNow,
                icon: const Icon(Icons.sync),
                label: const Text('Sincronizar ahora'),
              ),
            if (cloudSync || !SubscriptionConfig.isActive)
              const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesion'),
            ),
          ] else if (_view == _AccountView.forgotPassword) ...[
            const Text(
              'Recuperar contrasena',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _sendPasswordReset,
              child: const Text('Enviar enlace'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _view = _AccountView.signIn;
                        _message = null;
                      }),
              child: const Text('Volver al inicio de sesion'),
            ),
          ] else ...[
            Text(
              _view == _AccountView.signUp ? 'Crear cuenta' : 'Iniciar sesion',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Opcional. Vincula tu progreso SRS entre dispositivos. '
              'Puedes seguir entrenando sin cuenta.',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contrasena',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submitAuth,
              child: Text(
                _view == _AccountView.signUp ? 'Crear cuenta' : 'Entrar',
              ),
            ),
            const SizedBox(height: 8),
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
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(
              _message!,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ],
      ),
    );
  }
}
