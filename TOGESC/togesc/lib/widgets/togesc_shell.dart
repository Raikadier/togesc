import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../providers/subscription_provider.dart';

/// Shell de navegación principal (Stitch): header + rail wide / bottom nav móvil.
class TogescShell extends ConsumerWidget {
  final Widget child;

  const TogescShell({super.key, required this.child});

  static int _selectedIndex(String location, bool hasPro) {
    if (location.startsWith(AppRoutes.statistics)) return 1;
    if (location == AppRoutes.paywall || location == AppRoutes.subscription) {
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

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.music_note_outlined),
      selectedIcon: Icon(Icons.music_note_rounded),
      label: Text('Práctica'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.leaderboard_outlined),
      selectedIcon: Icon(Icons.leaderboard_rounded),
      label: Text('Estadísticas'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.workspace_premium_outlined),
      selectedIcon: Icon(Icons.workspace_premium_rounded),
      label: Text('Pro'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: Text('Perfil'),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final hasPro = ref.watch(hasProAccessProvider);
    final selected = _selectedIndex(location, hasPro);
    final wide =
        MediaQuery.sizeOf(context).width >= DesignTokens.shellBreakpoint;
    final scheme = Theme.of(context).colorScheme;

    final content = SafeArea(
      top: false,
      bottom: wide,
      child: child,
    );

    return Scaffold(
      appBar: _TogescShellHeader(
        hasPro: hasPro,
        onProTap: () => _onTabSelected(context, 2, hasPro),
        onAccountTap: () => _onTabSelected(context, 3, hasPro),
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: selected,
                  onDestinationSelected: (i) =>
                      _onTabSelected(context, i, hasPro),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: scheme.surfaceContainerLowest,
                  indicatorColor: scheme.primaryContainer.withValues(
                    alpha: 0.28,
                  ),
                  selectedIconTheme: IconThemeData(color: scheme.primary),
                  unselectedIconTheme: IconThemeData(
                    color: scheme.onSurfaceVariant,
                  ),
                  selectedLabelTextStyle: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                  unselectedLabelTextStyle: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                  destinations: _railDestinations,
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: selected,
              surfaceTintColor: Colors.transparent,
              onDestinationSelected: (i) => _onTabSelected(context, i, hasPro),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.music_note_outlined),
                  selectedIcon: Icon(Icons.music_note_rounded),
                  label: 'Práctica',
                ),
                NavigationDestination(
                  icon: Icon(Icons.leaderboard_outlined),
                  selectedIcon: Icon(Icons.leaderboard_rounded),
                  label: 'Estadísticas',
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

class _TogescShellHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final bool hasPro;
  final VoidCallback onProTap;
  final VoidCallback onAccountTap;

  const _TogescShellHeader({
    required this.hasPro,
    required this.onProTap,
    required this.onAccountTap,
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
          letterSpacing: -0.8,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.workspace_premium_outlined),
          tooltip: hasPro ? 'Suscripción Pro' : 'TOGESC Pro',
          onPressed: onProTap,
        ),
        IconButton(
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: scheme.primaryContainer.withValues(alpha: 0.15),
            child: Icon(Icons.person_rounded, size: 18, color: scheme.primary),
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
