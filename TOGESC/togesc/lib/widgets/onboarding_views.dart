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
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMd,
            vertical: DesignTokens.spacingXs,
          ),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            'FORMACIÓN AUDITIVA AVANZADA',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingLg),
        Text(
          'TOGESC',
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.primary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        Text(
          'Entrenador de oído absoluto',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
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
          borderRadius: DesignTokens.borderRadiusXl,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.35),
              scheme.secondaryContainer.withValues(alpha: 0.25),
              scheme.tertiaryContainer.withValues(alpha: 0.3),
            ],
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -24,
              bottom: -28,
              child: Icon(
                Icons.piano_rounded,
                size: reduceMotion ? 120 : 140,
                color: scheme.primary.withValues(alpha: 0.14),
              ),
            ),
            Positioned(
              left: -12,
              top: -16,
              child: Icon(
                Icons.graphic_eq_rounded,
                size: 88,
                color: scheme.secondary.withValues(alpha: 0.12),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.spacingLg),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingMd,
                    vertical: DesignTokens.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLowest.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacingSm),
                      Text(
                        'Motor pedagógico TOGESC',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
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
                borderRadius: DesignTokens.borderRadiusXl,
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
