import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // ✅ สร้าง Notification Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'medicine_channel',
      'แจ้งเตือนการกินยา',
      description: 'ใช้สำหรับแจ้งเตือนยา',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ✅ ฟังก์ชันที่ใช้ตั้งเวลาแจ้งเตือน
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // ✅ ป้องกันเวลาที่ผ่านมา
    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

    print('[DEBUG] Scheduled for: $scheduledDate -> TZ: $tzScheduled');

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_channel',
          'แจ้งเตือนการกินยา',
          channelDescription: 'ใช้สำหรับแจ้งเตือนยา',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // แจ้งตามเวลาเดิมทุกวัน
    );
  }
//     tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
//     final now = tz.TZDateTime.now(tz.local);
//     final scheduled = tz.TZDateTime(
//       tz.local,
//       dateTime.year,
//       dateTime.month,
//       dateTime.day,
//       dateTime.hour,
//       dateTime.minute,
//     );
//     return scheduled.isBefore(now) ? scheduled.add(Duration(days: 1)) : scheduled;
//   }
//   Future<void> showNotification({
//   required int id,
//   required String title,
//   required String body,
// }) async {
//   await _notificationsPlugin.show(
//     id,
//     title,
//     body,
//     NotificationDetails(
//       android: AndroidNotificationDetails(
//         'med_channel_id',
//         'การแจ้งเตือนยา',
//         channelDescription: 'เตือนให้กินยา',
//         importance: Importance.max,
//         priority: Priority.high,
//         playSound: true,
//       ),
//     ),
//   );
// }

}


