import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../providers/router_provider.dart';
import '../services/app_preferences.dart';
import '../widgets/home_hub_views.dart';
import '../widgets/info_views.dart';
import '../widgets/pedagogy_section_card.dart';
import '../widgets/togesc_ui.dart';

/// Informacion del proyecto y enfoque pedagogico.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return TogescScaffold(
      title: 'Acerca de TOGESC',
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.marginMobile),
        children: [
          Text(
            'Entrenador de Oido Absoluto',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            'TOGESC (TOne GEneration SCript) es una app educativa de codigo '
            'abierto para entrenar identificacion de alturas musicales con '
            'metodos basados en evidencia. El entrenamiento ocurre en tu '
            'dispositivo; la cuenta en la nube es opcional para sincronizar '
            'progreso entre dispositivos.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: DesignTokens.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          const HomeSectionHeader(title: 'Como entrena la app'),
          const PedagogySectionCard(
            icon: Icons.psychology_rounded,
            accentColor: DesignTokens.primaryContainer,
            title: 'Repeticion espaciada (SRS)',
            body:
                'El sistema repite mas las notas que te cuestan y espacia las '
                'que ya dominas. Asi consolidas memoria a largo plazo.',
          ),
          const PedagogySectionCard(
            icon: Icons.tune_rounded,
            accentColor: DesignTokens.secondary,
            title: 'Variacion de octavas y timbres',
            body:
                'Las notas suenan en distintas octavas y timbres para que '
                'aprendas la clase de altura (Do, Re, Mi...) y no una '
                'frecuencia fija.',
          ),
          const PedagogySectionCard(
            icon: Icons.blur_on_rounded,
            accentColor: DesignTokens.tertiary,
            title: 'Limpieza tonal',
            body:
                'Tras cada ejercicio oiras un sonido caotico breve que rompe '
                'el anclaje al tono anterior y favorece oido absoluto.',
          ),
          const PedagogySectionCard(
            icon: Icons.music_note_rounded,
            accentColor: DesignTokens.primary,
            title: 'Modos de practica',
            body:
                'Una nota, intervalos, acordes, aleatorio y velocidad. '
                'Piano interactivo, entrada por texto y estadisticas locales.',
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          InfoLinkCard(
            icon: Icons.school_outlined,
            title: 'Ver tutorial de nuevo',
            subtitle: 'Repasa como funciona el entrenamiento',
            onTap: () => _replayOnboarding(context),
          ),
          InfoLinkCard(
            icon: Icons.workspace_premium_outlined,
            title: 'Suscripcion Pro',
            subtitle: 'Planes, prueba gratis y gestion',
            onTap: () => context.push(AppRoutes.subscription),
          ),
          InfoLinkCard(
            icon: Icons.person_outline,
            title: 'Cuenta y sincronizacion',
            subtitle: 'Opcional — vincular progreso entre dispositivos',
            onTap: () => context.push(AppRoutes.account),
          ),
          InfoLinkCard(
            icon: Icons.privacy_tip_outlined,
            title: 'Politica de privacidad',
            subtitle: 'Datos locales y cuenta opcional',
            onTap: () => context.push(AppRoutes.privacy),
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            'Version 1.0.0 · Proyecto educativo open source',
            style: theme.textTheme.bodySmall?.copyWith(
              color: DesignTokens.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _replayOnboarding(BuildContext context) async {
    final prefs = AppPreferences(await SharedPreferences.getInstance());
    await prefs.setOnboardingComplete(false);
    refreshAppRouter();
    if (context.mounted) {
      context.go(AppRoutes.onboarding);
    }
  }
}
