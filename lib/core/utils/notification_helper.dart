import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android, iOS: DarwinInitializationSettings());
    await _plugin.initialize(settings);
  }

  static Future<void> showPriceAlert(String title, String body) async {
    if (kIsWeb) {
      return;
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails('price_alerts', 'Harga Komponen'),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(101, title, body, details);
  }

  static Future<void> showAchievement(String body) async {
    if (kIsWeb) {
      return;
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails('achievement', 'Achievement'),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(401, 'Pencapaian Baru', body, details);
  }

  static Future<void> scheduleDailyReminder() async {
    if (kIsWeb) {
      return;
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails('daily_build', 'Pengingat Build'),
      iOS: DarwinNotificationDetails(),
    );
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      201,
      'Build belum selesai',
      'Yuk lanjutkan rakit PC impianmu.',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleSessionReminder(DateTime expiry) async {
    if (kIsWeb) {
      return;
    }
    final remindAt = expiry.subtract(const Duration(hours: 1));
    const details = NotificationDetails(
      android: AndroidNotificationDetails('session_reminder', 'Sesi Login'),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.zonedSchedule(
      301,
      'Sesi akan berakhir',
      'Sesi login kamu akan kadaluarsa 1 jam lagi.',
      tz.TZDateTime.from(remindAt, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> showBuildSaved(String buildName) async {
    if (kIsWeb) {
      return;
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'build_saved',
        'Build Disimpan',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      501,
      'Build Berhasil Disimpan',
      'Build "$buildName" telah tersimpan di koleksi Anda.',
      details,
    );
  }
}
