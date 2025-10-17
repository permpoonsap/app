import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/medicine_item.dart';
import '../database/local_database.dart';
import '../notification/notification_service.dart';

class MedicineProvider extends ChangeNotifier {
  List<MedicineItem> _medicines = [];
  Map<String, List<MedicineItem>> _medicineHistory = {};
  String? _currentUserId;

  List<MedicineItem> get medicines => _medicines;
  Map<String, List<MedicineItem>> get medicineHistory => _medicineHistory;
  String? get currentUserId => _currentUserId;

  // Set current user ID
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
    LocalDatabase.setCurrentUserId(userId);
    // Clear current data when switching users
    _medicines.clear();
    _medicineHistory.clear();
    notifyListeners();
  }

  // Load medicines for current user
  Future<void> loadMedicines() async {
    if (_currentUserId == null) return;

    try {
      // Load all medicines for user from LocalDatabase
      final allMedicines =
          await LocalDatabase.getMedicinesForUser(_currentUserId!);

      // Filter medicines for today only for the main medicines list
      final today = DateTime.now();
      _medicines = allMedicines.where((medicine) {
        final medicineDate = medicine.scheduledDate;
        return medicineDate.year == today.year &&
            medicineDate.month == today.month &&
            medicineDate.day == today.day;
      }).toList();

      // Load medicine history (last 30 days)
      _medicineHistory.clear();
      for (int i = 0; i < 30; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateKey = _getDateKey(date);
        final historyMedicines = allMedicines.where((medicine) {
          final medicineDate = medicine.scheduledDate;
          return medicineDate.year == date.year &&
              medicineDate.month == date.month &&
              medicineDate.day == date.day;
        }).toList();

        if (historyMedicines.isNotEmpty) {
          _medicineHistory[dateKey] = historyMedicines;
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error loading medicines: $e');
      // Fallback to SharedPreferences if database fails
      await _loadFromSharedPreferences();
    }
  }

  // Fallback to SharedPreferences
  Future<void> _loadFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load current day medicines
    final medicinesJson =
        prefs.getString('medicines_${_currentUserId}_${_getTodayKey()}');
    if (medicinesJson != null) {
      final List<dynamic> medicinesList = json.decode(medicinesJson);
      _medicines =
          medicinesList.map((item) => MedicineItem.fromJson(item)).toList();
    } else {
      _medicines = [];
    }

    // Load medicine history (last 30 days)
    _medicineHistory.clear();
    for (int i = 0; i < 30; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey = _getDateKey(date);
      final historyJson =
          prefs.getString('medicines_${_currentUserId}_$dateKey');
      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        _medicineHistory[dateKey] =
            historyList.map((item) => MedicineItem.fromJson(item)).toList();
      }
    }

    notifyListeners();
  }

  // Add new medicine
  Future<void> addMedicine(MedicineItem medicine) async {
    if (_currentUserId == null) return;

    // Create new medicine with current user ID if not set
    MedicineItem medicineToAdd = medicine;
    if (medicine.userId.isEmpty) {
      medicineToAdd = medicine.copyWith(userId: _currentUserId!);
    }

    try {
      // Save to LocalDatabase
      final String newId = await LocalDatabase.addMedicine(medicineToAdd);

      // Update local state
      final MedicineItem persisted = medicineToAdd.copyWith(id: newId);
      _medicines.add(persisted);

      // สร้างการแจ้งเตือน
      await _scheduleMedicineNotification(persisted);

      await _saveMedicines();
      notifyListeners();
    } catch (e) {
      print('Error adding medicine to database: $e');
      // Fallback to SharedPreferences
      // Ensure an ID even in fallback so delete can work later
      final String fallbackId =
          DateTime.now().millisecondsSinceEpoch.toString();
      final MedicineItem withId = medicineToAdd.copyWith(id: fallbackId);
      _medicines.add(withId);

      // สร้างการแจ้งเตือนสำหรับ fallback
      await _scheduleMedicineNotification(withId);

      await _saveMedicines();
      notifyListeners();
    }
  }

  // Update medicine (toggle taken status)
  Future<void> updateMedicine(MedicineItem medicine) async {
    final index = _medicines.indexWhere((m) => m.id == medicine.id);
    if (index != -1) {
      _medicines[index] = medicine;

      try {
        // Update in LocalDatabase
        await LocalDatabase.updateMedicine(medicine);
      } catch (e) {
        print('Error updating medicine in database: $e');
      }

      await _saveMedicines();
      notifyListeners();
    }
  }

  // Edit medicine (update medicine details)
  Future<void> editMedicine(
      String medicineId, MedicineItem updatedMedicine) async {
    final index = _medicines.indexWhere((m) => m.id == medicineId);
    if (index != -1) {
      final oldMedicine = _medicines[index];

      // ลบการแจ้งเตือนเก่า
      await _cancelMedicineNotification(oldMedicine);

      // อัปเดตข้อมูล
      _medicines[index] = updatedMedicine;

      // สร้างการแจ้งเตือนใหม่
      await _scheduleMedicineNotification(updatedMedicine);

      try {
        // Update in LocalDatabase
        await LocalDatabase.updateMedicine(updatedMedicine);
      } catch (e) {
        print('Error updating medicine in database: $e');
      }

      await _saveMedicines();
      notifyListeners();
    }
  }

  // สร้างการแจ้งเตือนสำหรับยา
  Future<void> _scheduleMedicineNotification(MedicineItem medicine) async {
    try {
      final notificationId =
          medicine.name.hashCode ^ medicine.scheduledDate.hashCode;
      await NotificationService.scheduleNotification(
        id: notificationId,
        title: 'แจ้งเตือนยา',
        body:
            'ถึงเวลาที่ต้องทานยาแล้ว ${medicine.name} (${medicine.dose} เม็ด)',
        scheduledDate: medicine.scheduledDate,
      );
      print('Medicine notification scheduled: $notificationId');
    } catch (e) {
      print('Error scheduling medicine notification: $e');
    }
  }

  // Delete medicine
  Future<void> deleteMedicine(String medicineId) async {
    // หายาที่จะลบเพื่อใช้ในการลบการแจ้งเตือน
    final medicineToDelete = _medicines.firstWhere(
      (medicine) => medicine.id == medicineId,
      orElse: () => throw Exception('Medicine not found'),
    );

    // ลบการแจ้งเตือนก่อน
    await _cancelMedicineNotification(medicineToDelete);

    // ลบจากรายการ
    _medicines.removeWhere((medicine) => medicine.id == medicineId);

    try {
      // Delete from LocalDatabase
      await LocalDatabase.deleteMedicine(medicineId);
    } catch (e) {
      print('Error deleting medicine from database: $e');
    }

    await _saveMedicines();
    notifyListeners();
  }

  // ลบการแจ้งเตือนของยา
  Future<void> _cancelMedicineNotification(MedicineItem medicine) async {
    try {
      // สร้าง ID สำหรับการแจ้งเตือน (ใช้ชื่อยาและเวลานัด)
      final notificationId =
          medicine.name.hashCode ^ medicine.scheduledDate.hashCode;
      await NotificationService.cancelNotification(notificationId);
      print('Medicine notification cancelled: $notificationId');
    } catch (e) {
      print('Error cancelling medicine notification: $e');
    }
  }

  // Get medicines for specific date
  List<MedicineItem> getMedicinesForDate(DateTime date) {
    final dateKey = _getDateKey(date);
    if (dateKey == _getTodayKey()) {
      return _medicines;
    } else {
      return _medicineHistory[dateKey] ?? [];
    }
  }

  // Get medicine history for specific date range
  List<MedicineItem> getMedicineHistoryForDateRange(
      DateTime startDate, DateTime endDate) {
    List<MedicineItem> history = [];

    for (DateTime date = startDate;
        date.isBefore(endDate.add(Duration(days: 1)));
        date = date.add(Duration(days: 1))) {
      final dateKey = _getDateKey(date);
      if (dateKey == _getTodayKey()) {
        history.addAll(_medicines);
      } else {
        history.addAll(_medicineHistory[dateKey] ?? []);
      }
    }

    return history;
  }

  // Get statistics for date range
  Map<String, dynamic> getMedicineStatistics(
      DateTime startDate, DateTime endDate) {
    final medicines = getMedicineHistoryForDateRange(startDate, endDate);

    int totalMedicines = medicines.length;
    int takenMedicines = medicines.where((m) => m.isTaken).length;
    int missedMedicines = medicines
        .where((m) => !m.isTaken && m.scheduledDate.isBefore(DateTime.now()))
        .length;

    return {
      'total': totalMedicines,
      'taken': takenMedicines,
      'missed': missedMedicines,
      'compliance': totalMedicines > 0
          ? (takenMedicines / totalMedicines * 100).round()
          : 0,
    };
  }

  // Reset medicines for new day
  Future<void> resetMedicinesForNewDay() async {
    final today = DateTime.now();
    final yesterday = today.subtract(Duration(days: 1));
    final yesterdayKey = _getDateKey(yesterday);

    // Save yesterday's medicines to history
    if (_medicines.isNotEmpty) {
      _medicineHistory[yesterdayKey] = List.from(_medicines);
      await _saveMedicineHistory(yesterdayKey);
    }

    // Clean up old history (older than 30 days)
    await _cleanupOldHistory();

    // Reset current medicines (mark all as not taken)
    for (var medicine in _medicines) {
      medicine.isTaken = false;
      medicine.takenAt = null;
    }

    await _saveMedicines();
    notifyListeners();
  }

  // ลบประวัติการทานยาที่เก่ากว่า 30 วัน
  Future<void> _cleanupOldHistory() async {
    if (_currentUserId == null) return;

    final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
    final prefs = await SharedPreferences.getInstance();

    // ลบข้อมูลจาก SharedPreferences
    for (int i = 31; i <= 90; i++) {
      // ลบข้อมูล 31-90 วัน
      final oldDate = DateTime.now().subtract(Duration(days: i));
      final oldDateKey = _getDateKey(oldDate);
      await prefs.remove('medicines_${_currentUserId}_$oldDateKey');
    }

    // ลบข้อมูลจาก LocalDatabase
    try {
      await _deleteOldMedicineHistoryFromDatabase(thirtyDaysAgo);
    } catch (e) {
      print('Error cleaning up old medicine history from database: $e');
    }

    // ลบข้อมูลจาก memory
    final keysToRemove = <String>[];
    for (String dateKey in _medicineHistory.keys) {
      final date = _parseDateKey(dateKey);
      if (date != null && date.isBefore(thirtyDaysAgo)) {
        keysToRemove.add(dateKey);
      }
    }

    for (String key in keysToRemove) {
      _medicineHistory.remove(key);
    }

    print('Cleaned up medicine history older than 30 days');
  }

  // แปลง dateKey กลับเป็น DateTime
  DateTime? _parseDateKey(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('Error parsing date key: $dateKey');
    }
    return null;
  }

  // Save current medicines
  Future<void> _saveMedicines() async {
    if (_currentUserId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final medicinesJson =
        json.encode(_medicines.map((m) => m.toJson()).toList());
    await prefs.setString(
        'medicines_${_currentUserId}_${_getTodayKey()}', medicinesJson);
  }

  // Save medicine history for specific date
  Future<void> _saveMedicineHistory(String dateKey) async {
    if (_currentUserId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final historyJson = json.encode(
        _medicineHistory[dateKey]?.map((m) => m.toJson()).toList() ?? []);
    await prefs.setString('medicines_${_currentUserId}_$dateKey', historyJson);
  }

  // Get today's date key
  String _getTodayKey() {
    return _getDateKey(DateTime.now());
  }

  // Get date key for specific date
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Clear all data for current user
  Future<void> clearAllData() async {
    if (_currentUserId == null) return;

    try {
      // Clear from LocalDatabase
      await LocalDatabase.clearUserData(_currentUserId!);
    } catch (e) {
      print('Error clearing user data from database: $e');
    }

    // Clear from SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Clear current medicines
    await prefs.remove('medicines_${_currentUserId}_${_getTodayKey()}');
    _medicines.clear();

    // Clear history
    for (String dateKey in _medicineHistory.keys) {
      await prefs.remove('medicines_${_currentUserId}_$dateKey');
    }
    _medicineHistory.clear();

    notifyListeners();
  }

  // ลบประวัติการทานยาทั้งหมด (สำหรับการทดสอบหรือรีเซ็ต)
  Future<void> clearAllMedicineHistory() async {
    if (_currentUserId == null) return;

    final prefs = await SharedPreferences.getInstance();

    // ลบข้อมูลจาก SharedPreferences
    for (int i = 0; i <= 90; i++) {
      // ลบข้อมูล 0-90 วัน
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey = _getDateKey(date);
      await prefs.remove('medicines_${_currentUserId}_$dateKey');
    }

    // ลบข้อมูลจาก LocalDatabase
    try {
      await _deleteOldMedicineHistoryFromDatabase(DateTime(1900)); // ลบทั้งหมด
    } catch (e) {
      print('Error clearing all medicine history from database: $e');
    }

    // ลบข้อมูลจาก memory
    _medicineHistory.clear();
    _medicines.clear();

    notifyListeners();
    print('Cleared all medicine history');
  }

  // Get user data summary
  Future<Map<String, dynamic>> getUserDataSummary() async {
    if (_currentUserId == null) {
      return {
        'medicinesCount': 0,
        'appointmentsCount': 0,
        'lastActivity': null,
      };
    }

    try {
      return await LocalDatabase.getUserDataSummary(_currentUserId!);
    } catch (e) {
      print('Error getting user data summary: $e');
      return {
        'medicinesCount': _medicines.length,
        'appointmentsCount': 0,
        'lastActivity': null,
      };
    }
  }

  // ลบข้อมูลประวัติยาที่เก่ากว่าวันที่กำหนด
  Future<void> _deleteOldMedicineHistoryFromDatabase(
      DateTime cutoffDate) async {
    try {
      // ดึงข้อมูลยาทั้งหมดของ user
      final allMedicines =
          await LocalDatabase.getMedicinesForUser(_currentUserId!);

      // ลบยาที่มีวันที่เก่ากว่าวันที่กำหนด
      for (final medicine in allMedicines) {
        if (medicine.scheduledDate.isBefore(cutoffDate)) {
          await LocalDatabase.deleteMedicine(medicine.id!);
        }
      }
    } catch (e) {
      print('Error deleting old medicine history from database: $e');
    }
  }
}
