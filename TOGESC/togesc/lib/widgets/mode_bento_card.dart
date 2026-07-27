import 'package:flutter/material.dart';
import '../app/design_tokens.dart';
import '../app/togesc_colors.dart';
import '../constants/game_constants.dart';
import '../models/engagement_stats.dart';
import '../widgets/togesc_shell.dart';
import '../widgets/togesc_ui.dart';

/// Card bento de modo de juego (Stitch).
class ModeBentoCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isPro;
  final bool locked;
  final ModeMasteryStats? mastery;
  final VoidCallback onTap;
  const ModeBentoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isPro = false,
    this.locked = false,
    this.mastery,
  });
  @override
  State<ModeBentoCard> createState() => _ModeBentoCardState();
}

class _ModeBentoCardState extends State<ModeBentoCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (widget.locked) {
      return Semantics(
        button: true,
        enabled: true,
        label: '${widget.title}, bloqueado, Pro',
        hint: 'Abre la pantalla Pro para desbloquear',
        child: TogescCard(
          color: scheme.surfaceContainerLow,
          padding: const EdgeInsets.all(DesignTokens.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Icon(
                  Icons.lock_rounded,
                  color: scheme.secondary.withValues(alpha: 0.6),
                  size: 20,
                ),
              ),
              _ModeIcon(icon: widget.icon, dimmed: true),
              const SizedBox(height: DesignTokens.spacingMd),
              Text(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingSm),
              Text(
                widget.subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingLg),
              TogescProButton(
                label: 'Desbloquear con Pro',
                onPressed: widget.onTap,
              ),
            ],
          ),
        ),
      );
    }
    final decoration = BoxDecoration(
      color: scheme.surfaceContainerLowest,
      borderRadius: DesignTokens.borderRadiusXl,
      border: Border.all(
        color: _hovered
            ? scheme.primary
            : scheme.outlineVariant.withValues(alpha: 0.6),
      ),
      boxShadow: _hovered
          ? [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
    );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      label: widget.title,
      hint: widget.subtitle,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: DesignTokens.borderRadiusXl,
            child: AnimatedContainer(
              duration: Duration(milliseconds: reduceMotion ? 0 : 200),
              transform: (!reduceMotion && _hovered)
                  ? (Matrix4.identity()..translateByDouble(0.0, -2.0, 0.0, 1.0))
                  : Matrix4.identity(),
              padding: const EdgeInsets.all(DesignTokens.spacingLg),
              decoration: decoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ModeIcon(icon: widget.icon, highlighted: _hovered),
                      if (widget.mastery != null &&
                          widget.mastery!.sessionsCount > 0)
                        _MasteryBadge(mastery: widget.mastery!)
                      else if (widget.isPro)
                        const _ProBadge(),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacingMd),
                  Text(
                    widget.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: _hovered ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingSm),
                  Text(
                    widget.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DesignTokens.spacingMd),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.mastery == null ||
                                widget.mastery!.sessionsCount == 0
                            ? 'Sin sesiones'
                            : '${widget.mastery!.sessionsCount} sesiones',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Icon(
                        Icons.play_circle_outline_rounded,
                        color: scheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeIcon extends StatelessWidget {
  final IconData icon;
  final bool dimmed;
  final bool highlighted;
  const _ModeIcon({
    required this.icon,
    this.dimmed = false,
    this.highlighted = false,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: highlighted ? scheme.primary : scheme.surfaceContainer,
        borderRadius: DesignTokens.borderRadiusXl,
      ),
      child: Icon(
        icon,
        size: 32,
        color: highlighted
            ? scheme.onPrimary
            : (dimmed ? scheme.onSurfaceVariant : scheme.primaryContainer),
      ),
    );
  }
}

class _MasteryBadge extends StatelessWidget {
  final ModeMasteryStats mastery;
  const _MasteryBadge({required this.mastery});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final acc = mastery.accuracyPercent;
    final color = acc >= 80
        ? TogescColors.of(context).correct
        : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingMd,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        mastery.masteryLabel,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(DesignTokens.spacingSm),
      ),
      child: Text(
        'PRO',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

/// Grid de modos bento para Home con progressive disclosure.
///
/// Colapsado: solo modos free (≤4 decisiones). Expandido: free primero, luego Pro.
class ModeBentoGrid extends StatefulWidget {
  final List<
    ({
      GameMode mode,
      IconData icon,
      String title,
      String subtitle,
      bool isPro,
      bool locked,
      ModeMasteryStats? mastery,
      VoidCallback onTap,
    })
  >
  modes;

  /// Notifica al padre cuando cambia expandido (para el enlace «Ver todos»).
  final ValueChanged<bool>? onExpandedChanged;

  const ModeBentoGrid({
    super.key,
    required this.modes,
    this.onExpandedChanged,
  });

  @override
  State<ModeBentoGrid> createState() => ModeBentoGridState();
}

class ModeBentoGridState extends State<ModeBentoGrid> {
  bool _expanded = false;

  bool get expanded => _expanded;

  int get hiddenCount {
    final free = widget.modes.where((m) => !m.isPro).length;
    final total = widget.modes.length;
    return (total - free).clamp(0, total);
  }

  bool get canToggle => hiddenCount > 0;

  void setExpanded(bool value) {
    if (_expanded == value || !canToggle) return;
    setState(() => _expanded = value);
    widget.onExpandedChanged?.call(_expanded);
  }

  void toggle() => setExpanded(!_expanded);

  List<
    ({
      GameMode mode,
      IconData icon,
      String title,
      String subtitle,
      bool isPro,
      bool locked,
      ModeMasteryStats? mastery,
      VoidCallback onTap,
    })
  > get _visibleModes {
    final free = widget.modes.where((m) => !m.isPro).toList();
    final pro = widget.modes.where((m) => m.isPro).toList();
    if (_expanded || pro.isEmpty) {
      return [...free, ...pro];
    }
    return free;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleModes;
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            constraints.maxWidth >= DesignTokens.shellBreakpoint ? 2 : 1;
        // Evita GridView shrinkWrap dentro de scroll padre.
        if (crossAxisCount == 1) {
          return Column(
            children: [
              for (var i = 0; i < visible.length; i++) ...[
                if (i > 0) const SizedBox(height: DesignTokens.spacingMd),
                ModeBentoCard(
                  title: visible[i].title,
                  subtitle: visible[i].subtitle,
                  icon: visible[i].icon,
                  isPro: visible[i].isPro,
                  locked: visible[i].locked,
                  mastery: visible[i].mastery,
                  onTap: visible[i].onTap,
                ),
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < visible.length; i += 2) {
          final left = visible[i];
          final hasRight = i + 1 < visible.length;
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ModeBentoCard(
                      title: left.title,
                      subtitle: left.subtitle,
                      icon: left.icon,
                      isPro: left.isPro,
                      locked: left.locked,
                      mastery: left.mastery,
                      onTap: left.onTap,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingMd),
                  Expanded(
                    child: hasRight
                        ? ModeBentoCard(
                            title: visible[i + 1].title,
                            subtitle: visible[i + 1].subtitle,
                            icon: visible[i + 1].icon,
                            isPro: visible[i + 1].isPro,
                            locked: visible[i + 1].locked,
                            mastery: visible[i + 1].mastery,
                            onTap: visible[i + 1].onTap,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
          if (i + 2 < visible.length) {
            rows.add(const SizedBox(height: DesignTokens.spacingMd));
          }
        }
        return Column(children: rows);
      },
    );
  }
}
