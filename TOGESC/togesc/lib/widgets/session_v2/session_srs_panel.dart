import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../models/note_progress_summary.dart';
import '../../utils/srs_level.dart';
import 'srs_level_pill.dart';

/// Estado de una nota en el panel «Enfoque SRS de la sesión».
enum SessionFocusStatus {
  critical('Crítica', DesignTokens.sessionError),
  inProgress('En curso', DesignTokens.sessionWarning),
  consolidating('Consolidando', DesignTokens.sessionSuccess),
  noData('Sin datos', DesignTokens.sessionTextSecondary);

  const SessionFocusStatus(this.label, this.color);

  final String label;
  final Color color;
}

/// Fila del panel: nota, estado, % y nivel SRS.
@immutable
class SessionFocusEntry {
  final String note;
  final SessionFocusStatus status;

  /// Precisión histórica; `null` si la nota nunca se ha visto.
  final double? accuracyPercent;
  final int srsLevel;

  const SessionFocusEntry({
    required this.note,
    required this.status,
    required this.accuracyPercent,
    required this.srsLevel,
  });
}

/// Deriva las filas del panel (gap analysis §5):
/// - Crítica: en `critical_notes` o vista con precisión < 50 %.
/// - Consolidando: ya graduada (`!isLearning`).
/// - En curso: el resto de notas vistas.
/// - Sin datos: nunca vista.
List<SessionFocusEntry> buildSessionFocusEntries({
  required List<String> notes,
  required List<NoteProgressSummary> summaries,
  Set<String> criticalNotes = const {},
  int? learningThreshold,
}) {
  final byNote = {for (final s in summaries) s.note: s};
  final result = <SessionFocusEntry>[];
  for (final note in notes) {
    final summary = byNote[note];
    if (summary == null) continue;
    final seen = summary.timesSeen > 0;
    final accuracy = seen ? summary.accuracyPercent : null;
    final level = learningThreshold == null
        ? srsLevelForSummary(summary)
        : srsLevelForSummary(summary, learningThreshold: learningThreshold);
    final SessionFocusStatus status;
    if (criticalNotes.contains(note) ||
        (accuracy != null && accuracy < DesignTokens.masteryAmberThreshold)) {
      status = SessionFocusStatus.critical;
    } else if (!summary.isLearning) {
      status = SessionFocusStatus.consolidating;
    } else if (seen) {
      status = SessionFocusStatus.inProgress;
    } else {
      status = SessionFocusStatus.noData;
    }
    result.add(
      SessionFocusEntry(
        note: note,
        status: status,
        accuracyPercent: accuracy,
        srsLevel: level,
      ),
    );
  }
  return result;
}

/// Panel de 300 de ancho del layout de escritorio (1d).
class SessionSrsPanel extends StatelessWidget {
  final List<SessionFocusEntry> entries;
  final String Function(String note) formatNote;

  /// Las letras de los atajos son inglesas aunque se nombre en solfeo.
  final bool solfegeNames;

  const SessionSrsPanel({
    super.key,
    required this.entries,
    required this.formatNote,
    this.solfegeNames = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = DesignTokens.overline.copyWith(
      color: DesignTokens.sessionTextLabel,
    );

    return Container(
      key: const ValueKey('session-srs-panel'),
      width: DesignTokens.sessionSrsPanelWidth,
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      decoration: BoxDecoration(
        color: DesignTokens.sessionSurface,
        borderRadius: DesignTokens.borderRadiusCard,
        border: Border.all(color: DesignTokens.sessionBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Enfoque SRS de la sesión'.toUpperCase(),
              style: labelStyle,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          if (entries.isEmpty)
            Text(
              'Sin notas de enfoque todavía.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DesignTokens.sessionTextSecondary,
              ),
            )
          else
            ...entries.map((e) => _FocusRow(entry: e, formatNote: formatNote)),
          const SizedBox(height: DesignTokens.spacingMd),
          const Divider(color: DesignTokens.sessionDivider, height: 1),
          const SizedBox(height: DesignTokens.spacingMd),
          Text('Atajos de teclado'.toUpperCase(), style: labelStyle),
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            solfegeNames
                ? 'A–G notas (letras inglesas: C = Do) · ⇧ sostenido · '
                    'R repetir · espacio siguiente'
                : 'A–G notas · ⇧ sostenido · R repetir · espacio siguiente',
            key: const ValueKey('session-shortcuts-legend'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: DesignTokens.sessionTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusRow extends StatelessWidget {
  final SessionFocusEntry entry;
  final String Function(String note) formatNote;

  const _FocusRow({required this.entry, required this.formatNote});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = formatNote(entry.note);
    final pct = entry.accuracyPercent == null
        ? '—'
        : '${entry.accuracyPercent!.round()}%';
    final pctSemantics = entry.accuracyPercent == null
        ? 'sin datos de precisión'
        : '${entry.accuracyPercent!.round()} por ciento';
    return Semantics(
      container: true,
      label: '$name, ${entry.status.label}, $pctSemantics, nivel SRS '
          '${entry.srsLevel} de $srsMaxLevel',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingSm),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: DesignTokens.sessionTextPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.status.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: entry.status.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SrsLevelDots(level: entry.srsLevel),
                  ],
                ),
              ),
              Text(
                pct,
                style: theme.textTheme.titleSmall
                    ?.copyWith(
                      color: DesignTokens.sessionTextPrimary,
                      fontWeight: FontWeight.w700,
                    )
                    .merge(DesignTokens.tabularNumbers),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
