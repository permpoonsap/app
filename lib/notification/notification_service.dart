// lib/notification/notification_service.dart
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'medication_channel',
          channelName: 'Medication Reminders',
          channelDescription: 'Reminders to take your medication',
          defaultColor: Colors.teal,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
      ],
      debug: true,
    );
  }

  static Future<void> requestPermissions() async {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'medication_channel',
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar.fromDate(
          date: scheduledDate,
          preciseAlarm: true,
        ),
      );
      print('Notification scheduled: $id');
    } catch (e) {
      print('เกิดข้อผิดพลาดขณะตั้งเวลาแจ้งเตือน: $e');
    }
  }

  // ยกเลิกการแจ้งเตือน
  static Future<void> cancelNotification(int id) async {
    try {
      await AwesomeNotifications().cancel(id);
      print('Notification cancelled: $id');
    } catch (e) {
      print('เกิดข้อผิดพลาดขณะยกเลิกการแจ้งเตือน: $e');
    }
  }

  // ยกเลิกการแจ้งเตือนทั้งหมด
  static Future<void> cancelAllNotifications() async {
    try {
      await AwesomeNotifications().cancelAll();
      print('All notifications cancelled');
    } catch (e) {
      print('เกิดข้อผิดพลาดขณะยกเลิกการแจ้งเตือนทั้งหมด: $e');
    }
  }
}
