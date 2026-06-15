import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/srs_provider.dart';

/// Cuenta opcional y sincronizacion de progreso (Fase 4).
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
      if (_isSignUp) {
        await client.auth.signUp(email: email, password: password);
        setState(() {
          _message =
              'Cuenta creada. Si tu proyecto exige verificacion de email, '
              'revisa tu bandeja antes de sincronizar.';
        });
      } else {
        await client.auth.signInWithPassword(email: email, password: password);
      }

      if (client.auth.currentUser != null) {
        await ref.read(progressSyncOnSignInProvider)();
        if (mounted) {
          setState(() {
            _message = _isSignUp
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
      await ref.read(progressSyncOnSignInProvider)();
      if (mounted) {
        setState(() => _message = 'Sincronizacion completada.');
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
    final available = ref.watch(supabaseAvailableProvider);
    final email = ref.watch(currentUserEmailProvider);
    final signedIn = email != null;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuenta y sincronizacion'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          ] else if (signedIn) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(email),
              subtitle: const Text('Progreso vinculado a esta cuenta'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _syncNow,
              icon: const Icon(Icons.sync),
              label: const Text('Sincronizar ahora'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesion'),
            ),
          ] else ...[
            Text(
              _isSignUp ? 'Crear cuenta' : 'Iniciar sesion',
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
              child: Text(_isSignUp ? 'Crear cuenta' : 'Entrar'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _isSignUp = !_isSignUp;
                        _message = null;
                      }),
              child: Text(
                _isSignUp
                    ? 'Ya tengo cuenta — iniciar sesion'
                    : 'No tengo cuenta — registrarme',
              ),
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
