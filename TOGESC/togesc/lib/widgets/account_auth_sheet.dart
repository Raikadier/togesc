import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/design_tokens.dart';
import '../providers/auth_provider.dart';
import '../providers/srs_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/sync_provider.dart';
import 'account_auth_views.dart';

enum AccountAuthMode { signIn, signUp, forgotPassword }

/// Abre la hoja de acceso del Perfil v2.1 (SPEC §2.5). Devuelve el mensaje
/// que debe mostrar el Perfil al cerrarse con éxito (o null).
Future<String?> showAccountAuthSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const AccountAuthSheet(),
  );
}

/// Hoja de acceso con selector Entrar / Crear cuenta y errores en línea
/// (icono + región viva). Los textos son los de la pantalla de cuenta.
class AccountAuthSheet extends ConsumerStatefulWidget {
  const AccountAuthSheet({super.key});

  @override
  ConsumerState<AccountAuthSheet> createState() => _AccountAuthSheetState();
}

class _AccountAuthSheetState extends ConsumerState<AccountAuthSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  AccountAuthMode _mode = AccountAuthMode.signIn;
  bool _busy = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _show(String message, {bool error = true}) {
    setState(() {
      _message = message;
      _isError = error;
    });
  }

  void _setMode(AccountAuthMode mode) => setState(() {
    _mode = mode;
    _message = null;
  });

  Future<void> _submitAuth() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.length < 6) {
      _show('Introduce email y contraseña (min. 6 caracteres).');
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    final signUp = _mode == AccountAuthMode.signUp;
    try {
      if (signUp) {
        await client.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: Uri.base.origin,
        );
        _show(
          'Cuenta creada. Revisa tu email para verificar la cuenta.',
          error: false,
        );
      } else {
        await client.auth.signInWithPassword(email: email, password: password);
      }

      if (client.auth.currentUser != null) {
        await ref.read(progressSyncOnSignInProvider)();
        ref.invalidate(subscriptionStatusProvider);
        ref.invalidate(syncDiagnosticsProvider);
        ref.invalidate(syncPendingProvider);
        if (mounted) {
          Navigator.of(context).pop(
            signUp
                ? 'Sesión iniciada. Progreso local vinculado cuando sea posible.'
                : 'Sesión iniciada. Progreso sincronizado.',
          );
        }
      }
    } on AuthException catch (e) {
      _show(e.message);
    } catch (_) {
      _show('No se pudo completar la operación.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _show('Introduce tu email.');
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
      setState(() => _mode = AccountAuthMode.signIn);
      _show('Revisa tu email para restablecer la contraseña.', error: false);
    } on AuthException catch (e) {
      _show(e.message);
    } catch (_) {
      _show('No se pudo enviar el enlace.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final forgot = _mode == AccountAuthMode.forgotPassword;
    final signUp = _mode == AccountAuthMode.signUp;

    return Padding(
      padding: EdgeInsets.only(
        left: DesignTokens.marginMobile,
        right: DesignTokens.marginMobile,
        bottom:
            MediaQuery.viewInsetsOf(context).bottom + DesignTokens.spacingLg,
      ),
      child: SingleChildScrollView(
        child: Column(
          key: const ValueKey('account-auth-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                forgot ? 'Recuperar contraseña' : 'Tu cuenta TOGESC',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.spacingXs),
            Text(
              forgot
                  ? 'Te enviaremos un enlace a tu email.'
                  : 'Opcional. Vincula tu progreso SRS entre dispositivos. '
                        'Puedes seguir entrenando sin cuenta.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            if (!forgot) ...[
              SegmentedButton<AccountAuthMode>(
                key: const ValueKey('account-auth-mode'),
                segments: const [
                  ButtonSegment(
                    value: AccountAuthMode.signIn,
                    label: Text('Entrar'),
                  ),
                  ButtonSegment(
                    value: AccountAuthMode.signUp,
                    label: Text('Crear cuenta'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: _busy ? null : (s) => _setMode(s.first),
              ),
              const SizedBox(height: DesignTokens.spacingMd),
            ],
            AccountAuthTextField(
              key: const ValueKey('account-auth-email'),
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            if (!forgot) ...[
              const SizedBox(height: DesignTokens.spacingMd),
              AccountAuthTextField(
                key: const ValueKey('account-auth-password'),
                controller: _passwordController,
                label: 'Contraseña',
                obscureText: true,
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: DesignTokens.spacingMd),
              AccountAuthMessage(message: _message!, isError: _isError),
            ],
            const SizedBox(height: DesignTokens.spacingLg),
            AccountAuthPrimaryButton(
              key: const ValueKey('account-auth-submit'),
              label: forgot
                  ? 'Enviar enlace'
                  : (signUp ? 'Crear cuenta' : 'Entrar'),
              onPressed: _busy
                  ? null
                  : (forgot ? _sendPasswordReset : _submitAuth),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            if (forgot)
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _setMode(AccountAuthMode.signIn),
                child: const Text('Volver al inicio de sesión'),
              )
            else if (!signUp)
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _setMode(AccountAuthMode.forgotPassword),
                child: const Text('Olvidé mi contraseña'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Mensaje en línea del formulario: icono de error o de información y
/// región viva, para que el lector de pantalla lo anuncie.
class AccountAuthMessage extends StatelessWidget {
  const AccountAuthMessage({
    super.key,
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = isError ? scheme.error : scheme.primary;
    return Semantics(
      key: const ValueKey('account-auth-message'),
      liveRegion: true,
      container: true,
      label: isError ? 'Error: $message' : message,
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            size: 20,
            color: color,
          ),
          const SizedBox(width: DesignTokens.spacingSm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
