import 'package:flutter/material.dart';

/// Utility class สำหรับจัดการ context อย่างปลอดภัย
class ContextUtils {
  /// ตรวจสอบว่า context ยัง mounted อยู่หรือไม่
  static bool isMounted(BuildContext context) {
    return context.mounted;
  }

  /// แสดง SnackBar อย่างปลอดภัย
  static void showSnackBar(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Duration? duration,
  }) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor ?? Colors.grey[600],
          duration: duration ?? Duration(seconds: 2),
        ),
      );
    }
  }

  /// แสดง SnackBar สำหรับ error
  static void showErrorSnackBar(BuildContext context, String error) {
    showSnackBar(
      context,
      message: error,
      backgroundColor: Colors.red[600],
      duration: Duration(seconds: 3),
    );
  }

  /// แสดง SnackBar สำหรับ success
  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.green[600],
      duration: Duration(seconds: 2),
    );
  }

  /// แสดง SnackBar สำหรับ warning
  static void showWarningSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.orange[600],
      duration: Duration(seconds: 2),
    );
  }

  /// Navigate อย่างปลอดภัย
  static void navigateTo(BuildContext context, Widget page) {
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    }
  }

  /// Pop อย่างปลอดภัย
  static void pop(BuildContext context, [dynamic result]) {
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context, result);
    }
  }

  /// ตรวจสอบและทำงานกับ context อย่างปลอดภัย
  static void safeContextCallback(BuildContext context, VoidCallback callback) {
    if (context.mounted) {
      callback();
    }
  }

  /// ทำงานกับ context หลังจาก delay อย่างปลอดภัย
  static void delayedContextCallback(
    BuildContext context,
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 100),
  }) {
    Future.delayed(delay, () {
      if (context.mounted) {
        callback();
      }
    });
  }
}
