import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExerciseLogProvider extends ChangeNotifier {
  // Map<date, List<exerciseName>>
  Map<String, List<String>> _logs = {};

  Map<String, List<String>> get logs => _logs;

  Future<void> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('exercise_logs');
    if (jsonString != null) {
      final Map<String, dynamic> decoded = json.decode(jsonString);
      _logs =
          decoded.map((key, value) => MapEntry(key, List<String>.from(value)));

      // ลบข้อมูลเก่าที่เกิน 30 วัน
      await _cleanOldData();

      notifyListeners();
    }
  }

  // ลบข้อมูลเก่าที่เกิน 30 วัน
  Future<void> _cleanOldData() async {
    final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
    final keysToRemove = <String>[];

    _logs.forEach((dateKey, exercises) {
      try {
        final date = DateTime.parse(dateKey);
        if (date.isBefore(thirtyDaysAgo)) {
          keysToRemove.add(dateKey);
        }
      } catch (e) {
        // ถ้า parse วันที่ไม่ได้ ให้ลบออก
        keysToRemove.add(dateKey);
      }
    });

    for (String key in keysToRemove) {
      _logs.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      await _saveLogs();
    }
  }

  Future<void> addLog(String exerciseName) async {
    final today = DateTime.now();
    final dateKey =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    if (!_logs.containsKey(dateKey)) {
      _logs[dateKey] = [];
    }
    if (!_logs[dateKey]!.contains(exerciseName)) {
      _logs[dateKey]!.add(exerciseName);
      await _saveLogs();
      notifyListeners();
    }
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(_logs);
    await prefs.setString('exercise_logs', jsonString);
  }

  List<String> getLogsForDate(DateTime date) {
    final dateKey =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return _logs[dateKey] ?? [];
  }
}
