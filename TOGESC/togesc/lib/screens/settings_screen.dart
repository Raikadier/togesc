import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_tokens.dart';
import '../widgets/practice_settings_section.dart';
import '../widgets/togesc_ui.dart';

/// Ajustes de practica, sonido, apariencia y accesibilidad (Fase 7D).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TogescScaffold(
      title: 'Ajustes',
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.marginMobile),
        children: const [
          PracticeSettingsSection(),
        ],
      ),
    );
  }
}
