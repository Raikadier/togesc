import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../constants/note_naming.dart';
import '../../providers/today_session_provider.dart';
import '../../utils/today_session.dart';
import '../../constants/srs_constants.dart';
import '../progress_v2/progress_metrics.dart';
import '../../utils/session_summary.dart';
import '../togesc_ui.dart';

/// Texto del hero derivado solo de datos reales del SRS (D10).
///
/// - Sin notas de foco (SRS vacío o cargando): primera sesión.
/// - Ninguna nota vista: usuario nuevo, se empieza por notas naturales.
/// - Menos de 3 vistas: se dice cuántas tienen datos.
/// - Todas vistas: el motivo real de la selección (atrasadas, en
///   aprendizaje o menor precisión).
/// - [custom]: el usuario eligió las notas foco en «Ajustar enfoque».
String todayHeroCopy(List<TodayFocusNote> focus, {bool custom = false}) {
  if (custom && focus.isNotEmpty) {
    final n = focus.length;
    final notas = n == 1 ? 'una nota foco' : '${_countWord(n)} notas foco';
    return 'Elegiste $notas para hoy; el resto sigue el repaso normal.';
  }
  if (focus.isEmpty) {
    return 'Tu primera sesión dará al repaso los datos para elegir tu foco.';
  }
  final seen = focus.where((f) => f.accuracyPercent != null).length;
  if (seen == 0) {
    return 'Aún no hay datos de precisión: empezarás por notas naturales '
        'para que el repaso conozca tu oído.';
  }
  if (seen < focus.length) {
    final notas = seen == 1 ? '1 nota' : '$seen notas';
    return 'Solo hay datos de $notas; el resto del foco son notas '
        'nuevas.';
  }
  final one = focus.length == 1;
  final count = one ? 'la nota' : 'las ${_countWord(focus.length)} notas';
  if (focus.any((f) => f.isCritical || f.isOverdue)) {
    return one
        ? 'El repaso priorizó $count atrasada o con menor precisión.'
        : 'El repaso priorizó $count atrasadas o con menor precisión.';
  }
  if (focus.any((f) => f.isLearning)) {
    return 'El repaso priorizó $count en aprendizaje o con menor precisión.';
  }
  return 'El repaso priorizó $count con menor precisión.';
}

String _countWord(int n) => switch (n) {
  2 => 'dos',
  3 => 'tres',
  4 => 'cuatro',
  _ => '$n',
};

/// Estado escrito de una nota foco (el color nunca es la única señal).
String focusNoteStateLabel(TodayFocusNote note) {
  final pct = note.accuracyPercent;
  if (pct == null) return 'Nueva';
  return focusNoteStatus(note).title;
}

/// Estado de dominio de una nota foco. Sin intentos conocidos se juzga solo
/// por la precisión.
MasteryStatus focusNoteStatus(TodayFocusNote note) => masteryStatusOf(
  timesSeen: note.accuracyPercent == null
      ? 0
      : (note.timesSeen ?? masteryMinAttempts),
  pct: note.accuracyPercent ?? 0,
);

/// Card hero «Sesión de hoy» (#2A0640) del Home v2.
class TodaySessionHero extends StatelessWidget {
  final TodaySessionPlan plan;
  final VoidCallback onStart;
  final VoidCallback onAdjust;

  /// Hoy ya hay una sesión registrada: el hero lo reconoce y deja de
  /// presentarla como tarea pendiente (v2.2, lote C).
  final bool completedToday;

  /// Precisión de la última sesión de hoy; `null` si no se conoce.
  final double? lastAccuracyPercent;

  /// Pasos «1 · Escucha…»: solo hasta completar la primera sesión.
  final bool showSteps;

  const TodaySessionHero({
    super.key,
    required this.plan,
    required this.onStart,
    required this.onAdjust,
    this.completedToday = false,
    this.lastAccuracyPercent,
    this.showSteps = true,
    this.namingMode = NoteNamingMode.letter,
  });

  /// Notación elegida por el usuario (C·D·E o Do·Re·Mi).
  final NoteNamingMode namingMode;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rounds = plan.rounds;
    final minutes = plan.estimatedMinutes;

    final String summarySemantics;
    if (rounds > 0) {
      summarySemantics = minutes == null
          ? '$rounds rondas'
          : '$rounds rondas, unos $minutes minutos estimados';
    } else {
      summarySemantics = 'Sesión sin límite de rondas';
    }

