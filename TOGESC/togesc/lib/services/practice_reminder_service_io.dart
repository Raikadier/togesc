import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Recordatorios locales en Android/iOS cuando hay notas vencidas.
class PracticeReminderService {
  PracticeReminderService._();

  static final PracticeReminderService instance = PracticeReminderService._();

  static bool get isSupported =>
      Platform.isAndroid || Platform.isIOS;

  static const _channelId = 'togesc_practice';
  static const _notificationId = 9001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<void> requestPermission() async {
    if (!isSupported) return;
    await _ensureInitialized();
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    }
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> syncOverdueReminder({
    required bool enabled,
    required int overdueCount,
  }) async {
    if (!isSupported) return;
    await _ensureInitialized();

    if (!enabled || overdueCount <= 0) {
      await cancel();
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'Repaso TOGESC',
      channelDescription: 'Recordatorios cuando tienes notas vencidas',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.periodicallyShow(
      _notificationId,
      'Tienes notas para repasar',
      'Hay $overdueCount nota${overdueCount == 1 ? '' : 's'} vencida${overdueCount == 1 ? '' : 's'}. '
          'Abre TOGESC para practicar.',
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancel() async {
    if (!isSupported) return;
    await _ensureInitialized();
    await _plugin.cancel(_notificationId);
  }
}
