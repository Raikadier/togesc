import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/togesc_colors.dart';

/// App bar del Home v2 (56): logo, chip de racha y avatar.
class HomeAppBar extends StatelessWidget {
  final int streakDays;
  final bool streakRecord;
  final VoidCallback onAvatarTap;

  const HomeAppBar({
    super.key,
    required this.streakDays,
    required this.onAvatarTap,
    this.streakRecord = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = TogescColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: DesignTokens.appBarHeight,
      child: Row(
        children: [
          Semantics(
            header: true,
            child: Text(
              'TOGESC',
              style: DesignTokens.logo.copyWith(color: colors.brand),
            ),
          ),
          const Spacer(),
          StreakChip(streakDays: streakDays, isRecord: streakRecord),
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
                      color: DesignTokens.primaryContainerTint,
                      shape: BoxShape.circle,
                    ),
                    // #6A1B9A en claro; en oscuro daría 1,9:1 y pasa a
                    // `brand` (#DA9CFF).
                    child: Icon(
                      Icons.person_rounded,
                      size: 20,
                      color: dark
                          ? colors.brand
                          : DesignTokens.primaryContainer,
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

  /// Hoy se batió la racha récord: el chip añade «Récord» (v2.2, lote D).
  final bool isRecord;

  const StreakChip({
    super.key,
    required this.streakDays,
    this.isRecord = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final streakLabel = streakDays == 1 ? '1 día' : '$streakDays días';
    return Semantics(
      key: const ValueKey('home-streak-chip'),
      label: 'Racha de práctica: $streakLabel${isRecord ? ', récord' : ''}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: TogescColors.of(context).muted,
          borderRadius: DesignTokens.borderRadiusPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // #FFB300 sobre el chip claro da 1,6:1; en claro va el ámbar
            // profundo (3:1 de icono informativo).
            Icon(
              Icons.local_fire_department_rounded,
              size: 18,
              color: Theme.of(context).brightness == Brightness.light
                  ? TogescColors.of(context).selectionDeep
                  : DesignTokens.ctaAmber,
            ),
            const SizedBox(width: 4),
            Text(
              '$streakDays',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  )
                  .merge(DesignTokens.tabularNumbers),
            ),
            if (isRecord) ...[
              const SizedBox(width: 6),
              Text(
                'Récord',
                key: const ValueKey('home-streak-record'),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ],
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
        color: color ?? TogescColors.of(context).textTertiary,
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
