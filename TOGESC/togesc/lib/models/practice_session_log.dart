import '../constants/game_constants.dart';
import 'last_practice_session.dart';

/// Entrada de historial local de una sesion de practica (Fase 7C-2).
class PracticeSessionLog {
  final int modeId;
  final PracticeKind kind;
  final int roundsCompleted;
  final int correctRounds;
  final DateTime endedAt;

  const PracticeSessionLog({
    required this.modeId,
    required this.kind,
    required this.roundsCompleted,
    required this.correctRounds,
    required this.endedAt,
  });

  GameMode? get mode => GameMode.fromId(modeId);

  String get modeLabel {
    final m = mode;
    if (m == null) return 'Modo $modeId';
    if (kind == PracticeKind.speed) return 'Velocidad · ${m.displayName}';
    return m.displayName;
  }

  double get accuracyPercent =>
      roundsCompleted > 0 ? (correctRounds / roundsCompleted) * 100 : 0;

  Map<String, dynamic> toJson() => {
        'mode_id': modeId,
        'kind': kind.name,
        'rounds': roundsCompleted,
        'correct': correctRounds,
        'ended_at': endedAt.toIso8601String(),
      };

  factory PracticeSessionLog.fromJson(Map<String, dynamic> json) {
    final kindRaw = json['kind'] as String? ?? PracticeKind.game.name;
    return PracticeSessionLog(
      modeId: json['mode_id'] as int? ?? GameMode.singleNote.id,
      kind: kindRaw == PracticeKind.speed.name
          ? PracticeKind.speed
          : PracticeKind.game,
      roundsCompleted: json['rounds'] as int? ?? 0,
      correctRounds: json['correct'] as int? ?? 0,
      endedAt: DateTime.tryParse(json['ended_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

const int maxSessionHistoryEntries = 50;

/// Orden cromatico para el selector de pool (7C-4).
const List<String> chromaticNotes = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];
