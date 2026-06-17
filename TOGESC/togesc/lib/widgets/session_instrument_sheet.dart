import 'package:flutter/material.dart';

import '../models/audio_preferences.dart';
import '../models/instrument_preset.dart';

/// Bottom sheet para override de timbre en la sesion actual.
Future<void> showSessionInstrumentSheet({
  required BuildContext context,
  required String? sessionOverrideKey,
  required ValueChanged<String?> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Timbre de esta sesion',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _OptionTile(
                title: 'Segun preferencias',
                subtitle: 'Usa la configuracion de Cuenta',
                selected: sessionOverrideKey == null,
                onTap: () {
                  onSelected(null);
                  Navigator.pop(context);
                },
              ),
              _OptionTile(
                title: 'Aleatorio',
                subtitle: 'Un timbre distinto en cada nota',
                selected: sessionOverrideKey == AudioPreferences.sessionOverrideRandom,
                onTap: () {
                  onSelected(AudioPreferences.sessionOverrideRandom);
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 24),
              Text(
                'Timbre fijo',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              ...instrumentPresets.keys.map((id) {
                return _OptionTile(
                  title: instrumentLabel(id),
                  selected: sessionOverrideKey == id,
                  onTap: () {
                    onSelected(id);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      );
    },
  );
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
    return 'Sesion: aleatorio';
  }
  return 'Sesion: ${instrumentLabel(sessionOverrideKey)}';
}
