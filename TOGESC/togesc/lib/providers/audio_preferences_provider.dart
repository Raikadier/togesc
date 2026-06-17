import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/audio_preferences.dart';
import 'app_preferences_provider.dart';

final audioPreferencesProvider =
    AsyncNotifierProvider<AudioPreferencesNotifier, AudioPreferences>(
  AudioPreferencesNotifier.new,
);

class AudioPreferencesNotifier extends AsyncNotifier<AudioPreferences> {
  @override
  Future<AudioPreferences> build() async {
    final prefs = await ref.watch(appPreferencesProvider.future);
    return prefs.audioPreferences;
  }

  Future<void> save(AudioPreferences value) async {
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setAudioPreferences(value);
    state = AsyncData(value);
  }

  Future<void> setInstrumentMode(InstrumentMode mode) async {
    final current = state.valueOrNull ?? const AudioPreferences();
    await save(current.copyWith(instrumentMode: mode));
  }

  Future<void> setFixedInstrument(String id) async {
    final current = state.valueOrNull ?? const AudioPreferences();
    await save(current.copyWith(fixedInstrumentId: id));
  }

  Future<void> setMasterVolume(double volume) async {
    final current = state.valueOrNull ?? const AudioPreferences();
    await save(current.copyWith(masterVolume: volume.clamp(0.0, 1.0)));
  }

  Future<void> setClusterEnabled(bool enabled) async {
    final current = state.valueOrNull ?? const AudioPreferences();
    await save(current.copyWith(clusterEnabled: enabled));
  }

  Future<void> setClusterDuration(double seconds) async {
    final current = state.valueOrNull ?? const AudioPreferences();
    await save(current.copyWith(clusterDurationSec: seconds));
  }
}
