import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/services.dart';

import '../../app/design_tokens.dart';
import '../../app/togesc_colors.dart';

/// Pestañas de Progreso v2.1 (SPEC §2.3.1).
enum ProgressTab {
  summary('Resumen'),
  history('Historial');

  const ProgressTab(this.label);

  final String label;
}

/// Segmentado «Resumen | Historial» con semántica de pestañas (`tabBar` /
/// `tab`) y flechas ← → para cambiar, como un `role=tablist` web.
class ProgressTabs extends StatefulWidget {
  const ProgressTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ProgressTab selected;
  final ValueChanged<ProgressTab> onChanged;

  @override
  State<ProgressTabs> createState() => _ProgressTabsState();
}

class _ProgressTabsState extends State<ProgressTabs> {
  late final Map<ProgressTab, FocusNode> _nodes = {
    for (final t in ProgressTab.values)
      t: FocusNode(debugLabel: 'progress-tab-${t.name}'),
  };

  @override
  void dispose() {
    for (final n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  void _select(ProgressTab tab, {bool focus = false}) {
    widget.onChanged(tab);
    if (focus) _nodes[tab]!.requestFocus();
  }

  KeyEventResult _onKey(ProgressTab tab, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final values = ProgressTab.values;
    final i = values.indexOf(tab);
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _select(values[(i + 1) % values.length], focus: true);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _select(values[(i - 1 + values.length) % values.length], focus: true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = TogescColors.of(context);
    return Semantics(
      key: const ValueKey('progress-tabs'),
      role: SemanticsRole.tabBar,
      explicitChildNodes: true,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.muted,
          borderRadius: DesignTokens.borderRadiusPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final tab in ProgressTab.values)
              _TabButton(
                tab: tab,
                selected: tab == widget.selected,
                focusNode: _nodes[tab]!,
                onTap: () => _select(tab, focus: true),
                onKey: (event) => _onKey(tab, event),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.focusNode,
    required this.onTap,
    required this.onKey,
  });

  final ProgressTab tab;
  final bool selected;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final KeyEventResult Function(KeyEvent event) onKey;

  @override
  Widget build(BuildContext context) {
    final colors = TogescColors.of(context);
    final theme = Theme.of(context);
    return Semantics(
      role: SemanticsRole.tab,
      selected: selected,
      button: true,
      label: tab.label,
      onTap: onTap,
      excludeSemantics: true,
      child: Focus(
        focusNode: focusNode,
        onKeyEvent: (_, event) => onKey(event),
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return GestureDetector(
              key: ValueKey('progress-tab-${tab.name}'),
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: motionDuration(context, DesignTokens.durationFast),
                curve: DesignTokens.easeOut,
                constraints: const BoxConstraints(
                  minHeight: DesignTokens.touchTargetMin - 8,
                  minWidth: 112,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? colors.tile : colors.muted,
                  borderRadius: DesignTokens.borderRadiusPill,
                  border: Border.all(
                    color: focused ? colors.brand : Colors.transparent,
                    width: focused ? 3 : 0,
                  ),
                ),
                child: Text(
                  tab.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected ? colors.brand : colors.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
