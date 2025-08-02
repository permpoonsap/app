import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/medicine_item.dart';

class MedicineProvider extends ChangeNotifier {
  List<MedicineItem> _medicines = [];
  Map<String, List<MedicineItem>> _medicineHistory = {};

  List<MedicineItem> get medicines => _medicines;
  Map<String, List<MedicineItem>> get medicineHistory => _medicineHistory;

  // Load medicines from SharedPreferences
  Future<void> loadMedicines() async {
    final prefs = await SharedPreferences.getInstance();

    // Load current day medicines
    final medicinesJson = prefs.getString('medicines_${_getTodayKey()}');
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
      final historyJson = prefs.getString('medicines_$dateKey');
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
    _medicines.add(medicine);
    await _saveMedicines();
    notifyListeners();
  }

  // Update medicine (toggle taken status)
  Future<void> updateMedicine(MedicineItem medicine) async {
    final index = _medicines.indexWhere((m) => m.id == medicine.id);
    if (index != -1) {
      _medicines[index] = medicine;
      await _saveMedicines();
      notifyListeners();
    }
  }

  // Delete medicine
  Future<void> deleteMedicine(String medicineId) async {
    _medicines.removeWhere((medicine) => medicine.id == medicineId);
    await _saveMedicines();
    notifyListeners();
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

    // Reset current medicines (mark all as not taken)
    for (var medicine in _medicines) {
      medicine.isTaken = false;
      medicine.takenAt = null;
    }

    await _saveMedicines();
    notifyListeners();
  }

  // Save current medicines
  Future<void> _saveMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final medicinesJson =
        json.encode(_medicines.map((m) => m.toJson()).toList());
    await prefs.setString('medicines_${_getTodayKey()}', medicinesJson);
  }

  // Save medicine history for specific date
  Future<void> _saveMedicineHistory(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = json.encode(
        _medicineHistory[dateKey]?.map((m) => m.toJson()).toList() ?? []);
    await prefs.setString('medicines_$dateKey', historyJson);
  }

  // Get today's date key
  String _getTodayKey() {
    return _getDateKey(DateTime.now());
  }

  // Get date key for specific date
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Clear all data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear current medicines
    await prefs.remove('medicines_${_getTodayKey()}');
    _medicines.clear();

    // Clear history
    for (String dateKey in _medicineHistory.keys) {
      await prefs.remove('medicines_$dateKey');
    }
    _medicineHistory.clear();

    notifyListeners();
  }
}
