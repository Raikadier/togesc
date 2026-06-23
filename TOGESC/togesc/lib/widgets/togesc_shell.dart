import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../providers/subscription_provider.dart';

/// Shell de navegacion principal (Stitch): header + bottom nav movil.
class TogescShell extends ConsumerWidget {
  final Widget child;

  const TogescShell({super.key, required this.child});

  static int _selectedIndex(String location, bool hasPro) {
    if (location.startsWith(AppRoutes.statistics)) return 1;
    if (location == AppRoutes.paywall ||
        location == AppRoutes.subscription) {
      return 2;
    }
    if (location == AppRoutes.account) return 3;
    return 0;
  }

  void _onTabSelected(BuildContext context, int index, bool hasPro) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        context.go(AppRoutes.statistics);
      case 2:
        context.go(hasPro ? AppRoutes.subscription : AppRoutes.paywall);
      case 3:
        context.go(AppRoutes.account);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final hasPro = ref.watch(hasProAccessProvider);
    final selected = _selectedIndex(location, hasPro);
    final wide = MediaQuery.sizeOf(context).width >= DesignTokens.shellBreakpoint;

    return Scaffold(
      appBar: _TogescShellHeader(
        selectedIndex: selected,
        hasPro: hasPro,
        wide: wide,
        onNavTap: (i) => _onTabSelected(context, i, hasPro),
      ),
      body: child,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: selected,
              surfaceTintColor: Colors.transparent,
              onDestinationSelected: (i) =>
                  _onTabSelected(context, i, hasPro),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.music_note_outlined),
                  selectedIcon: Icon(Icons.music_note_rounded),
                  label: 'Practica',
                ),
                NavigationDestination(
                  icon: Icon(Icons.leaderboard_outlined),
                  selectedIcon: Icon(Icons.leaderboard_rounded),
                  label: 'Stats',
                ),
                NavigationDestination(
                  icon: Icon(Icons.workspace_premium_outlined),
                  selectedIcon: Icon(Icons.workspace_premium_rounded),
                  label: 'Pro',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Perfil',
                ),
              ],
            ),
    );
  }
}

class _TogescShellHeader extends StatelessWidget implements PreferredSizeWidget {
  final int selectedIndex;
  final bool hasPro;
  final bool wide;
  final ValueChanged<int> onNavTap;

  const _TogescShellHeader({
    required this.selectedIndex,
    required this.hasPro,
    required this.wide,
    required this.onNavTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppBar(
      centerTitle: false,
      backgroundColor: scheme.surfaceContainerLowest.withValues(alpha: 0.92),
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      title: Text(
        'TOGESC',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
              letterSpacing: -0.5,
            ),
      ),
      actions: [
        if (wide) ...[
          _DesktopNavLink(
            label: 'Entrenamiento',
            selected: selectedIndex == 0,
            onTap: () => onNavTap(0),
          ),
          _DesktopNavLink(
            label: 'Estadisticas',
            selected: selectedIndex == 1,
            onTap: () => onNavTap(1),
          ),
          _DesktopNavLink(
            label: 'Pro',
            selected: selectedIndex == 2,
            onTap: () => onNavTap(2),
          ),
          const SizedBox(width: DesignTokens.spacingMd),
        ],
        IconButton(
          icon: const Icon(Icons.workspace_premium_outlined),
          tooltip: hasPro ? 'Suscripcion Pro' : 'TOGESC Pro',
          onPressed: () => onNavTap(2),
        ),
        IconButton(
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: DesignTokens.primaryContainer.withValues(alpha: 0.15),
            child: const Icon(
              Icons.person_rounded,
              size: 18,
              color: DesignTokens.primary,
            ),
          ),
          tooltip: 'Cuenta',
          onPressed: () => onNavTap(3),
        ),
        const SizedBox(width: DesignTokens.spacingSm),
      ],
    );
  }
}

class _DesktopNavLink extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DesktopNavLink({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color =
        selected ? scheme.primary : scheme.onSurfaceVariant;

    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
      ),
    );
  }
}

/// Boton CTA con gradiente Pro (Stitch).
class TogescProButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const TogescProButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: DesignTokens.borderRadiusXl,
        child: Ink(
          decoration: BoxDecoration(
            gradient: DesignTokens.proGradient,
            borderRadius: DesignTokens.borderRadiusXl,
          ),
          child: Container(
            constraints: const BoxConstraints(minHeight: DesignTokens.touchTargetMin),
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
