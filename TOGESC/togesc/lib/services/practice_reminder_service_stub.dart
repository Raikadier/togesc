/// Recordatorios locales no disponibles en web/escritorio.
class PracticeReminderService {
  PracticeReminderService._();

  static final PracticeReminderService instance = PracticeReminderService._();

  static bool get isSupported => false;

  Future<void> requestPermission() async {}

  Future<void> syncOverdueReminder({
    required bool enabled,
    required int overdueCount,
  }) async {}

  Future<void> cancel() async {}
}
