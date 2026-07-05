import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// Repository quản lý local notification nhắc học streak mỗi ngày.
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

class NotificationRepository {
  static const int _streakReminderId = 2000;
  static const int streakReminderHour = 20;
  static const int streakReminderMinute = 0;
  static const String _channelId = 'streak_reminder';
  static const String _channelName = 'Streak reminder';
  static const String _channelDescription =
      'Nhắc học mỗi ngày để giữ streak HSK Dict.';

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized || kIsWeb) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(settings: initializationSettings);
    await _requestNotificationPermission();

    _isInitialized = true;
  }

  Future<void> scheduleDailyStreakReminder() async {
    if (kIsWeb) return;

    await init();

    final pendingRequests = await _notifications.pendingNotificationRequests();
    final alreadyScheduled = pendingRequests.any(
      (request) => request.id == _streakReminderId,
    );

    if (alreadyScheduled) {
      return;
    }

    await _notifications.zonedSchedule(
      id: _streakReminderId,
      title: 'HSK Dict nhắc nhẹ nè 🔥',
      body: 'Ê quay lại học tí đi, streak đang khóc thầm rồi đó 😭',
      scheduledDate: _nextReminderTime(),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelStreakReminder() async {
    if (kIsWeb) return;
    await init();
    await _notifications.cancel(id: _streakReminderId);
  }

  Future<void> _requestNotificationPermission() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _notifications
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  tz.TZDateTime _nextReminderTime() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      streakReminderHour,
      streakReminderMinute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}
