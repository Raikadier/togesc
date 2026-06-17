import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/models/audio_preferences.dart';
import 'package:togesc/services/app_preferences.dart';

void main() {
  group('AudioPreferences', () {
    test('random devuelve null para playback', () {
      const prefs = AudioPreferences(instrumentMode: InstrumentMode.random);
      expect(prefs.playbackInstrument(), isNull);
    });

    test('fixed devuelve instrumento configurado', () {
      const prefs = AudioPreferences(
        instrumentMode: InstrumentMode.fixed,
        fixedInstrumentId: 'piano',
      );
      expect(prefs.playbackInstrument(), 'piano');
    });

    test('override random tiene prioridad', () {
      const prefs = AudioPreferences(
        instrumentMode: InstrumentMode.fixed,
        fixedInstrumentId: 'piano',
      );
      expect(
        prefs.playbackInstrument(
          sessionOverrideKey: AudioPreferences.sessionOverrideRandom,
        ),
        isNull,
      );
    });

    test('override fijo tiene prioridad sobre preferencias', () {
      const prefs = AudioPreferences(
        instrumentMode: InstrumentMode.random,
      );
      expect(
        prefs.playbackInstrument(sessionOverrideKey: 'violin'),
        'violin',
      );
    });
  });

  group('AppPreferences audio', () {
    test('defaults compatibles con comportamiento previo', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = AppPreferences(await SharedPreferences.getInstance());
      final audio = prefs.audioPreferences;

      expect(audio.instrumentMode, InstrumentMode.random);
      expect(audio.fixedInstrumentId, 'sine');
      expect(audio.masterVolume, 1.0);
      expect(audio.clusterEnabled, true);
      expect(audio.clusterDurationSec, 3.0);
    });

    test('persiste y restaura preferencias de audio', () async {
      SharedPreferences.setMockInitialValues({});
      final store = AppPreferences(await SharedPreferences.getInstance());
      await store.setAudioPreferences(
        const AudioPreferences(
          instrumentMode: InstrumentMode.fixed,
          fixedInstrumentId: 'flute',
          masterVolume: 0.5,
          clusterEnabled: false,
          clusterDurationSec: 2.0,
        ),
      );

      final loaded = store.audioPreferences;
      expect(loaded.instrumentMode, InstrumentMode.fixed);
      expect(loaded.fixedInstrumentId, 'flute');
      expect(loaded.masterVolume, 0.5);
      expect(loaded.clusterEnabled, false);
      expect(loaded.clusterDurationSec, 2.0);
    });
  });
}
