import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/daily_goal.dart';
import '../database/local_database.dart';

class DailyGoalProvider extends ChangeNotifier {
  List<DailyGoal> _dailyGoals = [];
  Map<String, List<DailyGoal>> _goalHistory = {};
  String? _currentUserId;

  List<DailyGoal> get dailyGoals => _dailyGoals;
  Map<String, List<DailyGoal>> get goalHistory => _goalHistory;
  String? get currentUserId => _currentUserId;

  // Set current user ID
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
    LocalDatabase.setCurrentUserId(userId);
    // Clear current data when switching users
    _dailyGoals.clear();
    _goalHistory.clear();
    notifyListeners();
  }

  // Load daily goals for current user
  Future<void> loadDailyGoals() async {
    if (_currentUserId == null) return;

    try {
      // Load from LocalDatabase first
      _dailyGoals = await LocalDatabase.getDailyGoalsForUserAndDate(
        _currentUserId!,
        DateTime.now(),
      );

      // Load goal history (last 30 days)
      _goalHistory.clear();
      for (int i = 0; i < 30; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateKey = _getDateKey(date);
        final historyGoals = await LocalDatabase.getDailyGoalsForUserAndDate(
          _currentUserId!,
          date,
        );
        if (historyGoals.isNotEmpty) {
          _goalHistory[dateKey] = historyGoals;
        }
      }

      // Auto-update goal statuses
      await _autoUpdateGoalStatuses();

      notifyListeners();
    } catch (e) {
      print('Error loading daily goals: $e');
      // Fallback to SharedPreferences if database fails
      await _loadFromSharedPreferences();
    }
  }

  // Fallback to SharedPreferences
  Future<void> _loadFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load current day goals
    final goalsJson =
        prefs.getString('daily_goals_${_currentUserId}_${_getTodayKey()}');
    if (goalsJson != null) {
      final List<dynamic> goalsList = json.decode(goalsJson);
      _dailyGoals = goalsList.map((item) => DailyGoal.fromJson(item)).toList();
    } else {
      _dailyGoals = [];
    }

    // Load goal history (last 30 days)
    _goalHistory.clear();
    for (int i = 0; i < 30; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey = _getDateKey(date);
      final historyJson =
          prefs.getString('daily_goals_${_currentUserId}_$dateKey');
      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        _goalHistory[dateKey] =
            historyList.map((item) => DailyGoal.fromJson(item)).toList();
      }
    }

    // Auto-update goal statuses
    await _autoUpdateGoalStatuses();

    notifyListeners();
  }

  // Auto-update goal statuses (mark overdue goals as missed)
  Future<void> _autoUpdateGoalStatuses() async {
    bool hasChanges = false;

    for (int i = 0; i < _dailyGoals.length; i++) {
      final goal = _dailyGoals[i];
      if (goal.shouldMarkAsMissed) {
        _dailyGoals[i] = goal.markAsMissed();
        hasChanges = true;
      }
    }

    // Update history goals
    for (String dateKey in _goalHistory.keys) {
      final goals = _goalHistory[dateKey]!;
      for (int i = 0; i < goals.length; i++) {
        final goal = goals[i];
        if (goal.shouldMarkAsMissed) {
          goals[i] = goal.markAsMissed();
          hasChanges = true;
        }
      }
    }

    if (hasChanges) {
      await _saveDailyGoals();
      await _saveAllGoalHistory();
    }
  }

  // Add new daily goal
  Future<void> addDailyGoal(DailyGoal goal) async {
    if (_currentUserId == null) return;

    // Create new goal with current user ID if not set
    DailyGoal goalToAdd = goal;
    if (goal.userId.isEmpty) {
      goalToAdd = goal.copyWith(userId: _currentUserId!);
    }

    try {
      // Save to LocalDatabase
      await LocalDatabase.addDailyGoal(goalToAdd);

      // Update local state
      _dailyGoals.add(goalToAdd);
      await _saveDailyGoals();
      notifyListeners();
    } catch (e) {
      print('Error adding daily goal to database: $e');
      // Fallback to SharedPreferences
      _dailyGoals.add(goalToAdd);
      await _saveDailyGoals();
      notifyListeners();
    }
  }

  // Mark goal as completed
  Future<void> completeGoal(String goalId) async {
    final index = _dailyGoals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      final goal = _dailyGoals[index];

      if (!goal.canComplete) {
        throw Exception('ไม่สามารถทำเป้าหมายนี้ได้ (เลยเวลาหรือทำไปแล้ว)');
      }

      final completedGoal = goal.markAsCompleted();
      _dailyGoals[index] = completedGoal;

      try {
        // Update in LocalDatabase
        await LocalDatabase.updateDailyGoal(completedGoal);
      } catch (e) {
        print('Error updating daily goal in database: $e');
      }

      await _saveDailyGoals();
      notifyListeners();
    }
  }

  // Update goal
  Future<void> updateDailyGoal(DailyGoal goal) async {
    final index = _dailyGoals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _dailyGoals[index] = goal;

      try {
        // Update in LocalDatabase
        await LocalDatabase.updateDailyGoal(goal);
      } catch (e) {
        print('Error updating daily goal in database: $e');
      }

      await _saveDailyGoals();
      notifyListeners();
    }
  }

  // Delete goal
  Future<void> deleteDailyGoal(String goalId) async {
    _dailyGoals.removeWhere((goal) => goal.id == goalId);

    try {
      // Delete from LocalDatabase
      await LocalDatabase.deleteDailyGoal(goalId);
    } catch (e) {
      print('Error deleting daily goal from database: $e');
    }

    await _saveDailyGoals();
    notifyListeners();
  }

  // Get goals for specific date
  List<DailyGoal> getGoalsForDate(DateTime date) {
    final dateKey = _getDateKey(date);
    if (dateKey == _getTodayKey()) {
      return _dailyGoals;
    } else {
      return _goalHistory[dateKey] ?? [];
    }
  }

  // Get today's active goals (can still be completed)
  List<DailyGoal> get getActiveGoals {
    return _dailyGoals.where((goal) => goal.isActiveToday).toList();
  }

  // Get today's completed goals
  List<DailyGoal> get getCompletedGoals {
    return _dailyGoals
        .where((goal) => goal.status == GoalStatus.completed)
        .toList();
  }

  // Get today's missed goals
  List<DailyGoal> get getMissedGoals {
    return _dailyGoals
        .where((goal) => goal.status == GoalStatus.missed)
        .toList();
  }

  // Get goal history for specific date range
  List<DailyGoal> getGoalHistoryForDateRange(
      DateTime startDate, DateTime endDate) {
    List<DailyGoal> history = [];

    for (DateTime date = startDate;
        date.isBefore(endDate.add(Duration(days: 1)));
        date = date.add(Duration(days: 1))) {
      final dateKey = _getDateKey(date);
      if (dateKey == _getTodayKey()) {
        history.addAll(_dailyGoals);
      } else {
        history.addAll(_goalHistory[dateKey] ?? []);
      }
    }

    return history;
  }

  // Get statistics for date range
  Map<String, dynamic> getGoalStatistics(DateTime startDate, DateTime endDate) {
    final goals = getGoalHistoryForDateRange(startDate, endDate);

    int totalGoals = goals.length;
    int completedGoals =
        goals.where((g) => g.status == GoalStatus.completed).length;
    int missedGoals = goals.where((g) => g.status == GoalStatus.missed).length;
    int pendingGoals =
        goals.where((g) => g.status == GoalStatus.pending).length;

    return {
      'total': totalGoals,
      'completed': completedGoals,
      'missed': missedGoals,
      'pending': pendingGoals,
      'completionRate':
          totalGoals > 0 ? (completedGoals / totalGoals * 100).round() : 0,
    };
  }

  // Get today's statistics
  Map<String, dynamic> get getTodayStatistics {
    return getGoalStatistics(DateTime.now(), DateTime.now());
  }

  // Reset goals for new day
  Future<void> resetGoalsForNewDay() async {
    final today = DateTime.now();
    final yesterday = today.subtract(Duration(days: 1));
    final yesterdayKey = _getDateKey(yesterday);

    // Save yesterday's goals to history
    if (_dailyGoals.isNotEmpty) {
      _goalHistory[yesterdayKey] = List.from(_dailyGoals);
      await _saveGoalHistory(yesterdayKey);
    }

    // Create new goals for today based on yesterday's goals
    List<DailyGoal> newGoals = [];
    for (var goal in _dailyGoals) {
      if (goal.status == GoalStatus.completed ||
          goal.status == GoalStatus.missed) {
        // Create new goal for today
        final newGoal = goal.createForNextDay();
        newGoals.add(newGoal);
      }
    }

    // Update current goals
    _dailyGoals = newGoals;
    await _saveDailyGoals();
    notifyListeners();
  }

  // Save current daily goals
  Future<void> _saveDailyGoals() async {
    if (_currentUserId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final goalsJson = json.encode(_dailyGoals.map((g) => g.toJson()).toList());
    await prefs.setString(
        'daily_goals_${_currentUserId}_${_getTodayKey()}', goalsJson);
  }

  // Save goal history for specific date
  Future<void> _saveGoalHistory(String dateKey) async {
    if (_currentUserId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final historyJson = json
        .encode(_goalHistory[dateKey]?.map((g) => g.toJson()).toList() ?? []);
    await prefs.setString(
        'daily_goals_${_currentUserId}_$dateKey', historyJson);
  }

  // Save all goal history
  Future<void> _saveAllGoalHistory() async {
    for (String dateKey in _goalHistory.keys) {
      await _saveGoalHistory(dateKey);
    }
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
      await LocalDatabase.clearUserDailyGoalData(_currentUserId!);
    } catch (e) {
      print('Error clearing user daily goal data from database: $e');
    }

    // Clear from SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Clear current goals
    await prefs.remove('daily_goals_${_currentUserId}_${_getTodayKey()}');
    _dailyGoals.clear();

    // Clear history
    for (String dateKey in _goalHistory.keys) {
      await prefs.remove('daily_goals_${_currentUserId}_$dateKey');
    }
    _goalHistory.clear();

    notifyListeners();
  }

  // Get user data summary
  Future<Map<String, dynamic>> getUserDataSummary() async {
    if (_currentUserId == null) {
      return {
        'goalsCount': 0,
        'completedCount': 0,
        'missedCount': 0,
        'completionRate': 0,
      };
    }

    try {
      return await LocalDatabase.getDailyGoalSummary(_currentUserId!);
    } catch (e) {
      print('Error getting daily goal summary: $e');
      final stats = getTodayStatistics;
      return {
        'goalsCount': stats['total'],
        'completedCount': stats['completed'],
        'missedCount': stats['missed'],
        'completionRate': stats['completionRate'],
      };
    }
  }

  // Get goals by tag
  List<DailyGoal> getGoalsByTag(String tag) {
    return _dailyGoals.where((goal) => goal.tags.contains(tag)).toList();
  }

  // Get all available tags
  Set<String> get getAllTags {
    Set<String> tags = {};
    for (var goal in _dailyGoals) {
      tags.addAll(goal.tags);
    }
    return tags;
  }

  // Check if any goals are overdue
  bool get hasOverdueGoals {
    return _dailyGoals.any((goal) => goal.isOverdue);
  }

  // Get overdue goals count
  int get overdueGoalsCount {
    return _dailyGoals.where((goal) => goal.isOverdue).length;
  }
}
