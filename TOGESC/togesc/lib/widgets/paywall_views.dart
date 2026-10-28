import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../app/togesc_colors.dart';

/// Beneficio Pro del paywall v2.1: título y una línea de detalle.
typedef PaywallBenefit = ({IconData icon, String title, String detail});

/// Los 3 beneficios de Pro (paywall y card del plan en Perfil).
const List<PaywallBenefit> paywallBenefits = [
  (
    icon: Icons.piano_rounded,
    title: 'Acordes, aleatorio y modo velocidad',
    detail: 'De 1 a 5 notas simultáneas y ráfagas contra reloj.',
  ),
  (
    icon: Icons.insights_rounded,
    title: 'Estadísticas avanzadas',
    detail: 'Notas más difíciles y más fáciles, evolución por sesión.',
  ),
  (
    icon: Icons.cloud_sync_rounded,
    title: 'Sincronización SRS en la nube',
    detail: 'El mismo progreso en tu móvil y en la web.',
  ),
];

/// Fila de la tabla «Gratis o Pro».
typedef PaywallCompareRow = ({String label, bool free, bool pro});

/// Qué incluye cada plan (sale de `SubscriptionConstants`: los modos
/// gratis son una nota, intervalo y sostenidos).
const List<PaywallCompareRow> paywallCompareRows = [
  (label: 'Una nota, intervalo, sostenidos', free: true, pro: true),
  (label: 'SRS y progreso local', free: true, pro: true),
  (label: 'Acordes y aleatorio', free: false, pro: true),
  (label: 'Modo velocidad', free: false, pro: true),
  (label: 'Estadísticas avanzadas', free: false, pro: true),
  (label: 'Sincronización en la nube', free: false, pro: true),
];

/// Parte `hero` del paywall: overline, píldora «Desbloquea {función}» si
/// se llega desde un candado, titular, texto y los 3 beneficios en
/// tarjetas translúcidas. Texto `onHero` (17,5:1) sobre #2A0640.
class PaywallPitch extends StatelessWidget {
  const PaywallPitch({super.key, required this.subtitle, this.feature});

  /// Función Pro conocida (allowlist PT-10) o null.
  final String? feature;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const muted = DesignTokens.onHeroMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TOGESC Pro'.toUpperCase(),
          style: DesignTokens.overline.copyWith(
            color: DesignTokens.onHeroAccent,
          ),
        ),
        if (feature != null) ...[
          const SizedBox(height: DesignTokens.spacingMd),
          Container(
            key: const ValueKey('paywall-unlock'),
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingMd,
              vertical: DesignTokens.spacingXs + 2,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.onHero.withValues(alpha: 0.12),
              borderRadius: DesignTokens.borderRadiusPill,
              border: Border.all(
                color: DesignTokens.onHeroAccent.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_open_rounded,
                  size: 18,
                  color: DesignTokens.onHeroAccent,
                ),
                const SizedBox(width: DesignTokens.spacingXs + 2),
                Flexible(
                  child: Text(
                    'Desbloquea $feature',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: DesignTokens.onHero,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: DesignTokens.spacingMd),
        Semantics(
          header: true,
          child: Text(
            'Pasa a TOGESC Pro',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: DesignTokens.onHero,
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingLg),
        for (final (i, b) in paywallBenefits.indexed) ...[
          if (i > 0) const SizedBox(height: DesignTokens.spacingSm),
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            decoration: BoxDecoration(
              color: DesignTokens.onHero.withValues(alpha: 0.07),
              borderRadius: DesignTokens.borderRadiusCard,
              border: Border.all(
                color: DesignTokens.onHero.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: DesignTokens.onHero.withValues(alpha: 0.12),
                    borderRadius: DesignTokens.borderRadiusMd,
                  ),
                  child: Icon(b.icon, color: DesignTokens.onHeroAccent),
                ),
                const SizedBox(width: DesignTokens.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: DesignTokens.onHero,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        b.detail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Tabla «Gratis o Pro». Cada celda lleva icono (check o guion) y una
/// etiqueta accesible «Sí» / «No»; la fila entera se lee como una frase.
class PaywallCompareTable extends StatelessWidget {
  const PaywallCompareTable({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = TogescColors.of(context);

    Widget cell(bool yes) => SizedBox(
      width: 56,
      child: Icon(
        yes ? Icons.check_circle_rounded : Icons.remove_rounded,
        color: yes ? colors.correct : scheme.outline,
        size: 22,
      ),
    );

    Widget headCell(String text, {Color? color}) => SizedBox(
      width: 56,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: color ?? scheme.onSurfaceVariant,
        ),
      ),
    );

    return Column(
      key: const ValueKey('paywall-compare'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Incluye',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              headCell('Gratis'),
              headCell('Pro', color: scheme.primary),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        for (final row in paywallCompareRows) ...[
          Divider(height: 1, color: scheme.outlineVariant),
          Semantics(
            label:
                '${row.label}: Gratis, ${row.free ? 'sí' : 'no'}; '
                'Pro, ${row.pro ? 'sí' : 'no'}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: DesignTokens.spacingSm + 2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  cell(row.free),
                  cell(row.pro),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
