import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/models/srs_intensity_profile.dart';
import 'package:togesc/services/srs_system.dart';

void main() {
  test('perfil intenso programa revisiones mas cortas que relajado', () async {
    final start = DateTime.utc(2026, 6, 20, 12);

    final relaxed = SRSSystem(
      intensityProfile: SrsIntensityProfile.relaxed,
      clock: () => start,
    );
    final intense = SRSSystem(
      intensityProfile: SrsIntensityProfile.intense,
      clock: () => start,
    );

    await relaxed.loadProgress();
    await intense.loadProgress();

    relaxed.updateAfterResponse(
      notes: ['C'],
      correctNotes: ['C'],
      responseTime: 1.0,
    );
    intense.updateAfterResponse(
      notes: ['C'],
      correctNotes: ['C'],
      responseTime: 1.0,
    );

    final relaxedNext = DateTime.parse(relaxed.noteData['C']!.nextReview!);
    final intenseNext = DateTime.parse(intense.noteData['C']!.nextReview!);

    expect(
      intenseNext.isBefore(relaxedNext),
      isTrue,
      reason: 'Intenso debe revisar antes que relajado',
    );
  });

  test('perfil intenso gradua con menos aciertos consecutivos', () {
    expect(SrsIntensityProfile.intense.learningThreshold, 4);
    expect(SrsIntensityProfile.relaxed.learningThreshold, 6);
  });
}