    return Container(
      key: const ValueKey('today-session-hero'),
      decoration: BoxDecoration(
        color: DesignTokens.hero,
        borderRadius: DesignTokens.borderRadiusHero,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            right: -24,
            top: -18,
            child: ExcludeSemantics(
              child: Icon(
                Icons.graphic_eq_rounded,
                size: 150,
                color: Color(0x14FFFFFF),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (completedToday)
                      const ExcludeSemantics(
                        child: Icon(
                          Icons.check_circle_rounded,
                          key: ValueKey('today-done-icon'),
                          size: 16,
                          color: DesignTokens.onHeroAccent,
                        ),
                      )
                    else
                      const HeroLiveDot(),
                    const SizedBox(width: DesignTokens.spacingSm),
                    Flexible(
                      child: Text(
                        completedToday
                            ? 'SESIÓN DE HOY HECHA'
                            : 'SESIÓN DE HOY',
                        semanticsLabel: completedToday
                            ? 'Sesión de hoy hecha'
                            : 'Sesión de hoy',
                        style: DesignTokens.overline.copyWith(
                          color: DesignTokens.onHeroAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingSm),
                if (completedToday && lastAccuracyPercent != null)
                  Semantics(
                    label:
                        '${lastAccuracyPercent!.round()} por ciento de '
                        'precisión en tu última sesión',
                    excludeSemantics: true,
                    child: _DoneSummary(accuracyPercent: lastAccuracyPercent!),
                  )
                else
                  Semantics(
                    label: summarySemantics,
                    excludeSemantics: true,
                    child: _RoundsSummary(rounds: rounds, minutes: minutes),
                  ),
                const SizedBox(height: DesignTokens.spacingMd),
                Text(
                  completedToday
                      ? 'Hecho por hoy. '
                            '${nextSessionLine([for (final n in plan.focusNotes) formatNoteLabel(n.note, namingMode)])}'
                      : todayHeroCopy(
                          plan.focusNotes,
                          custom: plan.isCustomFocus,
                        ),
                  key: const ValueKey('today-hero-copy'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: DesignTokens.onHero.withValues(alpha: 0.86),
                    height: 1.4,
                  ),
                ),
                if (plan.focusNotes.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.spacingLg),
                  Row(
                    children: [
                      for (var i = 0; i < plan.focusNotes.length; i++) ...[
                        if (i > 0)
                          const SizedBox(width: DesignTokens.spacingSm),
                        Expanded(
                          child: FocusNoteMiniCard(
                            note: plan.focusNotes[i],
                            namingMode: namingMode,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                if (showSteps) ...[
                  const SizedBox(height: DesignTokens.spacingLg),
                  const HeroSteps(),
                ],
                const SizedBox(height: DesignTokens.spacingLg),
                if (!completedToday)
                  TogescCta(
                    key: const ValueKey('today-start-cta'),
                    label: 'Empezar sesión',
                    icon: Icons.play_arrow_rounded,
                    expand: true,
                    onPressed: onStart,
                  )
                else
                  // Con la sesión hecha sigue siendo la única acción
                  // principal, pero ya no parece una tarea pendiente.
                  SizedBox(
                    height: DesignTokens.ctaHeight,
                    child: FilledButton.icon(
                      key: const ValueKey('today-start-cta'),
                      onPressed: onStart,
                      style: FilledButton.styleFrom(
                        backgroundColor: DesignTokens.onHero.withValues(
                          alpha: 0.16,
                        ),
                        foregroundColor: DesignTokens.onHero,
                        shape: RoundedRectangleBorder(
                          borderRadius: DesignTokens.borderRadiusCta,
                        ),
                        textStyle: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 26),
                      label: const Text('Practicar más'),
                    ),
                  ),
                const SizedBox(height: DesignTokens.spacingXs),
                Center(
                  child: TextButton(
                    key: const ValueKey('today-adjust-link'),
                    onPressed: onAdjust,
                    style: TextButton.styleFrom(
                      foregroundColor: DesignTokens.onHeroAccent,
                      minimumSize: const Size(
                        DesignTokens.touchTargetMin,
                        DesignTokens.touchTargetMin,
                      ),
                    ),
                    child: const Text(
                      'Ajustar enfoque y duración',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// «78 % de precisión en tu última sesión», con el número grande del hero.
class _DoneSummary extends StatelessWidget {
  const _DoneSummary({required this.accuracyPercent});

  final double accuracyPercent;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: DesignTokens.spacingSm,
      children: [
        Text(
          '${accuracyPercent.round()} %',
          style: DesignTokens.bigNumber.copyWith(color: DesignTokens.onHero),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'de precisión en tu última sesión',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: DesignTokens.onHero.withValues(alpha: 0.86),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundsSummary extends StatelessWidget {
  final int rounds;
  final int? minutes;

  const _RoundsSummary({required this.rounds, required this.minutes});

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: DesignTokens.onHero.withValues(alpha: 0.86),
      fontWeight: FontWeight.w600,
    );
    if (rounds <= 0) {
      return Text('Sin límite de rondas', style: secondary);
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: DesignTokens.spacingSm,
      children: [
        Text(
          '$rounds',
          style: DesignTokens.bigNumber.copyWith(color: DesignTokens.onHero),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            minutes == null ? 'rondas' : 'rondas · ≈ $minutes min (estimado)',
            style: secondary,
          ),
        ),
      ],
    );
  }
}

/// Mini-card de una nota de foco: nombre, barra de 3 px y %.
class FocusNoteMiniCard extends StatelessWidget {
  final TodayFocusNote note;
  final NoteNamingMode namingMode;

  const FocusNoteMiniCard({
    super.key,
    required this.note,
    this.namingMode = NoteNamingMode.letter,
  });

  @override
  Widget build(BuildContext context) {
    final pct = note.accuracyPercent;
    final textTheme = Theme.of(context).textTheme;
    final label = formatNoteLabel(note.note, namingMode);
    // Va detrás de la cifra («64 % en curso»): en minúscula.
    final state = focusNoteStateLabel(note).toLowerCase();
    final measuring =
        pct != null && focusNoteStatus(note) == MasteryStatus.measuring;
    final attempts = measuringProgressLabel(note.timesSeen ?? 0);
    final semantics = pct == null
        ? 'Nota $label: nueva, sin datos de precisión'
        : measuring
        ? 'Nota $label: midiendo, $attempts intentos'
        : 'Nota $label: ${pct.round()} % de precisión, $state';
    final labelStyle = textTheme.labelMedium
        ?.copyWith(
          color: DesignTokens.onHero.withValues(alpha: 0.86),
          fontWeight: FontWeight.w700,
        )
        .merge(DesignTokens.tabularNumbers);

    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Container(
        key: ValueKey('focus-note-${note.note}'),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: DesignTokens.borderRadiusCell,
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.titleMedium?.copyWith(
                color: DesignTokens.onHero,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: DesignTokens.borderRadiusPill,
              child: SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  value: pct == null
                      ? 0
                      : measuring
                      ? ((note.timesSeen ?? 0) / masteryMinAttempts).clamp(
                          0.0,
                          1.0,
                        )
                      : (pct / 100).clamp(0.0, 1.0),
                  backgroundColor: const Color(0x29FFFFFF),
                  color: pct == null || measuring
                      ? DesignTokens.onHeroAccent
                      : masteryBarColorOnDark(pct),
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (pct == null)
              Text('Nueva', style: labelStyle)
            else
              Wrap(
                spacing: DesignTokens.spacingXs,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    measuring ? attempts : '${pct.round()} %',
                    style: labelStyle,
                  ),
                  Text(state, style: labelStyle),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Punto que late junto a «Sesión de hoy» (escala 1 → 1,6 y opacidad
/// 1 → .35, 1,8 s por pulso). Late [pulses] veces y se queda quieto: así no
/// pasa de 5 s de movimiento automático (WCAG 2.2.2) y no distrae. Fijo con
/// movimiento reducido.
class HeroLiveDot extends StatefulWidget {
  const HeroLiveDot({super.key});

  static const Duration period = Duration(milliseconds: 1800);
  static const int pulses = 2;

  @override
  State<HeroLiveDot> createState() => _HeroLiveDotState();
}

class _HeroLiveDotState extends State<HeroLiveDot>
    with SingleTickerProviderStateMixin {
  // Cada pulso es ida y vuelta: medio periodo en cada sentido.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: HeroLiveDot.period ~/ 2,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced =
        motionDuration(context, HeroLiveDot.period) == Duration.zero;
    if (reduced) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_started) {
      _started = true;
      _controller
          .repeat(reverse: true, count: HeroLiveDot.pulses * 2)
          .whenComplete(() {
            if (mounted) _controller.value = 0;
          });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        key: const ValueKey('today-live-dot'),
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_controller.value);
          return Opacity(
            opacity: 1 - 0.65 * t,
            child: Transform.scale(scale: 1 + 0.6 * t, child: child),
          );
        },
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: DesignTokens.onHeroAccent,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// «1 · Escucha», «2 · Toca la tecla», «3 · El SRS ajusta tu repaso».
class HeroSteps extends StatelessWidget {
  const HeroSteps({super.key});

  static const steps = [
    (Icons.hearing_rounded, '1 · Escucha'),
    (Icons.piano_rounded, '2 · Toca la tecla'),
    (Icons.trending_up_rounded, '3 · El repaso se ajusta a ti'),
  ];

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: DesignTokens.onHero.withValues(alpha: 0.86),
      fontSize: 13,
    );
    return Semantics(
      key: const ValueKey('today-steps'),
      container: true,
      label:
          'Cómo funciona: escucha, toca la tecla y el repaso se ajusta '
          'a ti',
      excludeSemantics: true,
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          for (final (icon, label) in steps)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: DesignTokens.onHeroAccent),
                const SizedBox(width: 6),
                Flexible(child: Text(label, style: style)),
              ],
            ),
        ],
      ),
    );
  }
}
