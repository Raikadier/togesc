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
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: DesignTokens.contentMaxWidth,
            ),
            child: body,
          ),
        ),
      ),
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

/// Card con borde outline y radio de card v2 (14, `radiusCard`).
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
    final theme = Theme.of(context);
    final cardColor =
        color ??
        theme.cardTheme.color ??
        theme.colorScheme.surfaceContainerLowest;

    final card = Card(
      color: cardColor,
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: onTap,
      borderRadius: DesignTokens.borderRadiusCard,
      child: card,
    );
  }
}

/// Contenedor de pagina con max-width Stitch y margen responsive.
class TogescPageBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;

  const TogescPageBody({
    super.key,
    required this.child,
    this.padding,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final wide =
        MediaQuery.sizeOf(context).width >= DesignTokens.shellBreakpoint;
    final margin = wide
        ? DesignTokens.marginDesktop
        : DesignTokens.marginMobile;
    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: DesignTokens.contentMaxWidth,
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.all(margin),
          child: child,
        ),
      ),
    );

    if (!scrollable) return content;
    return SingleChildScrollView(child: content);
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.marginMobile,
        vertical: DesignTokens.spacingSm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Metric(label: 'Racha', value: '$streak', style: style),
          _Metric(
            label: 'Límite',
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

  const _Metric({required this.label, required this.value, this.style});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Etiqueta en overline v2 y valor con cifras tabulares. El valor usa
    // `primary` (#4E0078 en claro y #DA9CFF en la sesión oscura): con
    // `primaryContainer` quedaba a 1,2:1 sobre el fondo de la sesión.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: DesignTokens.overline.copyWith(color: scheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: style
              ?.copyWith(fontWeight: FontWeight.w700, color: scheme.primary)
              .merge(DesignTokens.tabularNumbers),
        ),
      ],
    );
  }
}
