import 'instrument_preset.dart';

/// Modo de seleccion de timbre para la practica.
enum InstrumentMode { random, fixed }

/// Preferencias de audio persistidas (Fase 7A).
class AudioPreferences {
  final InstrumentMode instrumentMode;
  final String fixedInstrumentId;
  final double masterVolume;
  final bool clusterEnabled;
  final double clusterDurationSec;

  const AudioPreferences({
    this.instrumentMode = InstrumentMode.random,
    this.fixedInstrumentId = 'sine',
    this.masterVolume = 1.0,
    this.clusterEnabled = true,
    this.clusterDurationSec = 3.0,
  });

  static const sessionOverrideRandom = '__random__';

  /// Instrumento para [AudioGenerator.mixTones]: null = aleatorio.
  String? playbackInstrument({String? sessionOverrideKey}) {
    if (sessionOverrideKey == sessionOverrideRandom) return null;
    if (sessionOverrideKey != null &&
        instrumentPresets.containsKey(sessionOverrideKey)) {
      return sessionOverrideKey;
    }
    if (instrumentMode == InstrumentMode.random) return null;
    return instrumentPresets.containsKey(fixedInstrumentId)
        ? fixedInstrumentId
        : 'sine';
  }

  AudioPreferences copyWith({
    InstrumentMode? instrumentMode,
    String? fixedInstrumentId,
    double? masterVolume,
    bool? clusterEnabled,
    double? clusterDurationSec,
  }) {
    return AudioPreferences(
      instrumentMode: instrumentMode ?? this.instrumentMode,
      fixedInstrumentId: fixedInstrumentId ?? this.fixedInstrumentId,
      masterVolume: masterVolume ?? this.masterVolume,
      clusterEnabled: clusterEnabled ?? this.clusterEnabled,
      clusterDurationSec: clusterDurationSec ?? this.clusterDurationSec,
    );
  }
}

/// Etiquetas en espanol para la UI.
const Map<String, String> instrumentDisplayNames = {
  'sine': 'Seno',
  'piano': 'Piano',
  'violin': 'Violin',
  'guitar': 'Guitarra',
  'flute': 'Flauta',
  'trumpet': 'Trompeta',
  'organ': 'Organo',
};

String instrumentLabel(String id) =>
    instrumentDisplayNames[id] ?? id;
