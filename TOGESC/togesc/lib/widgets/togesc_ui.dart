import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../app/togesc_colors.dart';
import '../utils/number_format.dart';

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

    // Un solo nodo con nombre y acción: sin esto el `Card` se quedaba el
    // texto y el `InkWell` exponía un tap sin etiqueta (WCAG 4.1.2).
    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        borderRadius: DesignTokens.borderRadiusCard,
        child: card,
      ),
    );
  }
}

/// Contenedor de pagina con max-width Stitch y margen responsive.
class TogescPageBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;
  final double maxWidth;

  const TogescPageBody({
    super.key,
    required this.child,
    this.padding,
    this.scrollable = true,
    this.maxWidth = DesignTokens.contentMaxWidth,
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
        constraints: BoxConstraints(maxWidth: maxWidth),
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
          _Metric(label: 'Seguidas', value: '$streak', style: style),
          _Metric(
            label: 'Límite',
            value: formatSecondsEs(timeLimit),
            style: style,
          ),
          _Metric(
            label: 'Promedio',
            value: averageTime != null
                ? formatSecondsEs(averageTime!, decimals: 2)
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
    // Flexible + scaleDown: con texto grande las tres métricas encogen en
    // lugar de desbordar la fila.
    return Flexible(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: DesignTokens.overline.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: style
                  ?.copyWith(fontWeight: FontWeight.w700, color: scheme.primary)
                  .merge(DesignTokens.tabularNumbers),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón principal único (v2.2, lote E): ámbar del Home, 17/800, alto
/// `ctaHeight` y la sombra del prototipo. Una sola acción principal por
/// pantalla; el resto de botones son secundarios.
class TogescCta extends StatelessWidget {
  const TogescCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.compact = false,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Ocupa todo el ancho disponible.
  final bool expand;

  /// Alto mínimo táctil (48) en lugar de `ctaHeight`, para filas de acciones.
  final bool compact;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final height = compact
        ? DesignTokens.touchTargetMin
        : DesignTokens.ctaHeight;
    final style = FilledButton.styleFrom(
      backgroundColor: DesignTokens.ctaAmber,
      foregroundColor: DesignTokens.onCtaAmber,
      minimumSize: Size(expand ? double.infinity : 0, height),
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg),
      shape: RoundedRectangleBorder(borderRadius: DesignTokens.borderRadiusCta),
      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      elevation: 0,
      // Fundido de estado de Material (200 ms): fuera con movimiento reducido.
      animationDuration: motionDuration(
        context,
        const Duration(milliseconds: 200),
      ),
    );
    final button = icon == null
        ? FilledButton(
            onPressed: onPressed,
            autofocus: autofocus,
            style: style,
            child: Text(label),
          )
        : FilledButton.icon(
            onPressed: onPressed,
            autofocus: autofocus,
            style: style,
            icon: Icon(icon, size: 24),
            label: Text(label),
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: DesignTokens.borderRadiusCta,
        boxShadow: onPressed == null ? null : DesignTokens.ctaShadow,
      ),
      child: button,
    );
  }
}

/// Opción de [TogescSegmented].
class TogescSegment<T> {
  const TogescSegment({
    required this.value,
    required this.label,
    this.icon,
    this.tooltip,
  });

  final T value;
  final String label;
  final IconData? icon;
  final String? tooltip;
}

/// Selector segmentado único (v2.2, lote E), con el estilo de «Resumen |
/// Historial»: pastilla apagada y la opción elegida en `tile` y `brand`.
/// Cada opción es un botón con estado «seleccionado» para lectores de
/// pantalla y se activa con Enter o Espacio.
class TogescSegmented<T> extends StatelessWidget {
  const TogescSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.expand = false,
  });

  final List<TogescSegment<T>> segments;

  /// Opción elegida; `null` si ninguna.
  final T? selected;

  /// `null` lo deshabilita.
  final ValueChanged<T>? onChanged;

  /// Reparte todo el ancho entre las opciones.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = TogescColors.of(context);
    final theme = Theme.of(context);
    Widget option(TogescSegment<T> s) {
      final isSelected = s.value == selected;
      final fg = isSelected ? colors.brand : colors.textSecondary;
      Widget child = AnimatedContainer(
        duration: motionDuration(context, DesignTokens.durationFast),
        curve: DesignTokens.easeOut,
        constraints: const BoxConstraints(
          minHeight: DesignTokens.touchTargetMin,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? colors.tile : Colors.transparent,
          borderRadius: DesignTokens.borderRadiusPill,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (s.icon != null) ...[
                Icon(s.icon, size: 18, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                s.label,
                maxLines: 1,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      );
      child = Semantics(
        button: true,
        selected: isSelected,
        inMutuallyExclusiveGroup: true,
        child: InkWell(
          borderRadius: DesignTokens.borderRadiusPill,
          onTap: onChanged == null ? null : () => onChanged!(s.value),
          child: child,
        ),
      );
      if (s.tooltip != null) {
        child = Tooltip(message: s.tooltip!, child: child);
      }
      // Flexible: sin ancho de sobra (texto grande, móvil) la etiqueta
      // encoge con el FittedBox en lugar de desbordar.
      return expand ? Expanded(child: child) : Flexible(child: child);
    }

    return Opacity(
      opacity: onChanged == null ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.muted,
          borderRadius: DesignTokens.borderRadiusPill,
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: [for (final s in segments) option(s)],
        ),
      ),
    );
  }
}
