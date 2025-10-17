import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/exercise_log_provider.dart';
import '../provider/brain_game_provider.dart';
import '../provider/medicine_provider.dart';
import '../provider/daily_goal_provider.dart';
import '../model/daily_goal.dart';

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({Key? key}) : super(key: key);

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    // โหลดข้อมูลเมื่อเข้าหน้า
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataForSelectedDate();
    });
  }

  void _changeDay(int deltaDays) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: deltaDays));
    });
    // โหลดข้อมูลใหม่สำหรับวันที่เลือก
    _loadDataForSelectedDate();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
      // โหลดข้อมูลใหม่สำหรับวันที่เลือก
      _loadDataForSelectedDate();
    }
  }

  // โหลดข้อมูลสำหรับวันที่เลือก
  Future<void> _loadDataForSelectedDate() async {
    try {
      final medicineProvider =
          Provider.of<MedicineProvider>(context, listen: false);
      final goalProvider =
          Provider.of<DailyGoalProvider>(context, listen: false);
      final exerciseProvider =
          Provider.of<ExerciseLogProvider>(context, listen: false);
      final gameProvider =
          Provider.of<BrainGameProvider>(context, listen: false);

      // โหลดข้อมูลยาสำหรับวันที่เลือก
      await medicineProvider.loadMedicines();

      // โหลดข้อมูลเป้าหมายสำหรับวันที่เลือก
      await goalProvider.loadDailyGoals();

      // โหลดข้อมูลออกกำลังกาย
      await exerciseProvider.loadLogs();

      // โหลดข้อมูลเกมฝึกสมอง
      await gameProvider.loadGameLogs();
    } catch (e) {
      print('Error loading data for selected date: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final logProvider = Provider.of<ExerciseLogProvider>(context);
    final gameProvider = Provider.of<BrainGameProvider>(context);
    final medicineProvider = Provider.of<MedicineProvider>(context);
    final goalProvider = Provider.of<DailyGoalProvider>(context);
    final dateKey =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final logs = logProvider.logs[dateKey] ?? [];
    final gameLogs = gameProvider.getGameLogsForDate(_selectedDate);
    final medicineLogs = medicineProvider.getMedicinesForDate(_selectedDate);
    final takenMedicines =
        medicineLogs.where((medicine) => medicine.isTaken).toList();
    final todayGoals = goalProvider.getGoalsForDate(_selectedDate);
    final completedGoals = todayGoals
        .where((goal) => goal.status == GoalStatus.completed)
        .toList();
    final missedGoals =
        todayGoals.where((goal) => goal.status == GoalStatus.missed).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFFC107),
        title: Text('สรุปกิจกรรมประจำวัน'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month),
            onPressed: _pickDate,
            tooltip: 'เลือกวันที่',
          ),
        ],
      ),
      backgroundColor: Color(0xFFFFF3CD),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'กิจกรรมวันที่ ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: () => _changeDay(-1),
                  tooltip: 'วันก่อนหน้า',
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: () => _changeDay(1),
                  tooltip: 'วันถัดไป',
                ),
              ],
            ),
            SizedBox(height: 24),

            // สรุปคะแนนเกม
            if (gameLogs.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF9370DB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.psychology_alt, color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'เกมฝึกสมอง',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'เล่น ${gameLogs.length} เกม ได้ ${gameProvider.getTotalScoreForDate(_selectedDate)} คะแนน',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],

            // สรุปการทานยา
            if (takenMedicines.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF2E7D5F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.medication, color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'การทานยา',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'ทานยา ${takenMedicines.length} รายการ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],

            if (logs.isEmpty && gameLogs.isEmpty && takenMedicines.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'ยังไม่ได้บันทึกกิจกรรม',
                    style: TextStyle(fontSize: 22, color: Colors.grey),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  children: [
                    // แสดงผลเกมฝึกสมอง
                    if (gameLogs.isNotEmpty) ...[
                      Text(
                        'เกมฝึกสมอง',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9370DB),
                        ),
                      ),
                      SizedBox(height: 12),
                      ...gameLogs
                          .map((gameLog) => Card(
                                color: Color(0xFF9370DB),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  leading: Icon(Icons.psychology_alt,
                                      color: Colors.white, size: 36),
                                  title: Text(
                                    '${gameLog.gameType} - ${gameLog.score}/${gameLog.totalQuestions} คะแนน',
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'เวลา ${gameLog.timestamp.hour.toString().padLeft(2, '0')}:${gameLog.timestamp.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                      SizedBox(height: 24),
                    ],

                    // แสดงผลการออกกำลังกาย
                    if (logs.isNotEmpty) ...[
                      Text(
                        'การออกกำลังกาย',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      SizedBox(height: 12),
                      ...logs.asMap().entries.map((entry) {
                        final exerciseName = entry.value;
                        return Card(
                          color: Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.check_circle,
                                color: Colors.white, size: 36),
                            title: Text(
                              exerciseName,
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }).toList(),
                    ],

                    // แสดงผลการทานยา
                    if (takenMedicines.isNotEmpty) ...[
                      Text(
                        'การทานยา',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D5F),
                        ),
                      ),
                      SizedBox(height: 12),
                      ...takenMedicines
                          .map((medicine) => Card(
                                color: Color(0xFF2E7D5F),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  leading: Icon(Icons.medication,
                                      color: Colors.white, size: 36),
                                  title: Text(
                                    '${medicine.name} - ${medicine.dose} เม็ด',
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: medicine.takenAt != null
                                      ? Text(
                                          'เวลา ${medicine.takenAt!.hour.toString().padLeft(2, '0')}:${medicine.takenAt!.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.8),
                                          ),
                                        )
                                      : null,
                                ),
                              ))
                          .toList(),
                    ],

                    // แสดงผลเป้าหมายประจำวัน
                    if (todayGoals.isNotEmpty) ...[
                      SizedBox(height: 24),
                      Text(
                        'เป้าหมายประจำวัน',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                      SizedBox(height: 12),

                      // แสดงเป้าหมายที่ทำสำเร็จ
                      if (completedGoals.isNotEmpty) ...[
                        Text(
                          'ทำสำเร็จ (${completedGoals.length})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 8),
                        ...completedGoals
                            .map((goal) => Card(
                                  color: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    leading: Icon(Icons.check_circle,
                                        color: Colors.white, size: 36),
                                    title: Text(
                                      goal.title,
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: goal.completedAt != null
                                        ? Text(
                                            'ทำสำเร็จเวลา ${goal.completedAt!.hour.toString().padLeft(2, '0')}:${goal.completedAt!.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                            ),
                                          )
                                        : null,
                                  ),
                                ))
                            .toList(),
                        SizedBox(height: 16),
                      ],

                      // แสดงเป้าหมายที่ไม่ได้ทำ
                      if (missedGoals.isNotEmpty) ...[
                        Text(
                          'ไม่ได้ทำ (${missedGoals.length})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 8),
                        ...missedGoals
                            .map((goal) => Card(
                                  color: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    leading: Icon(Icons.cancel,
                                        color: Colors.white, size: 36),
                                    title: Text(
                                      goal.title,
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      'กำหนดเวลา ${goal.targetTimeText}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                        SizedBox(height: 16),
                      ],

                      // แสดงสถิติรวม
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF2196F3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.analytics,
                                color: Colors.white, size: 32),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'สรุปเป้าหมาย',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'ทั้งหมด ${todayGoals.length} เป้าหมาย ทำสำเร็จ ${completedGoals.length} เป้าหมาย (${todayGoals.length > 0 ? (completedGoals.length / todayGoals.length * 100).round() : 0}%)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
