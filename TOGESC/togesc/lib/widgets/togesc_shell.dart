import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../app/togesc_colors.dart';
import '../constants/game_constants.dart';
import '../constants/subscription_constants.dart';
import '../providers/subscription_provider.dart';

/// Destinos de la navegación principal v2 (decisión D8).
///
/// Pro ya no es un destino: se llega desde Perfil («TOGESC Pro») y desde
/// los candados de los modos Pro.
enum TogescNavDestination {
  practice('Práctica', Icons.music_note_rounded, Icons.music_note_outlined),
  progress('Progreso', Icons.insights_rounded, Icons.insights_outlined),
  speed('Velocidad', Icons.bolt_rounded, Icons.bolt_outlined),
  profile('Perfil', Icons.person_rounded, Icons.person_outline_rounded);

  const TogescNavDestination(this.label, this.selectedIcon, this.icon);

  final String label;

  /// Variante rellena (FILL 1) para el destino activo.
  final IconData selectedIcon;

  /// Variante en contorno (FILL 0) para el resto.
  final IconData icon;

  /// Destino activo para una ubicación. Rutas sin destino propio:
  /// - `/paywall?feature=Entrenamiento de velocidad` → Velocidad (llegó por
  ///   el candado de la pestaña).
  /// - `/paywall` y `/subscription` → Perfil (Pro vive dentro de Perfil).
  /// - `/settings`, `/about`… → Perfil. Cualquier otra → Práctica.
  static TogescNavDestination forLocation(Uri uri) {
    final path = uri.path;
    if (path == AppRoutes.statistics ||
        path.startsWith('${AppRoutes.statistics}/')) {
      return progress;
    }
    if (path == AppRoutes.speedSelect ||
        path.startsWith('${AppRoutes.speedSelect}/')) {
      return speed;
    }
    if (path == AppRoutes.paywall &&
        uri.queryParameters['feature'] == _speedFeature) {
      return speed;
    }
    if (path == AppRoutes.account ||
        path == AppRoutes.paywall ||
        path == AppRoutes.subscription ||
        path == AppRoutes.settings ||
        path == AppRoutes.about ||
        path == AppRoutes.privacy) {
      return profile;
    }
    return practice;
  }
}

final _speedFeature = SubscriptionConstants.modeProLabel(
  GameMode.speedTraining,
);

/// Navega a [destination]. Si Velocidad está bloqueada, abre el paywall
/// encima de Práctica (`push`), para que su botón de cerrar pueda volver.
void navigateToTogescDestination(
  BuildContext context,
  TogescNavDestination destination, {
  required bool hasPro,
}) {
  switch (destination) {
    case TogescNavDestination.practice:
      context.go(AppRoutes.home);
    case TogescNavDestination.progress:
      context.go(AppRoutes.statistics);
    case TogescNavDestination.speed:
      if (hasPro) {
        context.go(AppRoutes.speedSelect);
      } else {
        context.go(AppRoutes.home);
        context.push(
          '${AppRoutes.paywall}?feature=${Uri.encodeComponent(_speedFeature)}',
        );
      }
    case TogescNavDestination.profile:
      context.go(AppRoutes.account);
  }
}

/// Shell de navegación principal v2.
///
/// - Ancho < [DesignTokens.desktopBreakpoint]: app bar de 56 y barra
///   inferior de 76 ([TogescBottomNav]).
/// - Ancho ≥ [DesignTokens.desktopBreakpoint]: rail izquierdo de 76
///   ([TogescNavRail]) en su variante clara.
///
/// La sesión de juego (`/game/:id`, `/speed/game/:id`) vive fuera del
/// `ShellRoute`, así que en móvil nunca muestra la barra inferior. En
/// escritorio, el layout de sesión puede reutilizar
/// `TogescNavRail(dark: true)`.
class TogescShell extends ConsumerWidget {
  final Widget child;

  const TogescShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = GoRouterState.of(context);
    final hasPro = ref.watch(hasProAccessProvider);
    final selected = TogescNavDestination.forLocation(state.uri);
    final desktop =
        MediaQuery.sizeOf(context).width >= DesignTokens.desktopBreakpoint;

    void onSelect(TogescNavDestination d) =>
        navigateToTogescDestination(context, d, hasPro: hasPro);

    // Velocidad trae su propio app bar (TogescScaffold): no se duplica.
    final showHeader = !desktop && selected != TogescNavDestination.speed;

    final content = SafeArea(top: false, bottom: desktop, child: child);

