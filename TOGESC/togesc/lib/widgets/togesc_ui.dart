import 'package:flutter/material.dart';

import '../app/design_tokens.dart';

/// Scaffold con AppBar unificado Harmonic Precision.
class TogescScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final bool automaticallyImplyLeading;

  const TogescScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TogescAppBar(
        title: title,
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// AppBar TOGESC — fondo claro, sin sombra, título centrado.
class TogescAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const TogescAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }
}

/// Card con borde outline y radio 12px (estilo Stitch).
class TogescCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  const TogescCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DesignTokens.spacingLg),
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: onTap,
      borderRadius: DesignTokens.borderRadiusMd,
      child: card,
    );
  }
}

/// Chip de modo o filtro con icono opcional.
class TogescChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  const TogescChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      avatar: icon != null ? Icon(icon, size: 18) : null,
      selected: selected,
      onSelected: onTap == null ? null : (_) => onTap!(),
      showCheckmark: false,
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: selected
            ? DesignTokens.primaryContainer
            : DesignTokens.onSurface,
      ),
      side: BorderSide(
        color: selected
            ? DesignTokens.primaryContainer
            : DesignTokens.outlineVariant,
        width: selected ? 2 : 1,
      ),
    );
  }
}

/// Barra de métricas del modo velocidad (racha, límite, promedio).
class TogescSpeedMetricsBar extends StatelessWidget {
  final int streak;
  final double timeLimit;
  final double? averageTime;

  const TogescSpeedMetricsBar({
    super.key,
    required this.streak,
    required this.timeLimit,
    this.averageTime,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.marginMobile,
        vertical: DesignTokens.spacingSm,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceContainerLow,
        border: const Border(
          bottom: BorderSide(color: DesignTokens.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Metric(label: 'Racha', value: '$streak', style: style),
          _Metric(
            label: 'Limite',
            value: '${timeLimit.toStringAsFixed(1)}s',
            style: style,
          ),
          _Metric(
            label: 'Promedio',
            value: averageTime != null
                ? '${averageTime!.toStringAsFixed(2)}s'
                : '—',
            style: style,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? style;

  const _Metric({
    required this.label,
    required this.value,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: style?.copyWith(color: DesignTokens.onSurfaceVariant),
        ),
        Text(
          value,
          style: style?.copyWith(
            fontWeight: FontWeight.w600,
            color: DesignTokens.primaryContainer,
          ),
        ),
      ],
    );
  }
}
