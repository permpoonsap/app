import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('alarm_permission');

/// ตรวจสอบว่าได้รับสิทธิ์ Exact Alarm หรือยัง
Future<bool> checkExactAlarmPermission() async {
  try {
    final bool granted = await _channel.invokeMethod('checkExactAlarmPermission');
    return granted;
  } catch (e) {
    print('Error checking permission: $e');
    return false;
  }
}

/// ขอสิทธิ์เฉพาะเมื่อยังไม่ได้รับ
Future<void> requestExactAlarmIfNeeded() async {
  final granted = await checkExactAlarmPermission();
  if (!granted) {
    try {
      await _channel.invokeMethod('requestExactAlarmPermission');
    } catch (e) {
      print('Error requesting permission: $e');
    }
  }
}
