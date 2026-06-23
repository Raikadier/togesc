import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/analytics_provider.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/srs_provider.dart';
import '../services/app_preferences.dart';
import '../services/practice_reminder_service.dart';
import '../widgets/csat_survey_dialog.dart';

/// Encuesta CSAT ocasional y recordatorios de repaso (Fase 6).
class CsatSurveyListener extends ConsumerStatefulWidget {
  const CsatSurveyListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<CsatSurveyListener> createState() =>
      _CsatSurveyListenerState();
}

class _CsatSurveyListenerState extends ConsumerState<CsatSurveyListener> {
  bool _csatChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _afterStartup());
  }

  Future<void> _afterStartup() async {
    try {
      await _syncPracticeReminder();
    } catch (_) {
      // No bloquear arranque si falla el plugin de notificaciones en release.
    }
    if (!mounted || _csatChecked) return;
    _csatChecked = true;

    final prefs = AppPreferences(await SharedPreferences.getInstance());
    if (!prefs.shouldShowCsatSurvey()) return;
    if (!mounted) return;

    final result = await showCsatSurveyDialog(context);
    final now = DateTime.now();
    if (result == null) {
      await prefs.setCsatLastDismissed(now);
      return;
    }

    await prefs.setCsatLastSubmitted(now);
    await ref.read(analyticsServiceProvider).csatSubmitted(
          rating: result.rating,
          comment: result.comment.isEmpty ? null : result.comment,
        );
  }

  Future<void> _syncPracticeReminder() async {
    final prefs = await ref.read(appPreferencesProvider.future);
    if (!prefs.practiceRemindersEnabled) {
      await PracticeReminderService.instance.cancel();
      return;
    }

    final srs = ref.read(srsSystemProvider).valueOrNull;
    if (srs == null) return;

    final overdue = srs.getOverdueNotes().length;
    await PracticeReminderService.instance.syncOverdueReminder(
      enabled: prefs.practiceRemindersEnabled,
      overdueCount: overdue,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
