import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';

/// App bar del Home v2 (56): logo, chip de racha y avatar.
class HomeAppBar extends StatelessWidget {
  final int streakDays;
  final VoidCallback onAvatarTap;

  const HomeAppBar({
    super.key,
    required this.streakDays,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DesignTokens.appBarHeight,
      child: Row(
        children: [
          Semantics(
            header: true,
            child: Text(
              'TOGESC',
              style: DesignTokens.logo.copyWith(color: DesignTokens.primary),
            ),
          ),
          const Spacer(),
          StreakChip(streakDays: streakDays),
          const SizedBox(width: DesignTokens.spacingXs),
          Semantics(
            button: true,
            label: 'Perfil',
            excludeSemantics: true,
            child: InkResponse(
              key: const ValueKey('home-avatar'),
              onTap: onAvatarTap,
              radius: 24,
              child: SizedBox(
                width: DesignTokens.touchTargetMin,
                height: DesignTokens.touchTargetMin,
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0x266A1B9A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 20,
                      color: DesignTokens.primaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de racha (icono fuego ámbar y número de días).
class StreakChip extends StatelessWidget {
  final int streakDays;

  const StreakChip({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final streakLabel = streakDays == 1 ? '1 día' : '$streakDays días';
    return Semantics(
      key: const ValueKey('home-streak-chip'),
      label: 'Racha de práctica: $streakLabel',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: DesignTokens.surfaceContainer,
          borderRadius: DesignTokens.borderRadiusPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              size: 18,
              color: DesignTokens.ctaAmber,
            ),
            const SizedBox(width: 4),
            Text(
              '$streakDays',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ).merge(DesignTokens.tabularNumbers),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overline de fecha («JUEVES 10 DE SEPTIEMBRE»).
class HomeOverline extends StatelessWidget {
  final String text;
  final Color? color;

  const HomeOverline(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      semanticsLabel: text,
      style: DesignTokens.overline.copyWith(
        color: color ?? DesignTokens.textTertiary,
      ),
    );
  }
}

/// Cabecera de sección del Home v2 con acción opcional a la derecha.
class HomeV2SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const HomeV2SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingSm),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
