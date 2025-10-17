import 'package:flutter/material.dart';
import '../model/appointment_item.dart';
import '../notification/notification_service.dart';
import '../database/local_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentProvider with ChangeNotifier {
  final List<AppointmentItem> _appointments = [];
  String? _currentUserId;

  List<AppointmentItem> get appointments => _appointments;

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
    LocalDatabase.setCurrentUserId(userId);
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    final uid = _currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final maps = await LocalDatabase.getAppointmentsForUser(uid);
      _appointments
        ..clear()
        ..addAll(maps.map((m) {
          final timeParts = (m['time'] as String).split(':');
          final date = DateTime.parse(m['date']);
          final dt = DateTime(date.year, date.month, date.day,
              int.parse(timeParts[0]), int.parse(timeParts[1]));
          return AppointmentItem(
            id: m['id'],
            doctorName: m['title'] ?? '',
            reason: m['description'] ?? '',
            dateTime: dt,
            alertBefore: Duration(minutes: 30),
          );
        }));
      notifyListeners();
    } catch (e) {
      // Ignore silently for now
    }
  }

  void addAppointment(AppointmentItem item) {
    // สร้าง ID ถ้าไม่มี
    final itemWithId = item.id == null
        ? item.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString())
        : item;

    _appointments.add(itemWithId);
    _scheduleAppointmentNotifications(itemWithId);
    notifyListeners();
    _persistAppointment(itemWithId);
  }

  void _scheduleAppointmentNotifications(AppointmentItem item) {
    final DateTime appointmentDateTime = item.dateTime;

    // แจ้งเตือนล่วงหน้า 1 วัน (ถ้าเวลายังไม่ผ่าน)
    final DateTime oneDayBefore =
        appointmentDateTime.subtract(Duration(days: 1));
    if (oneDayBefore.isAfter(DateTime.now())) {
      final int id1 = appointmentDateTime.millisecondsSinceEpoch % 1000000000;
      NotificationService.scheduleNotification(
        id: id1,
        title: 'นัดพบแพทย์พรุ่งนี้',
        body:
            'เตือนความจำ: พรุ่งนี้มีนัดเวลา ${_formatTime(appointmentDateTime)}',
        scheduledDate: oneDayBefore,
      );
    }

    // แจ้งเตือนล่วงหน้าตามการตั้งค่า (เช่น 30 นาที)
    final DateTime customBefore =
        appointmentDateTime.subtract(item.alertBefore);
    if (customBefore.isAfter(DateTime.now())) {
      final int id2 =
          (appointmentDateTime.millisecondsSinceEpoch + 7) % 1000000000;
      NotificationService.scheduleNotification(
        id: id2,
        title: 'ใกล้ถึงเวลานัดพบแพทย์',
        body:
            'อีก ${_formatDuration(item.alertBefore)} จะถึงเวลานัด ${_formatDateTime(appointmentDateTime)}',
        scheduledDate: customBefore,
      );
    }
  }

  String _formatTime(DateTime dt) {
    final String hh = dt.hour.toString().padLeft(2, '0');
    final String mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formatDateTime(DateTime dt) {
    final String yyyy = dt.year.toString();
    final String mm = dt.month.toString().padLeft(2, '0');
    final String dd = dt.day.toString().padLeft(2, '0');
    final String hh = dt.hour.toString().padLeft(2, '0');
    final String mi = dt.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$mi';
  }

  String _formatDuration(Duration d) {
    if (d.inDays >= 1) return '${d.inDays} วัน';
    if (d.inHours >= 1) return '${d.inHours} ชั่วโมง';
    if (d.inMinutes >= 1) return '${d.inMinutes} นาที';
    return '${d.inSeconds} วินาที';
  }

  Future<void> _persistAppointment(AppointmentItem item) async {
    final uid = _currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final id = await LocalDatabase.addAppointmentForUser(
        userId: uid,
        title: item.doctorName,
        description: item.reason,
        dateTime: item.dateTime,
      );

      // อัปเดต ID ในรายการถ้ายังไม่มี
      if (item.id == null) {
        final index = _appointments.indexWhere((app) =>
            app.doctorName == item.doctorName &&
            app.reason == item.reason &&
            app.dateTime == item.dateTime);
        if (index != -1) {
          _appointments[index] = item.copyWith(id: id);
        }
      }
    } catch (_) {}
  }

  // แก้ไขข้อมูลนัดพบแพทย์
  Future<void> updateAppointment(int index, AppointmentItem updatedItem) async {
    if (index < 0 || index >= _appointments.length) return;

    final oldItem = _appointments[index];

    // ลบการแจ้งเตือนเก่า
    await _cancelAppointmentNotifications(oldItem);

    // อัปเดตข้อมูล
    _appointments[index] = updatedItem;

    // สร้างการแจ้งเตือนใหม่
    _scheduleAppointmentNotifications(updatedItem);

    notifyListeners();

    // บันทึกลงฐานข้อมูล
    await _updateAppointmentInDatabase(updatedItem, index);
  }

  // ลบข้อมูลนัดพบแพทย์
  Future<void> deleteAppointment(int index) async {
    if (index < 0 || index >= _appointments.length) return;

    final item = _appointments[index];

    // ลบการแจ้งเตือน
    await _cancelAppointmentNotifications(item);

    // ลบจากฐานข้อมูลก่อน
    await _deleteAppointmentFromDatabase(item);

    // ลบจากรายการ
    _appointments.removeAt(index);

    notifyListeners();
  }

  // ลบการแจ้งเตือนของนัดพบแพทย์
  Future<void> _cancelAppointmentNotifications(AppointmentItem item) async {
    final DateTime appointmentDateTime = item.dateTime;

    // ลบการแจ้งเตือนล่วงหน้า 1 วัน
    final int id1 = appointmentDateTime.millisecondsSinceEpoch % 1000000000;
    await NotificationService.cancelNotification(id1);

    // ลบการแจ้งเตือนล่วงหน้าตามการตั้งค่า
    final int id2 =
        (appointmentDateTime.millisecondsSinceEpoch + 7) % 1000000000;
    await NotificationService.cancelNotification(id2);
  }

  // อัปเดตข้อมูลในฐานข้อมูล
  Future<void> _updateAppointmentInDatabase(
      AppointmentItem item, int index) async {
    final uid = _currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // ลบข้อมูลเก่าและเพิ่มข้อมูลใหม่
      if (item.id != null) {
        await LocalDatabase.deleteAppointment(item.id!);
      }
      await _persistAppointment(item);
    } catch (e) {
      print('Error updating appointment in database: $e');
    }
  }

  // ลบข้อมูลจากฐานข้อมูล
  Future<void> _deleteAppointmentFromDatabase(AppointmentItem item) async {
    final uid = _currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      if (item.id != null) {
        await LocalDatabase.deleteAppointment(item.id!);
      }
    } catch (e) {
      print('Error deleting appointment from database: $e');
    }
  }
}
