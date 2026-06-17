import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/models/last_practice_session.dart';
import 'package:togesc/services/app_preferences.dart';

void main() {
  group('LastPracticeSession', () {
    test('route de juego estandar', () {
      final session = LastPracticeSession(
        modeId: 1,
        kind: PracticeKind.game,
        practicedAt: DateTime(2026, 1, 1),
      );
      expect(session.route, '/game/1');
      expect(session.label, 'Una sola nota');
    });

    test('route de velocidad incluye prefijo', () {
      final session = LastPracticeSession(
        modeId: 2,
        kind: PracticeKind.speed,
        practicedAt: DateTime(2026, 1, 1),
      );
      expect(session.route, '/speed/game/2');
      expect(session.label, 'Velocidad · Intervalo (2 notas)');
    });

    test('mode resuelve GameMode', () {
      final session = LastPracticeSession(
        modeId: 3,
        kind: PracticeKind.game,
        practicedAt: DateTime(2026, 1, 1),
      );
      expect(session.mode, GameMode.chord);
    });
  });

  group('AppPreferences last practice', () {
    test('guarda y carga ultima sesion', () async {
      SharedPreferences.setMockInitialValues({});
      final store = AppPreferences(await SharedPreferences.getInstance());
      final session = LastPracticeSession(
        modeId: GameMode.interval.id,
        kind: PracticeKind.speed,
        practicedAt: DateTime(2026, 6, 15, 10, 30),
      );
      await store.setLastPracticeSession(session);

      final loaded = store.lastPracticeSession;
      expect(loaded?.modeId, GameMode.interval.id);
      expect(loaded?.kind, PracticeKind.speed);
      expect(loaded?.route, '/speed/game/2');
    });
  });
}
