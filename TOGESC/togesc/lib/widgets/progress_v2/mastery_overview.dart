import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/togesc_colors.dart';
import '../../constants/note_naming.dart';
import '../../models/note_progress_summary.dart';
import '../ear_map/ear_map_wheel.dart';
import '../home_v2/ear_map_card.dart' show consolidatedNoteCount;
import 'note_mastery_grid.dart';

/// Vista de la card «Dominio por nota».
enum MasteryView {
  wheel('Rueda'),
  grid('Rejilla');

  const MasteryView(this.label);

  final String label;
}

/// Card «Dominio por nota» de Progreso v2.1 (SPEC §2.3.4).
///
/// - Estrecha (< [sideBySideWidth]): selector «Rueda | Rejilla», rueda por
///   defecto.
/// - Ancha (escritorio): rueda y rejilla lado a lado, sin selector.
/// En las dos vistas, tocar una nota llama a [onNoteTap] (hoja de detalle).
class MasteryOverview extends StatefulWidget {
  const MasteryOverview({
    super.key,
    required this.summaries,
    required this.consolidatedCount,
    required this.inProgressCount,
    required this.onNoteTap,
    this.namingMode = NoteNamingMode.letter,
    this.learningThreshold = 5,
    this.initialView = MasteryView.wheel,
  });

  final List<NoteProgressSummary> summaries;

  /// Notas graduadas por el SRS (subtítulo, como en v2).
  final int consolidatedCount;
  final int inProgressCount;
  final ValueChanged<NoteProgressSummary> onNoteTap;
  final NoteNamingMode namingMode;
  final int learningThreshold;
  final MasteryView initialView;

  /// Ancho a partir del cual se ven las dos vistas a la vez.
  static const double sideBySideWidth = 720;

  @override
  State<MasteryOverview> createState() => _MasteryOverviewState();
}

class _MasteryOverviewState extends State<MasteryOverview> {
  late MasteryView _view = widget.initialView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = TogescColors.of(context);
    final solid = consolidatedNoteCount(widget.summaries);

    final wheel = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: EarMapWheel(
        summaries: widget.summaries,
        namingMode: widget.namingMode,
        learningThreshold: widget.learningThreshold,
        centerValue: '$solid/12',
        centerCaption: 'consolidadas',
        onSelect: widget.onNoteTap,
      ),
    );
    final grid = NoteMasteryGrid(
      summaries: widget.summaries,
      consolidatedCount: widget.consolidatedCount,
      inProgressCount: widget.inProgressCount,
      namingMode: widget.namingMode,
      learningThreshold: widget.learningThreshold,
      onNoteTap: widget.onNoteTap,
      showHeader: false,
    );

    return Container(
      key: const Key('progress-mastery'),
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      decoration: BoxDecoration(
        color: colors.tile,
        borderRadius: DesignTokens.borderRadiusCard,
        border: Border.all(color: colors.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= MasteryOverview.sideBySideWidth;
          final header = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Dominio por nota',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingXs),
                    Text(
                      '${widget.consolidatedCount} consolidadas · '
                      '${widget.inProgressCount} en curso',
                      key: const Key('progress-mastery-subtitle'),
                      style: theme.textTheme.bodyMedium
                          ?.merge(DesignTokens.tabularNumbers)
                          .copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (!wide)
                SegmentedButton<MasteryView>(
                  key: const Key('progress-mastery-view'),
                  showSelectedIcon: false,
                  segments: [
                    for (final v in MasteryView.values)
                      ButtonSegment(value: v, label: Text(v.label)),
                  ],
                  selected: {_view},
                  onSelectionChanged: (next) {
                    if (next.isEmpty) return;
                    setState(() => _view = next.first);
                  },
                ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: DesignTokens.spacingMd),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: Center(child: wheel)),
                    const SizedBox(width: DesignTokens.marginDesktop),
                    Expanded(child: grid),
                  ],
                )
              else if (_view == MasteryView.wheel)
                Center(child: wheel)
              else
                grid,
            ],
          );
        },
      ),
    );
  }
}
