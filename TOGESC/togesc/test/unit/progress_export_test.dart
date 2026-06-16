import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/services/progress_export_service.dart';
import 'package:togesc/services/srs_system.dart';

void main() {
  test('buildCsv incluye cabecera y filas de notas', () async {
    final srs = SRSSystem();
    await srs.loadProgress();
    srs.noteData['C']!.weight = 3.5;
    srs.noteData['C']!.timesSeen = 10;

    final csv = ProgressExportService.buildCsv(srs);

    expect(csv, contains('nota,peso,en_aprendizaje'));
    expect(csv, contains('C,3.50'));
    expect(csv.split('\n').length, greaterThan(12));
  });
}
