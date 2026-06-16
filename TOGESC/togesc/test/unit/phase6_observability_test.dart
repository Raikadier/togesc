import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:togesc/constants/note_naming.dart';
import 'package:togesc/services/app_preferences.dart';

void main() {
  group('letterToSolfege', () {
    test('mapea notas blancas', () {
      expect(letterToSolfege['C'], 'Do');
      expect(letterToSolfege['E'], 'Mi');
      expect(letterToSolfege['B'], 'Si');
    });

    test('formatNoteLabel respeta modo', () {
      expect(formatNoteLabel('G', NoteNamingMode.letter), 'G');
      expect(formatNoteLabel('G', NoteNamingMode.solfege), 'Sol');
    });
  });

  group('AppPreferences CSAT', () {
    test('no muestra encuesta antes de 10 sesiones', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = AppPreferences(await SharedPreferences.getInstance());
      expect(prefs.shouldShowCsatSurvey(), isFalse);
    });

    test('muestra encuesta tras 10 sesiones sin respuesta previa', () async {
      SharedPreferences.setMockInitialValues({sessionCountKey: 10});
      final prefs = AppPreferences(await SharedPreferences.getInstance());
      expect(prefs.shouldShowCsatSurvey(), isTrue);
    });

    test('no muestra si se respondio hace menos de 30 dias', () async {
      final recent = DateTime.now().subtract(const Duration(days: 5));
      SharedPreferences.setMockInitialValues({
        sessionCountKey: 20,
        csatLastSubmittedKey: recent.toIso8601String(),
      });
      final prefs = AppPreferences(await SharedPreferences.getInstance());
      expect(prefs.shouldShowCsatSurvey(), isFalse);
    });

    test('muestra de nuevo tras 30 dias de la ultima respuesta', () async {
      final old = DateTime.now().subtract(const Duration(days: 31));
      SharedPreferences.setMockInitialValues({
        sessionCountKey: 20,
        csatLastSubmittedKey: old.toIso8601String(),
      });
      final prefs = AppPreferences(await SharedPreferences.getInstance());
      expect(prefs.shouldShowCsatSurvey(), isTrue);
    });
  });
}
