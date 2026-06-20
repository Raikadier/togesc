import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:togesc/models/last_practice_session.dart';
import 'package:togesc/models/practice_session_log.dart';
import 'package:togesc/models/practice_session_preferences.dart';
import 'package:togesc/services/app_preferences.dart';
import 'package:togesc/services/srs_system.dart';
import 'package:togesc/services/user_data_export_service.dart';

void main() {
  test('buildJson incluye progreso, preferencias e historial', () async {
    SharedPreferences.setMockInitialValues({});
    final store = AppPreferences(await SharedPreferences.getInstance());
    await store.setPracticeSessionPreferences(
      const PracticeSessionPreferences(
        roundGoal: SessionRoundGoal.ten,
        autoAdvanceAfterResult: true,
      ),
    );
    await store.setPracticeNotePool(['C', 'D', 'E']);
    await store.appendSessionLog(
      PracticeSessionLog(
        modeId: 0,
        kind: PracticeKind.game,
        roundsCompleted: 5,
        correctRounds: 4,
        endedAt: DateTime.utc(2026, 6, 20, 12),
      ),
    );

    final srs = SRSSystem();
    await srs.loadProgress();
    srs.noteData['C']!.weight = 2.5;

    final payload = UserDataExportService.buildPayload(
      srs: srs,
      prefs: store,
      exportedAt: DateTime.utc(2026, 6, 20, 15),
    );

    expect(payload['export_version'], '1.0');
    expect(payload['app'], 'togesc');
    expect(payload['progress'], isA<Map<String, dynamic>>());
    expect(payload['progress']['note_data'], contains('C'));
    expect(payload['preferences']['practice_note_pool'], ['C', 'D', 'E']);
    expect(payload['preferences']['practice_session']['round_goal_rounds'], 10);
    expect(payload['session_history'], hasLength(1));

    final json = UserDataExportService.buildJson(
      srs: srs,
      prefs: store,
      exportedAt: DateTime.utc(2026, 6, 20, 15),
    );
    expect(json, contains('"export_version": "1.0"'));
    expect(json, contains('"rounds": 5'));
  });
}
