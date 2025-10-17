import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/medicine_provider.dart';
import '../provider/daily_goal_provider.dart';
import '../provider/health_profile_provider.dart';
import '../provider/appointment_provider.dart';
import '../provider/exercise_log_provider.dart';
import '../provider/brain_game_provider.dart';
import '../database/local_database.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ตรวจสอบสถานะการ login ปัจจุบัน
  static User? get currentUser => _auth.currentUser;

  // Stream สำหรับติดตามการเปลี่ยนแปลงสถานะการ login
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login ด้วย Email และ Password
  static Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set current user ID in LocalDatabase
      if (userCredential.user != null) {
        LocalDatabase.setCurrentUserId(userCredential.user!.uid);
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // สมัครสมาชิกใหม่
  static Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set current user ID in LocalDatabase
      if (userCredential.user != null) {
        LocalDatabase.setCurrentUserId(userCredential.user!.uid);
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Logout
  static Future<void> signOut(BuildContext context) async {
    try {
      // Clear current user ID
      LocalDatabase.setCurrentUserId('');

      // Clear provider data before logout
      if (context.mounted) {
        try {
          // Clear MedicineProvider
          final medicineProvider =
              Provider.of<MedicineProvider>(context, listen: false);
          medicineProvider.setCurrentUserId(''); // Clear current user

          // Clear DailyGoalProvider
          final dailyGoalProvider =
              Provider.of<DailyGoalProvider>(context, listen: false);
          dailyGoalProvider.setCurrentUserId(''); // Clear current user

          // Clear HealthProfileProvider
          final healthProfileProvider =
              Provider.of<HealthProfileProvider>(context, listen: false);
          healthProfileProvider.setCurrentUserId(''); // Clear current user

          // Clear AppointmentProvider
          final appointmentProvider =
              Provider.of<AppointmentProvider>(context, listen: false);
          appointmentProvider.setCurrentUserId('');
        } catch (e) {
          // Provider might not be available, ignore this error
          print('Provider not available during logout: $e');
        }
      }

      // Sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // เปลี่ยนรหัสผ่าน
  static Future<void> changePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw Exception('ไม่พบผู้ใช้ที่ login อยู่');
      }
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ส่งอีเมลรีเซ็ตรหัสผ่าน
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ตรวจสอบว่า login อยู่หรือไม่
  static bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  // ดึง User ID ของผู้ใช้ปัจจุบัน
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // ดึงอีเมลของผู้ใช้ปัจจุบัน
  static String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  // ตั้งค่า User ID ให้กับ Providers ทั้งหมด
  static Future<void> setCurrentUserForProviders(BuildContext context) async {
    try {
      User? user = _auth.currentUser;
      if (user != null && context.mounted) {
        try {
          // Set user ID for MedicineProvider
          final medicineProvider =
              Provider.of<MedicineProvider>(context, listen: false);
          medicineProvider.setCurrentUserId(user.uid);

          // Set user ID for DailyGoalProvider
          final dailyGoalProvider =
              Provider.of<DailyGoalProvider>(context, listen: false);
          dailyGoalProvider.setCurrentUserId(user.uid);

          // Set user ID for HealthProfileProvider
          final healthProfileProvider =
              Provider.of<HealthProfileProvider>(context, listen: false);
          healthProfileProvider.setCurrentUserId(user.uid);

          // Set user ID for AppointmentProvider
          final appointmentProvider =
              Provider.of<AppointmentProvider>(context, listen: false);
          appointmentProvider.setCurrentUserId(user.uid);

          // Set user ID for ExerciseLogProvider
          final exerciseProvider =
              Provider.of<ExerciseLogProvider>(context, listen: false);
          exerciseProvider.setCurrentUserId(user.uid);

          // Set user ID for BrainGameProvider
          final brainGameProvider =
              Provider.of<BrainGameProvider>(context, listen: false);
          brainGameProvider.setCurrentUserId(user.uid);

          // โหลดข้อมูลสำหรับ provider ใหม่
          await medicineProvider.loadMedicines();
          await exerciseProvider.loadLogs();
          await brainGameProvider.loadGameLogs();
        } catch (e) {
          // Provider might not be available, ignore this error
          print('Provider not available when setting user: $e');
        }
      }
    } catch (e) {
      print('Error setting current user for providers: $e');
    }
  }

  // จัดการ Error จาก Firebase Auth
  static String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'ไม่พบผู้ใช้นี้';
        case 'wrong-password':
          return 'รหัสผ่านไม่ถูกต้อง';
        case 'email-already-in-use':
          return 'อีเมลนี้ถูกใช้งานแล้ว';
        case 'weak-password':
          return 'รหัสผ่านอ่อนเกินไป';
        case 'invalid-email':
          return 'อีเมลไม่ถูกต้อง';
        case 'user-disabled':
          return 'บัญชีผู้ใช้ถูกปิดใช้งาน';
        case 'too-many-requests':
          return 'มีการพยายามเข้าสู่ระบบมากเกินไป กรุณาลองใหม่ภายหลัง';
        case 'operation-not-allowed':
          return 'การดำเนินการนี้ไม่ได้รับอนุญาต';
        case 'network-request-failed':
          return 'เกิดข้อผิดพลาดในการเชื่อมต่อเครือข่าย';
        default:
          return 'เกิดข้อผิดพลาด: ${error.message}';
      }
    }
    return 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';
  }

  // ตรวจสอบความแข็งแกร่งของรหัสผ่าน
  static String validatePassword(String password) {
    if (password.length < 6) {
      return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'รหัสผ่านต้องมีตัวพิมพ์ใหญ่อย่างน้อย 1 ตัว';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'รหัสผ่านต้องมีตัวเลขอย่างน้อย 1 ตัว';
    }
    return 'valid';
  }

  // ตรวจสอบความถูกต้องของอีเมล
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // ตรวจสอบสถานะการเชื่อมต่อ
  static Future<bool> checkConnection() async {
    try {
      await _auth.currentUser?.reload();
      return true;
    } catch (e) {
      return false;
    }
  }
}
