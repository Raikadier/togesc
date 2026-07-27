import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../providers/router_provider.dart';
import '../services/app_preferences.dart';
import '../widgets/info_views.dart';
import '../widgets/pedagogy_section_card.dart';
import '../widgets/togesc_ui.dart';

/// Información del proyecto y enfoque pedagógico (Stitch about hub).
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return TogescScaffold(
      title: 'Acerca de TOGESC',
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.marginMobile),
        children: [
          const AboutHeroCard(),
          const SizedBox(height: DesignTokens.spacingLg),
          const InfoSectionHeader(title: 'Cómo entrena la app'),
          PedagogySectionCard(
            icon: Icons.psychology_rounded,
            accentColor: scheme.primaryContainer,
            title: 'Repetición espaciada (SRS)',
            body:
                'El sistema repite más las notas que te cuestan y espacia las '
                'que ya dominas. Así consolidas memoria a largo plazo.',
          ),
          PedagogySectionCard(
            icon: Icons.tune_rounded,
            accentColor: scheme.secondary,
            title: 'Variación de octavas y timbres',
            body:
                'Las notas suenan en distintas octavas y timbres para que '
                'aprendas la clase de altura (Do, Re, Mi…) y no una '
                'frecuencia fija.',
          ),
          PedagogySectionCard(
            icon: Icons.blur_on_rounded,
            accentColor: scheme.tertiary,
            title: 'Limpieza tonal',
            body:
                'Tras cada ejercicio oirás un sonido caótico breve que rompe '
                'el anclaje al tono anterior y favorece oído absoluto.',
          ),
          PedagogySectionCard(
            icon: Icons.music_note_rounded,
            accentColor: scheme.primary,
            title: 'Modos de práctica',
            body:
                'Una nota, intervalos, acordes, aleatorio y velocidad. '
                'Piano interactivo, entrada por texto y estadísticas locales.',
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          const InfoSectionHeader(title: 'Enlaces útiles'),
          InfoLinkCard(
            icon: Icons.school_outlined,
            title: 'Ver tutorial de nuevo',
            subtitle: 'Repasa cómo funciona el entrenamiento',
            onTap: () => _replayOnboarding(context),
          ),
          InfoLinkCard(
            icon: Icons.workspace_premium_outlined,
            title: 'Suscripción Pro',
            subtitle: 'Planes, prueba gratis y gestión',
            onTap: () => context.push(AppRoutes.subscription),
          ),
          InfoLinkCard(
            icon: Icons.person_outline,
            title: 'Cuenta y sincronización',
            subtitle: 'Opcional — vincular progreso entre dispositivos',
            onTap: () => context.push(AppRoutes.account),
          ),
          InfoLinkCard(
            icon: Icons.privacy_tip_outlined,
            title: 'Política de privacidad',
            subtitle: 'Datos locales y cuenta opcional',
            onTap: () => context.push(AppRoutes.privacy),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          Center(
            child: Text(
              'Versión 1.0.0 · Proyecto educativo open source',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _replayOnboarding(BuildContext context) async {
    final prefs = AppPreferences(await SharedPreferences.getInstance());
    await prefs.setOnboardingComplete(false);
    if (!context.mounted) return;
    context.go(AppRoutes.onboarding);
    refreshAppRouter();
  }
}
