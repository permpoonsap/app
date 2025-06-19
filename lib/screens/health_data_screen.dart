import 'package:flutter/material.dart';

class HealthDataScreen extends StatefulWidget {
  const HealthDataScreen({super.key});

  @override
  _HealthDataScreenState createState() => _HealthDataScreenState();
}

class _HealthDataScreenState extends State<HealthDataScreen> {
  int selectedTab = 0;
  
  // ข้อมูลสุขภาพตัวอย่าง
  final Map<String, dynamic> healthData = {
    'blood_pressure': {'systolic': 120, 'diastolic': 80},
    'heart_rate': 72,
    'weight': 65.5,
    'height': 165,
    'blood_sugar': 95,
    'temperature': 36.5,
    'bmi': 24.1,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8D6),
      appBar: AppBar(
        title: Text('ข้อมูลสุขภาพ', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // แท็บเลือกหมวดหมู่
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('ข้อมูลพื้นฐาน', 0),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton('ประวัติการวัด', 1),
                ),
              ],
            ),
          ),
          
          // เนื้อหาตามแท็บที่เลือก
          Expanded(
            child: selectedTab == 0 ? _buildBasicHealthData() : _buildHealthHistory(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    bool isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pink : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBasicHealthData() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildHealthCard('ความดันโลหิต', '${healthData['blood_pressure']['systolic']}/${healthData['blood_pressure']['diastolic']} mmHg', 
              Icons.favorite, Colors.red, 'ปกติ'),
          
          _buildHealthCard('อัตราการเต้นของหัวใจ', '${healthData['heart_rate']} bpm', 
              Icons.monitor_heart, Colors.pink, 'ปกติ'),
          
          _buildHealthCard('น้ำหนัก', '${healthData['weight']} กก.', 
              Icons.monitor_weight, Colors.blue, 'เหมาะสม'),
          
          _buildHealthCard('ส่วนสูง', '${healthData['height']} ซม.', 
              Icons.height, Colors.green, '-'),
          
          _buildHealthCard('ระดับน้ำตาลในเลือด', '${healthData['blood_sugar']} mg/dL', 
              Icons.bloodtype, Colors.orange, 'ปกติ'),
          
          _buildHealthCard('อุณหภูมิร่างกาย', '${healthData['temperature']} °C', 
              Icons.thermostat, Colors.cyan, 'ปกติ'),
          
          _buildHealthCard('ดัชนีมวลกาย (BMI)', '${healthData['bmi']}', 
              Icons.calculate, Colors.purple, 'ปกติ'),
        ],
      ),
    );
  }

  Widget _buildHealthHistory() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'ประวัติการวัดย้อนหลัง 7 วัน',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 7,
              itemBuilder: (context, index) {
                DateTime date = DateTime.now().subtract(Duration(days: index));
                return _buildHistoryCard(date, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(String title, String value, IconData icon, Color color, String status) {
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
          Icon(icon, color: color, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(value, style: TextStyle(fontSize: 18, color: color)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              status,
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(DateTime date, int index) {
    // ข้อมูลตัวอย่างสำหรับประวัติ
    List<Map<String, dynamic>> historyData = [
      {'bp': '118/78', 'hr': 68, 'weight': 65.3},
      {'bp': '122/82', 'hr': 74, 'weight': 65.4},
      {'bp': '120/80', 'hr': 72, 'weight': 65.5},
      {'bp': '119/79', 'hr': 70, 'weight': 65.2},
      {'bp': '121/81', 'hr': 73, 'weight': 65.6},
      {'bp': '123/83', 'hr': 75, 'weight': 65.1},
      {'bp': '120/80', 'hr': 71, 'weight': 65.3},
    ];

    return Container(
      margin: EdgeInsets.only(bottom: 8),
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
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.pink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${date.day}/${date.month}',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('ความดัน', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('${historyData[index]['bp']}', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    Text('ชีพจร', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('${historyData[index]['hr']}', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    Text('น้ำหนัก', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('${historyData[index]['weight']}', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ปกติ':
        return Colors.green;
      case 'เหมาะสม':
        return Colors.blue;
      case 'ต้องระวัง':
        return Colors.orange;
      case 'อันตราย':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}