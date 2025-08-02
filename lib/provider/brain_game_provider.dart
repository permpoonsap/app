import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BrainGameProvider extends ChangeNotifier {
  // Map<date, List<gameResult>>
  Map<String, List<GameResult>> _gameLogs = {};

  Map<String, List<GameResult>> get gameLogs => _gameLogs;

  Future<void> loadGameLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('brain_game_logs');
    if (jsonString != null) {
      final Map<String, dynamic> decoded = json.decode(jsonString);
      _gameLogs = decoded.map((key, value) => MapEntry(
          key, (value as List).map((e) => GameResult.fromJson(e)).toList()));

      // ลบข้อมูลเก่าที่เกิน 30 วัน
      await _cleanOldData();

      notifyListeners();
    }
  }

  // ลบข้อมูลเก่าที่เกิน 30 วัน
  Future<void> _cleanOldData() async {
    final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
    final keysToRemove = <String>[];

    _gameLogs.forEach((dateKey, logs) {
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
      _gameLogs.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      await _saveGameLogs();
    }
  }

  Future<void> addGameResult(
      String gameType, int score, int totalQuestions) async {
    final today = DateTime.now();
    final dateKey =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    if (!_gameLogs.containsKey(dateKey)) {
      _gameLogs[dateKey] = [];
    }

    final gameResult = GameResult(
      gameType: gameType,
      score: score,
      totalQuestions: totalQuestions,
      timestamp: DateTime.now(),
    );

    _gameLogs[dateKey]!.add(gameResult);
    await _saveGameLogs();
    notifyListeners();
  }

  Future<void> _saveGameLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, List<Map<String, dynamic>>> dataToSave = {};

    _gameLogs.forEach((key, value) {
      dataToSave[key] = value.map((e) => e.toJson()).toList();
    });

    final jsonString = json.encode(dataToSave);
    await prefs.setString('brain_game_logs', jsonString);
  }

  List<GameResult> getGameLogsForDate(DateTime date) {
    final dateKey =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return _gameLogs[dateKey] ?? [];
  }

  int getTotalScoreForDate(DateTime date) {
    final logs = getGameLogsForDate(date);
    return logs.fold(0, (sum, log) => sum + log.score);
  }

  int getTotalGamesForDate(DateTime date) {
    final logs = getGameLogsForDate(date);
    return logs.length;
  }
}

class GameResult {
  final String gameType;
  final int score;
  final int totalQuestions;
  final DateTime timestamp;

  GameResult({
    required this.gameType,
    required this.score,
    required this.totalQuestions,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'gameType': gameType,
      'score': score,
      'totalQuestions': totalQuestions,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GameResult.fromJson(Map<String, dynamic> json) {
    return GameResult(
      gameType: json['gameType'],
      score: json['score'],
      totalQuestions: json['totalQuestions'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
