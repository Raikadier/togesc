import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import 'pedagogy_section_card.dart';
import 'togesc_ui.dart';

/// Hero de bienvenida en onboarding (Stitch welcome, tono pedagógico).
class OnboardingWelcomeHeader extends StatelessWidget {
  const OnboardingWelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'TOGESC',
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.primary,
            letterSpacing: -0.8,
            height: 1.05,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        Text(
          'Entrenador de oído absoluto',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        Text(
          'Método con repetición espaciada, variación de estímulos y '
          'limpieza tonal. Tres ideas clave antes de empezar:',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

/// Panel visual atmosférico (sin imagen remota; ancla de producto).
class OnboardingVisualHero extends StatelessWidget {
  const OnboardingVisualHero({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label: 'Motor pedagógico TOGESC',
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: DesignTokens.borderRadiusMd,
          color: scheme.surfaceContainer,
          border: Border.all(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -20,
              bottom: -24,
              child: Icon(
                Icons.piano_rounded,
                size: reduceMotion ? 110 : 128,
                color: scheme.primary.withValues(alpha: 0.12),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Motor pedagógico',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingXs),
                    Text(
                      'SRS · variación · limpieza tonal',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bento de tres pilares pedagógicos (Stitch 3-col en wide).
class OnboardingPedagogyBento extends StatelessWidget {
  const OnboardingPedagogyBento({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final cards = [
      PedagogySectionCard(
        icon: Icons.update_rounded,
        accentColor: scheme.primary,
        title: 'Algoritmo SRS',
        body:
            'Repetición inteligente de las notas críticas para consolidar '
            'memoria auditiva a largo plazo.',
        vertical: true,
      ),
      PedagogySectionCard(
        icon: Icons.piano_rounded,
        accentColor: scheme.secondary,
        title: 'Timbre universal',
        body:
            'Entrena en varios registros e instrumentos para reconocer la '
            'clase de altura, no una frecuencia fija.',
        vertical: true,
      ),
      PedagogySectionCard(
        icon: Icons.blur_on_rounded,
        accentColor: scheme.tertiary,
        title: 'Neutralidad tonal',
        body:
            'Un estímulo de limpieza breve tras cada ejercicio evita el '
            'anclaje relativo entre rondas.',
        vertical: true,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= DesignTokens.shellBreakpoint;
        if (!wide) {
          return Column(
            children: [
              for (final card in cards) ...[
                card,
                if (card != cards.last)
                  const SizedBox(height: DesignTokens.spacingMd),
              ],
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: DesignTokens.spacingMd),
                Expanded(child: cards[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// CTA final del onboarding.
class OnboardingStartCta extends StatelessWidget {
  final VoidCallback onPressed;

  const OnboardingStartCta({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: DesignTokens.borderRadiusMd,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Entendido, empezar'),
                SizedBox(width: DesignTokens.spacingSm),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_rounded,
              size: 16,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(width: DesignTokens.spacingXs),
            Text(
              'Progreso SRS local incluido desde el primer día',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Preferencias rápidas en onboarding (notación + audio).
class OnboardingSetupCard extends StatelessWidget {
  final bool useSolfege;
  final ValueChanged<bool> onSolfegeChanged;
  final Widget audioTest;

  const OnboardingSetupCard({
    super.key,
    required this.useSolfege,
    required this.onSolfegeChanged,
    required this.audioTest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return TogescCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Antes de empezar',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Notación Do/Re/Mi'),
            subtitle: const Text('Puedes cambiarlo después en Ajustes.'),
            value: useSolfege,
            onChanged: onSolfegeChanged,
          ),
          Text('Vista previa', style: theme.textTheme.labelLarge),
          const SizedBox(height: DesignTokens.spacingSm),
          Wrap(
            spacing: DesignTokens.spacingSm,
            runSpacing: DesignTokens.spacingSm,
            children: (useSolfege
                    ? const ['Do', 'Re', 'Mi', 'Fa', 'Sol']
                    : const ['C', 'D', 'E', 'F', 'G'])
                .map((note) => Chip(label: Text(note)))
                .toList(),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          Divider(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          const SizedBox(height: DesignTokens.spacingMd),
          audioTest,
        ],
      ),
    );
  }
}
