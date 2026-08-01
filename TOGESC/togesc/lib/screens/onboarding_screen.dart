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
import '../widgets/onboarding_views.dart';
import '../widgets/togesc_ui.dart';

/// Introducción pedagógica: por qué SRS, octavas y cluster de limpieza.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _useSolfege = false;

  @override
  Widget build(BuildContext context) {
    final wide =
        MediaQuery.sizeOf(context).width >= DesignTokens.shellBreakpoint;
    final margin = wide
        ? DesignTokens.marginDesktop
        : DesignTokens.marginMobile;

    return TogescScaffold(
      title: 'Cómo funciona',
      automaticallyImplyLeading: false,
      body: ListView(
        padding: EdgeInsets.all(margin),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: DesignTokens.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const OnboardingWelcomeHeader(),
                  const SizedBox(height: DesignTokens.spacingLg * 2),
                  const OnboardingPedagogyBento(),
                  const SizedBox(height: DesignTokens.spacingLg * 2),
                  const OnboardingVisualHero(),
                  const SizedBox(height: DesignTokens.spacingLg * 2),
                  OnboardingSetupCard(
                    useSolfege: _useSolfege,
                    onSolfegeChanged: (value) =>
                        setState(() => _useSolfege = value),
                    audioTest: const AudioTestButton(outlined: false),
                  ),
                  const SizedBox(height: DesignTokens.spacingLg * 2),
                  OnboardingStartCta(onPressed: () => _complete(context)),
                  const SizedBox(height: DesignTokens.spacingLg),
                  Center(
                    child: Text(
                      'TOGESC',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.45),
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                    ),
                  ),
                ],
              ),
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
