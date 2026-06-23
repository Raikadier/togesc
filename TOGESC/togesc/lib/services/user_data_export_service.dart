import 'dart:convert';

import '../services/app_preferences.dart';
import '../services/progress_repository.dart';
import '../services/srs_system.dart';

/// Exportacion portable de datos locales (Fase 7E-1 / GDPR).
abstract final class UserDataExportService {
  static const exportVersion = '1.0';

  static Map<String, dynamic> buildPayload({
    required SRSSystem srs,
    required AppPreferences prefs,
    DateTime? exportedAt,
  }) {
    final at = (exportedAt ?? DateTime.now()).toUtc();
    final audio = prefs.audioPreferences;
    final ui = prefs.uiPreferences;
    final session = prefs.practiceSessionPreferences;
    final last = prefs.lastPracticeSession;

    return {
      'export_version': exportVersion,
      'exported_at': at.toIso8601String(),
      'app': 'togesc',
      'progress': encodeProgressPayload(
        srs.noteData,
        lastSession: last?.practicedAt.toIso8601String(),
      ),
      'preferences': {
        'onboarding_complete': prefs.onboardingComplete,
        'session_count': prefs.sessionCount,
        'note_naming': prefs.noteNamingMode.name,
        'practice_reminders_enabled': prefs.practiceRemindersEnabled,
        'audio': {
          'instrument_mode': audio.instrumentMode.name,
          'fixed_instrument_id': audio.fixedInstrumentId,
          'master_volume': audio.masterVolume,
          'cluster_enabled': audio.clusterEnabled,
          'cluster_duration_sec': audio.clusterDurationSec,
          'octave_variation_enabled': audio.octaveVariationEnabled,
          'tone_duration_sec': audio.toneDurationSec,
        },
        'ui': {
          'input_mode': ui.inputMode.name,
          'confirm_before_submit': ui.confirmBeforeSubmit,
          'hide_piano_labels': ui.hidePianoLabels,
          'large_piano': ui.largePiano,
          'reduce_animations': ui.reduceAnimations,
          'theme_preference': ui.themePreference.name,
        },
        'practice_session': {
          'round_goal_rounds': session.roundGoal.rounds,
          'auto_advance_after_result': session.autoAdvanceAfterResult,
        },
        'practice_note_pool': prefs.practiceNotePool,
        'srs_intensity': prefs.srsIntensityProfile.name,
        'total_xp': prefs.totalXp,
        'last_practice': last == null
            ? null
            : {
                'mode_id': last.modeId,
                'kind': last.kind.name,
                'practiced_at': last.practicedAt.toIso8601String(),
              },
      },
      'session_history':
          prefs.sessionHistory.map((entry) => entry.toJson()).toList(),
    };
  }

  static String buildJson({
    required SRSSystem srs,
    required AppPreferences prefs,
    DateTime? exportedAt,
  }) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(
      buildPayload(srs: srs, prefs: prefs, exportedAt: exportedAt),
    );
  }
}
