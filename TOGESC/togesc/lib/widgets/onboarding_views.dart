import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import 'pedagogy_section_card.dart';

/// Indicador de pasos del onboarding: el paso actual es una pastilla
/// alargada y los ya vistos van rellenos (SPEC v2.1 §2.7).
class OnboardingStepDots extends StatelessWidget {
  const OnboardingStepDots({
    super.key,
    required this.current,
    required this.count,
  });

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = motionDuration(context, DesignTokens.motionMedium);
    return Semantics(
      key: const ValueKey('onboarding-dots'),
      label: 'Paso ${current + 1} de $count',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            AnimatedContainer(
              duration: duration,
              curve: DesignTokens.easeOut,
              width: i == current ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i <= current ? scheme.primary : scheme.outlineVariant,
                borderRadius: DesignTokens.borderRadiusPill,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Arte `hero` de bienvenida: ecualizador de 9 barras y la etiqueta
/// «SRS · variación · limpieza tonal». Las barras se mueven 3 ciclos
/// (menos de 5 s, WCAG 2.2.2) y quedan quietas con movimiento reducido.
class OnboardingWelcomeArt extends StatefulWidget {
  const OnboardingWelcomeArt({super.key});

  static const int bars = 9;
  static const int cycles = 3;

  @override
  State<OnboardingWelcomeArt> createState() => _OnboardingWelcomeArtState();
}

class _OnboardingWelcomeArtState extends State<OnboardingWelcomeArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _eq = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!reduced) {
      _eq.repeat(count: OnboardingWelcomeArt.cycles);
    }
  }

  @override
  void dispose() {
    _eq.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExcludeSemantics(
      child: Container(
        key: const ValueKey('onboarding-welcome-art'),
        height: 180,
        padding: const EdgeInsets.all(DesignTokens.spacingLg),
        decoration: BoxDecoration(
          color: DesignTokens.hero,
          borderRadius: DesignTokens.borderRadiusHero,
        ),
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _eq,
                builder: (context, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var k = 0; k < OnboardingWelcomeArt.bars; k++) ...[
                      if (k > 0) const SizedBox(width: 6),
                      FractionallySizedBox(
                        heightFactor: _barHeight(k, _eq.value),
                        child: Container(
                          width: 10,
                          decoration: BoxDecoration(
                            color: DesignTokens.onHeroAccent.withValues(
                              alpha: 0.55 + 0.05 * (k % 3),
                            ),
                            borderRadius: DesignTokens.borderRadiusPill,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            Text(
              'SRS · variación · limpieza tonal',
              style: theme.textTheme.labelLarge?.copyWith(
                color: DesignTokens.onHero,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Altura relativa de la barra [k]: un perfil de campana que oscila.
  static double _barHeight(int k, double t) {
    const n = OnboardingWelcomeArt.bars;
    final center = 1 - ((k - (n - 1) / 2).abs() / n);
    final wave = 0.5 + 0.5 * math.sin(2 * math.pi * (t + k / n));
    return (0.25 + 0.6 * center * (0.6 + 0.4 * wave)).clamp(0.15, 1.0);
  }
}

/// Cabecera de un paso: overline, titular (anunciado al cambiar) y texto.
class OnboardingStepHeader extends StatelessWidget {
  const OnboardingStepHeader({
    super.key,
    required this.overline,
    required this.title,
    this.lead,
  });

  final String overline;
  final String title;
  final String? lead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          overline.toUpperCase(),
          style: DesignTokens.overline.copyWith(color: scheme.primary),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: scheme.onSurface,
            ),
          ),
        ),
        if (lead != null) ...[
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            lead!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ],
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

/// Tarjeta de estado de la ronda de prueba (icono, título y detalle).
class OnboardingTryStatus extends StatelessWidget {
  const OnboardingTryStatus({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String detail;

  /// Color del icono y del borde (correcto o incorrecto); null en neutro.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = accent ?? scheme.primary;
    return Semantics(
      key: const ValueKey('onboarding-try-status'),
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: DesignTokens.borderRadiusCard,
          border: Border.all(
            color: accent == null ? scheme.outlineVariant : color,
            width: accent == null ? 1 : 2,
          ),
        ),
        child: Row(
          children: [
            ExcludeSemantics(child: Icon(icon, color: color)),
            const SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
