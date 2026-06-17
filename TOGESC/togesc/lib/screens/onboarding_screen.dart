import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../constants/note_naming.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/router_provider.dart';
import '../services/app_preferences.dart';
import '../widgets/audio_test_button.dart';
import '../widgets/home_hub_views.dart';
import '../widgets/pedagogy_section_card.dart';
import '../widgets/togesc_ui.dart';

/// Introduccion pedagogica: por que SRS, octavas y cluster de limpieza.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _useSolfege = false;

  @override
  Widget build(BuildContext context) {
    return TogescScaffold(
      title: 'Como funciona',
      automaticallyImplyLeading: false,
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.marginMobile),
        children: [
          const OnboardingWelcomeHeader(),
          const SizedBox(height: DesignTokens.spacingLg),
          const PedagogySectionCard(
            icon: Icons.psychology_rounded,
            accentColor: DesignTokens.primaryContainer,
            title: 'Repeticion espaciada (SRS)',
            body:
                'El sistema repite mas las notas que te cuestan y espacia las que '
                'ya dominas. Asi consolidas memoria a largo plazo, no memorizacion '
                'de un dia.',
          ),
          const PedagogySectionCard(
            icon: Icons.tune_rounded,
            accentColor: DesignTokens.secondary,
            title: 'Variacion de octavas y timbres',
            body:
                'Las notas suenan en distintas octavas y con distintos colores '
                'timbrales para que aprendas la clase de altura (Do, Re, Mi...) '
                'y no una frecuencia fija en Hz.',
          ),
          const PedagogySectionCard(
            icon: Icons.blur_on_rounded,
            accentColor: DesignTokens.tertiary,
            title: 'Limpieza tonal',
            body:
                'Tras cada ejercicio oiras un sonido caotico breve que rompe el '
                'anclaje al tono anterior. Asi entrenas identificacion absoluta, '
                'no memoria relativa entre ejercicios.',
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          TogescCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Notacion Do/Re/Mi'),
              subtitle: const Text(
                'Puedes cambiarlo despues en Cuenta.',
              ),
              value: _useSolfege,
              onChanged: (value) => setState(() => _useSolfege = value),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          const AudioTestButton(outlined: false),
          const SizedBox(height: DesignTokens.spacingLg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _complete(context),
              child: const Text('Entendido, empezar'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _complete(BuildContext context) async {
    ref.read(audioPlayerServiceProvider).captureUserGesture();
    final prefs = AppPreferences(await SharedPreferences.getInstance());
    await prefs.setOnboardingComplete(true);
    await prefs.setNoteNamingMode(
      _useSolfege ? NoteNamingMode.solfege : NoteNamingMode.letter,
    );
    ref.invalidate(noteNamingModeProvider);
    refreshAppRouter();
    if (context.mounted) {
      context.go(AppRoutes.home);
    }
  }
}