    return Scaffold(
      appBar: showHeader
          ? _TogescShellHeader(
              onAccountTap: () => onSelect(TogescNavDestination.profile),
            )
          : null,
      body: desktop
          ? Row(
              children: [
                TogescNavRail(selected: selected, onSelected: onSelect),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: desktop
          ? null
          : TogescBottomNav(selected: selected, onSelected: onSelect),
    );
  }
}

/// Barra inferior de 76 (1a/1c). Activo: icono relleno, `primary` y
/// negrita; resto: contorno en `textSecondary`.
class TogescBottomNav extends StatelessWidget {
  const TogescBottomNav({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final TogescNavDestination selected;
  final ValueChanged<TogescNavDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = TogescColors.of(context);

    return Material(
      color: colors.navBar,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: DesignTokens.navBarHeight,
            child: Row(
              children: [
                for (final d in TogescNavDestination.values)
                  Expanded(
                    child: _BottomNavItem(
                      destination: d,
                      selected: d == selected,
                      onTap: () => onSelected(d),
                      textTheme: textTheme,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.textTheme,
  });

  final TogescNavDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final colors = TogescColors.of(context);
    final color = selected ? colors.brand : colors.textSecondary;

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: destination.label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('nav-${destination.name}'),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: DesignTokens.touchTargetMin,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: DesignTokens.spacingXs),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rail izquierdo de 76 (1d): «TG» y 4 destinos de 48 con icono.
///
/// - [dark] `false` (pantallas del shell): sigue el tema activo con
///   [TogescColors] (`navBar`, `divider`, `brand`): #FFFDFE en claro y
///   #1A121E con borde #3A2E42 en oscuro.
/// - [dark] `true` (sesión): fondo `sessionBackground`, borde `sessionChip`.
///
/// En ambas variantes el activo lleva fondo `hero` (#2A0640) e icono
/// `onHeroAccent` (#DA9CFF): 8,5:1. Cada destino es focusable con
/// teclado (Tab + Enter/Espacio), con tooltip y etiqueta semántica.
class TogescNavRail extends StatelessWidget {
  const TogescNavRail({
    super.key,
    required this.selected,
    required this.onSelected,
    this.dark = false,
  });

  final TogescNavDestination? selected;
  final ValueChanged<TogescNavDestination> onSelected;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final colors = TogescColors.of(context);
    final background = dark ? DesignTokens.sessionBackground : colors.navBar;
    final border = dark ? DesignTokens.sessionChip : colors.divider;
    final logoColor = dark ? DesignTokens.sessionAccent : colors.brand;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Navegación principal',
      child: Material(
        color: background,
        child: Container(
          width: DesignTokens.railWidth,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: border)),
          ),
          child: SafeArea(
            right: false,
            child: FocusTraversalGroup(
              child: Column(
                children: [
                  const SizedBox(height: DesignTokens.spacingLg),
                  ExcludeSemantics(
                    child: Text(
                      'TG',
                      style: DesignTokens.logo.copyWith(color: logoColor),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingLg),
                  for (final d in TogescNavDestination.values) ...[
                    _RailItem(
                      destination: d,
                      selected: d == selected,
                      dark: dark,
                      onTap: () => onSelected(d),
                    ),
                    const SizedBox(height: DesignTokens.spacingSm),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  final TogescNavDestination destination;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = TogescColors.of(context);
    final iconColor = selected
        ? DesignTokens.onHeroAccent
        : (dark ? DesignTokens.sessionTextSecondary : colors.textSecondary);
    final focusColor = dark ? DesignTokens.sessionAccent : colors.brand;
    final radius = DesignTokens.borderRadiusCell;

    return Tooltip(
      message: destination.label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        selected: selected,
        label: destination.label,
        onTap: onTap,
        excludeSemantics: true,
        child: Material(
          color: selected ? DesignTokens.hero : Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            key: ValueKey('rail-${destination.name}'),
            onTap: onTap,
            borderRadius: radius,
            focusColor: focusColor.withValues(alpha: 0.24),
            child: SizedBox.square(
              dimension: DesignTokens.touchTargetMin,
              child: Icon(
                selected ? destination.selectedIcon : destination.icon,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// App bar de 56 (1a): logo «TOGESC» 15/800 y avatar. Sin icono Pro (D8).
class _TogescShellHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onAccountTap;

  const _TogescShellHeader({required this.onAccountTap});

  @override
  Size get preferredSize => const Size.fromHeight(DesignTokens.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = TogescColors.of(context);
    return AppBar(
      toolbarHeight: DesignTokens.appBarHeight,
      centerTitle: false,
      backgroundColor: colors.page,
      surfaceTintColor: Colors.transparent,
      foregroundColor: colors.textPrimary,
      automaticallyImplyLeading: false,
      title: Semantics(
        header: true,
        child: Text(
          'TOGESC',
          style: DesignTokens.logo.copyWith(color: colors.brand),
        ),
      ),
      actions: [
        IconButton(
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: DesignTokens.primaryContainer.withValues(
              alpha: 0.15,
            ),
            child: Icon(
              Icons.person_rounded,
              size: 18,
              color: colors.brand,
            ),
          ),
          tooltip: 'Cuenta',
          onPressed: onAccountTap,
        ),
        const SizedBox(width: DesignTokens.spacingSm),
      ],
    );
  }
}

/// Botón CTA con gradiente Pro (Stitch).
class TogescProButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const TogescProButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: DesignTokens.borderRadiusMd,
        child: Ink(
          decoration: BoxDecoration(
            color: DesignTokens.primaryContainer,
            borderRadius: DesignTokens.borderRadiusMd,
          ),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: DesignTokens.touchTargetMin,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingLg,
              vertical: DesignTokens.spacingMd,
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: DesignTokens.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
