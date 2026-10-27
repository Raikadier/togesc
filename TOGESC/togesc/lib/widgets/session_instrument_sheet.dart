import 'package:flutter/material.dart';

import '../models/audio_preferences.dart';
import '../models/instrument_preset.dart';

/// Hoja «Instrumento de esta sesión» (SPEC v2.1 §2.2.5).
///
/// - «Según preferencias» y «Aleatorio» aplican y cierran la hoja.
/// - Los timbres fijos van en rejilla: al elegir uno se aplica, suena una
///   preescucha ([onPreview]) y la hoja sigue abierta para comparar.
Future<void> showSessionInstrumentSheet({
  required BuildContext context,
  required String? sessionOverrideKey,
  required ValueChanged<String?> onSelected,
  ValueChanged<String>? onPreview,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _InstrumentSheet(
      initial: sessionOverrideKey,
      onSelected: onSelected,
      onPreview: onPreview,
    ),
  );
}

class _InstrumentSheet extends StatefulWidget {
  const _InstrumentSheet({
    required this.initial,
    required this.onSelected,
    this.onPreview,
  });

  final String? initial;
  final ValueChanged<String?> onSelected;
  final ValueChanged<String>? onPreview;

  @override
  State<_InstrumentSheet> createState() => _InstrumentSheetState();
}

class _InstrumentSheetState extends State<_InstrumentSheet> {
  late String? _current = widget.initial;

  void _pickAndClose(String? key) {
    widget.onSelected(key);
    Navigator.pop(context);
  }

  void _pickFixed(String id) {
    setState(() => _current = id);
    widget.onSelected(id);
    widget.onPreview?.call(id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: const ValueKey('session-instrument-sheet'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Instrumento de esta sesión',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          _OptionTile(
            title: 'Según preferencias',
            subtitle: 'Usa la configuración de Cuenta',
            selected: _current == null,
            onTap: () => _pickAndClose(null),
          ),
          _OptionTile(
            title: 'Aleatorio',
            subtitle: 'Un timbre distinto en cada nota',
            selected: _current == AudioPreferences.sessionOverrideRandom,
            onTap: () => _pickAndClose(AudioPreferences.sessionOverrideRandom),
          ),
          const Divider(height: 24),
          Text('Timbre fijo', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 480 ? 3 : 2;
              const gap = 8.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final id in instrumentPresets.keys)
                    SizedBox(
                      width: width,
                      child: _TimbreButton(
                        id: id,
                        selected: _current == id,
                        onTap: () => _pickFixed(id),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            'Solo cambia esta sesión. Al elegir un timbre suena una '
            'preescucha.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimbreButton extends StatelessWidget {
  const _TimbreButton({
    required this.id,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = instrumentLabel(id);
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? '$label, elegido' : label,
      excludeSemantics: true,
      child: OutlinedButton(
        key: ValueKey('session-timbre-$id'),
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor:
              selected ? scheme.primary.withValues(alpha: 0.14) : null,
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          foregroundColor: scheme.onSurface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: selected ? const Icon(Icons.check_rounded) : null,
      selected: selected,
      onTap: onTap,
    );
  }
}

String sessionInstrumentSummary({
  required AudioPreferences prefs,
  required String? sessionOverrideKey,
}) {
  if (sessionOverrideKey == null) {
    if (prefs.instrumentMode == InstrumentMode.random) {
      return 'Preferencias: aleatorio';
    }
    return 'Preferencias: ${instrumentLabel(prefs.fixedInstrumentId)}';
  }
  if (sessionOverrideKey == AudioPreferences.sessionOverrideRandom) {
    return 'Sesión: aleatorio';
  }
  return 'Sesión: ${instrumentLabel(sessionOverrideKey)}';
}
