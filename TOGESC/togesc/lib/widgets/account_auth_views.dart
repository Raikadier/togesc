import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import 'togesc_ui.dart';

/// Card de formulario auth (Stitch wave2).
class AccountAuthFormCard extends StatelessWidget {
  final String badge;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const AccountAuthFormCard({
    super.key,
    required this.badge,
    required this.title,
    required this.children,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return TogescCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingMd,
              vertical: DesignTokens.spacingXs,
            ),
            decoration: BoxDecoration(
              gradient: DesignTokens.proGradient,
              borderRadius: DesignTokens.borderRadiusXl,
            ),
            child: Text(
              badge,
              style: theme.textTheme.labelMedium?.copyWith(
                color: DesignTokens.onPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: DesignTokens.spacingSm),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: DesignTokens.spacingLg),
          ...children,
        ],
      ),
    );
  }
}

/// Campo de texto auth con estilo unificado.
class AccountAuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;

  const AccountAuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusXl,
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusXl,
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

/// Boton primario auth con altura minima Stitch.
class AccountAuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AccountAuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(DesignTokens.touchTargetMin),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusXl,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
