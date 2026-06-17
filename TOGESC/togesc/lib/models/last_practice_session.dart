import '../constants/game_constants.dart';

/// Tipo de pantalla de practica usada en la ultima sesion.
enum PracticeKind { game, speed }

/// Ultima sesion de practica guardada para el CTA "Continuar".
class LastPracticeSession {
  final int modeId;
  final PracticeKind kind;
  final DateTime practicedAt;

  const LastPracticeSession({
    required this.modeId,
    required this.kind,
    required this.practicedAt,
  });

  GameMode? get mode => GameMode.fromId(modeId);

  String get route {
    final resolved = mode;
    if (resolved == null) return '';
    if (kind == PracticeKind.speed) {
      return '/speed/game/${resolved.id}';
    }
    return '/game/${resolved.id}';
  }

  String get label {
    final resolved = mode;
    if (resolved == null) return 'Practica';
    final base = _homeModeTitle(resolved);
    if (kind == PracticeKind.speed) {
      return 'Velocidad · $base';
    }
    return base;
  }

  static String _homeModeTitle(GameMode mode) {
    return switch (mode) {
      GameMode.singleNote => 'Una sola nota',
      GameMode.interval => 'Intervalo (2 notas)',
      GameMode.chord => 'Acorde (3 notas)',
      GameMode.random => 'Aleatorio (1-5 notas)',
      GameMode.sharpsOnly => 'Solo sostenidos',
      _ => mode.displayName,
    };
  }
}
