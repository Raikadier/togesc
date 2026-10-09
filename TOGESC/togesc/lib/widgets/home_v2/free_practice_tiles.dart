import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/togesc_colors.dart';
import '../../constants/game_constants.dart';
import '../../models/engagement_stats.dart';

/// Datos de un modo para los tiles de «Práctica libre» y el catálogo.
class HomeModeEntry {
  final GameMode mode;
  final String title;
  final String subtitle;
  final IconData icon;

  /// El modo es de pago (muestra la marca PRO aunque el usuario lo tenga).
  final bool isPro;

  /// El usuario no puede jugarlo: candado y tap al paywall (D8).
  final bool locked;
  final ModeMasteryStats? mastery;
  final VoidCallback onTap;

  const HomeModeEntry({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isPro,
    required this.locked,
    required this.mastery,
    required this.onTap,
  });

  int get sessions => mastery?.sessionsCount ?? 0;

  /// Precisión real del modo; `null` sin sesiones.
  double? get accuracy => sessions > 0 ? mastery!.accuracyPercent : null;

  /// «86% · 24 ses.» o «Sin sesiones».
  String get progressLabel {
    final acc = accuracy;
    if (acc == null) return 'Sin sesiones';
    return '${acc.round()}% · $sessions ses.';
  }

  String get semanticsLabel {
    final parts = <String>[title];
    final acc = accuracy;
    parts.add(acc == null
        ? 'sin sesiones'
        : '${acc.round()} % de precisión en $sessions '
            '${sessions == 1 ? 'sesión' : 'sesiones'}');
    if (locked) {
      parts.add('requiere Pro');
    } else if (isPro) {
      parts.add('Pro');
    }
    return parts.join(', ');
  }
}

/// Tres tiles de práctica libre en una fila.
class FreePracticeTiles extends StatelessWidget {
  final List<HomeModeEntry> entries;

  const FreePracticeTiles({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(width: DesignTokens.spacingSm),
            Expanded(child: FreePracticeTile(entry: entries[i])),
          ],
        ],
      ),
    );
  }
}

class FreePracticeTile extends StatelessWidget {
  final HomeModeEntry entry;

  const FreePracticeTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = TogescColors.of(context);
    final acc = entry.accuracy;

    return Semantics(
      button: true,
      label: entry.semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: colors.tile,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusCard,
          side: BorderSide(color: colors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('free-tile-${entry.mode.name}'),
          onTap: entry.onTap,
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(entry.icon, size: 22, color: colors.brand),
                    const Spacer(),
                    if (entry.isPro) ProBadge(locked: entry.locked),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingSm),
                Text(
                  entry.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                const SizedBox(height: DesignTokens.spacingSm),
                ClipRRect(
                  borderRadius: DesignTokens.borderRadiusPill,
                  child: SizedBox(
                    height: 4,
                    child: LinearProgressIndicator(
                      value: acc == null ? 0 : (acc / 100).clamp(0.0, 1.0),
                      backgroundColor: colors.muted,
                      color: acc == null
                          ? colors.cardBorder
                          : masteryColor(acc),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.progressLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ).merge(DesignTokens.tabularNumbers),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Marca «PRO», con candado si el usuario no tiene acceso.
class ProBadge extends StatelessWidget {
  final bool locked;

  const ProBadge({super.key, required this.locked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: DesignTokens.pro,
        borderRadius: DesignTokens.borderRadiusPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (locked) ...[
            const Icon(
              Icons.lock_rounded,
              key: ValueKey('pro-lock-icon'),
              size: 11,
              color: Colors.white,
            ),
            const SizedBox(width: 2),
          ],
          const Text(
            'PRO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Catálogo completo de modos («Ver todos»), en un bottom sheet.
Future<void> showAllModesSheet(
  BuildContext context,
  List<HomeModeEntry> entries,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.marginMobile,
            0,
            DesignTokens.marginMobile,
            DesignTokens.marginMobile,
          ),
          child: Column(
            key: const ValueKey('all-modes-sheet'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Todos los modos',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingSm),
              for (final entry in entries)
                Semantics(
                  button: true,
                  label: entry.semanticsLabel,
                  excludeSemantics: true,
                  child: ListTile(
                    key: ValueKey('all-modes-${entry.mode.name}'),
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      entry.icon,
                      color: TogescColors.of(sheetContext).brand,
                    ),
                    title: Text(entry.title),
                    subtitle: Text('${entry.subtitle} · ${entry.progressLabel}'),
                    trailing: entry.isPro
                        ? ProBadge(locked: entry.locked)
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      entry.onTap();
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
