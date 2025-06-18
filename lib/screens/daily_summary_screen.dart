import 'package:flutter/material.dart';

class DailySummaryScreen extends StatefulWidget {
  @override
  _DailySummaryScreenState createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  DateTime selectedDate = DateTime.now();
  
  // ข้อมูลตัวอย่าง
  final Map<String, dynamic> dailyData = {
    'medicine_taken': 3,
    'medicine_total': 4,
    'water_intake': 6,
    'water_goal': 8,
    'exercise_minutes': 30,
    'exercise_goal': 45,
    'sleep_hours': 7.5,
    'mood_rating': 4,
    'steps': 8500,
    'steps_goal': 10000,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8D6),
      appBar: AppBar(
        title: Text('สรุปรายวัน', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // เลือกวันที่
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'วันที่: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // สรุปข้อมูล
            Expanded(
              child: ListView(
                children: [
                  _buildSummaryCard('การกินยา', '${dailyData['medicine_taken']}/${dailyData['medicine_total']} ครั้ง', 
                      Icons.medication, Colors.cyan, dailyData['medicine_taken'] / dailyData['medicine_total']),
                  
                  _buildSummaryCard('การดื่มน้ำ', '${dailyData['water_intake']}/${dailyData['water_goal']} แก้ว', 
                      Icons.local_drink, Colors.blue, dailyData['water_intake'] / dailyData['water_goal']),
                  
                  _buildSummaryCard('การออกกำลังกาย', '${dailyData['exercise_minutes']}/${dailyData['exercise_goal']} นาที', 
                      Icons.fitness_center, Colors.orange, dailyData['exercise_minutes'] / dailyData['exercise_goal']),
                  
                  _buildSummaryCard('การนอนหลับ', '${dailyData['sleep_hours']} ชั่วโมง', 
                      Icons.bedtime, Colors.purple, dailyData['sleep_hours'] / 8),
                  
                  _buildSummaryCard('จำนวนก้าว', '${dailyData['steps']}/${dailyData['steps_goal']} ก้าว', 
                      Icons.directions_walk, Colors.green, dailyData['steps'] / dailyData['steps_goal']),
                  
                  _buildMoodCard('อารมณ์วันนี้', dailyData['mood_rating']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, double progress) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(value, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress > 1.0 ? 1.0 : progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCard(String title, int rating) {
    List<String> moods = ['😢', '😞', '😐', '😊', '😄'];
    List<String> moodTexts = ['แย่มาก', 'แย่', 'ปกติ', 'ดี', 'ดีมาก'];
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.mood, color: Colors.amber, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text(moods[rating - 1], style: TextStyle(fontSize: 24)),
                    SizedBox(width: 8),
                    Text(moodTexts[rating - 1], style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }
}