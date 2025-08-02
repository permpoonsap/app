import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/exercise_log_provider.dart';
import '../provider/brain_game_provider.dart';
import '../provider/medicine_provider.dart';

class DailySummaryScreen extends StatelessWidget {
  const DailySummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logProvider = Provider.of<ExerciseLogProvider>(context);
    final gameProvider = Provider.of<BrainGameProvider>(context);
    final medicineProvider = Provider.of<MedicineProvider>(context);
    final today = DateTime.now();
    final dateKey =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final logs = logProvider.logs[dateKey] ?? [];
    final gameLogs = gameProvider.getGameLogsForDate(today);
    final medicineLogs = medicineProvider.getMedicinesForDate(today);
    final takenMedicines =
        medicineLogs.where((medicine) => medicine.isTaken).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFFC107),
        title: Text('สรุปกิจกรรมประจำวัน'),
        centerTitle: true,
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
                Text(
                  'กิจกรรมวันที่ ${today.day}/${today.month}/${today.year}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                            'เล่น ${gameLogs.length} เกม ได้ ${gameProvider.getTotalScoreForDate(today)} คะแนน',
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
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
