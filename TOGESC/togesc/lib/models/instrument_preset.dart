/// Preset de instrumento para sintesis aditiva.
class InstrumentPreset {
  final String name;
  final List<(int harmonic, double amplitude)> harmonics;
  final double attack;
  final double decay;
  final double sustainLevel;
  final double release;

  const InstrumentPreset({
    required this.name,
    required this.harmonics,
    required this.attack,
    required this.decay,
    required this.sustainLevel,
    required this.release,
  });
}

/// Presets de instrumentos disponibles.
const _sineHarmonics = [(1, 1.0)];
const _pianoHarmonics = [(1, 1.0), (2, 0.5), (3, 0.25), (4, 0.125), (5, 0.06)];
const _violinHarmonics = [(1, 1.0), (2, 0.8), (3, 0.6), (4, 0.4), (5, 0.3), (6, 0.2)];
const _guitarHarmonics = [(1, 1.0), (2, 0.6), (3, 0.3), (4, 0.2), (5, 0.1)];
const _fluteHarmonics = [(1, 1.0), (2, 0.3), (3, 0.1), (4, 0.05)];
const _trumpetHarmonics = [(1, 1.0), (2, 0.9), (3, 0.8), (4, 0.7), (5, 0.6)];
const _organHarmonics = [(1, 1.0), (2, 0.8), (3, 0.6), (4, 0.5), (5, 0.4), (6, 0.3)];

final Map<String, InstrumentPreset> instrumentPresets = {
  'sine': InstrumentPreset(
    name: 'sine',
    harmonics: _sineHarmonics,
    attack: 0.01, decay: 0.1, sustainLevel: 0.8, release: 0.1,
  ),
  'piano': InstrumentPreset(
    name: 'piano',
    harmonics: _pianoHarmonics,
    attack: 0.001, decay: 0.3, sustainLevel: 0.4, release: 0.5,
  ),
  'violin': InstrumentPreset(
    name: 'violin',
    harmonics: _violinHarmonics,
    attack: 0.1, decay: 0.2, sustainLevel: 0.9, release: 0.3,
  ),
  'guitar': InstrumentPreset(
    name: 'guitar',
    harmonics: _guitarHarmonics,
    attack: 0.005, decay: 0.2, sustainLevel: 0.5, release: 0.4,
  ),
  'flute': InstrumentPreset(
    name: 'flute',
    harmonics: _fluteHarmonics,
    attack: 0.05, decay: 0.1, sustainLevel: 0.85, release: 0.2,
  ),
  'trumpet': InstrumentPreset(
    name: 'trumpet',
    harmonics: _trumpetHarmonics,
    attack: 0.01, decay: 0.1, sustainLevel: 0.9, release: 0.15,
  ),
  'organ': InstrumentPreset(
    name: 'organ',
    harmonics: _organHarmonics,
    attack: 0.05, decay: 0.1, sustainLevel: 1.0, release: 0.1,
  ),
};
