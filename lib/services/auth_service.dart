import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/medicine_provider.dart';

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
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
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
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Logout
  static Future<void> signOut(BuildContext context) async {
    try {
      // Clear medicine data before logout
      if (context.mounted) {
        try {
          final medicineProvider =
              Provider.of<MedicineProvider>(context, listen: false);
          medicineProvider.clearAllData();
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

  // ตั้งค่า User ID ให้กับ MedicineProvider
  static void setCurrentUserForMedicineProvider(BuildContext context) {
    try {
      User? user = _auth.currentUser;
      if (user != null && context.mounted) {
        try {
          final medicineProvider =
              Provider.of<MedicineProvider>(context, listen: false);
          // No need to set user for local storage
        } catch (e) {
          // Provider might not be available, ignore this error
          print('Provider not available when setting user: $e');
        }
      }
    } catch (e) {
      print('Error setting current user for medicine provider: $e');
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
