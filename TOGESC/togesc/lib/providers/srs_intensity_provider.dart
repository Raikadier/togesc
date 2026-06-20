import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/srs_intensity_profile.dart';
import 'app_preferences_provider.dart';
import 'srs_provider.dart';

final srsIntensityProfileProvider =
    AsyncNotifierProvider<SrsIntensityProfileNotifier, SrsIntensityProfile>(
  SrsIntensityProfileNotifier.new,
);

class SrsIntensityProfileNotifier extends AsyncNotifier<SrsIntensityProfile> {
  @override
  Future<SrsIntensityProfile> build() async {
    final prefs = await ref.watch(appPreferencesProvider.future);
    return prefs.srsIntensityProfile;
  }

  Future<void> setProfile(SrsIntensityProfile profile) async {
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setSrsIntensityProfile(profile);
    state = AsyncData(profile);

    final srs = ref.read(srsSystemProvider).valueOrNull;
    if (srs != null) {
      srs.intensityProfile = profile;
    }
  }
}
