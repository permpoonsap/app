import 'package:flutter/material.dart';
import 'screens/daily_summary_screen.dart';
import 'screens/health_data_screen.dart';
import 'medicine_reminder/medicine_reminder_screen.dart';
import 'notification_service.dart'; // **IMPORTANT: Adjust this import path to your actual NotificationService file**

class HomeScreen extends StatelessWidget {
  final String userName = "ลองใจ เย็นเย็น";

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA), // พื้นหลังสีขาวนวลที่นุ่มตา
      appBar: AppBar(
        backgroundColor: Color(0xFF2E7D5F), // สีเขียวเข้มที่มองเห็นชัด
        elevation: 2,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(Icons.menu, color: Colors.white, size: 28),
        ),
        title: Text(
          'หน้าหลัก',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ส่วนโปรไฟล์ที่ปรับปรุงแล้ว
            Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color(0xFF2E7D5F),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Color(0xFFE8F5E8),
                      child: Icon(
                        Icons.account_circle,
                        size: 48,
                        color: Color(0xFF2E7D5F)
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'สวัสดี',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D5F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),


            // ช่องค้นหาที่ปรับปรุงแล้ว
            Container(
              margin: EdgeInsets.only(bottom: 24),
              child: TextField(
                style: TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'ค้นหาฟังก์ชันที่ต้องการ...',
                  hintStyle: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.search, size: 24, color: Colors.grey[600]),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF2E7D5F), width: 2),
                  ),
                ),
              ),
            ),

            // Notification Test Button
            // ElevatedButton(
            //   child: Text("ทดสอบแจ้งเตือนทันที"),
            //   onPressed: () {
            //     // Ensure NotificationService is properly initialized and accessible
            //     NotificationService().showNotification(
            //       id: 999,
            //       title: "แจ้งเตือนทดสอบ",
            //       body: "นี่คือการแจ้งเตือนทันที",
            //     );
            //   },
            // ),
            SizedBox(height: 24), // Add some spacing after the button


            // Grid เมนูที่ปรับปรุงแล้ว
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 0.85, // ทำให้การ์ดสูงขึ้นเล็กน้อย
              children: [
                _buildEnhancedMenuTile(
                  context,
                  'เตือนกินยา',
                  Icons.medication_liquid,
                  Color(0xFF4A90E2),
                  'จัดการยาประจำวัน',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MedicineReminderScreen()),
                    );
                  }
                ),
                _buildEnhancedMenuTile(
                  context,
                  'นัดพบแพทย์',
                  Icons.local_hospital,
                  Color(0xFF7B68EE),
                  'จัดการการนัดหมาย',
                  () {
                    // TODO: ไปยังหน้านัดพบแพทย์
                  }
                ),
                _buildEnhancedMenuTile(
                  context,
                  'เป้าหมายประจำวัน',
                  Icons.track_changes,
                  Color(0xFF32CD32),
                  'ตั้งเป้าหมายสุขภาพ',
                  () {
                    // TODO: ไปยังหน้าตั้งเป้าหมาย
                  }
                ),
                _buildEnhancedMenuTile(
                  context,
                  'ขอความช่วยเหลือ',
                  Icons.support_agent,
                  Color(0xFFFF6B6B),
                  'ติดต่อเจ้าหน้าที่',
                  () {
                    // TODO: ไปยังหน้าขอความช่วยเหลือ
                  }
                ),
                _buildEnhancedMenuTile(
                  context,
                  'ออกกำลังกาย',
                  Icons.directions_walk,
                  Color(0xFFFF8C00),
                  'ท่าออกกำลังกาย',
                  () {
                    // TODO: ไปยังหน้าออกกำลังกาย
                  }
                ),
                _buildEnhancedMenuTile(
                  context,
                  'เกมฝึกสมอง',
                  Icons.psychology_alt,
                  Color(0xFF9370DB),
                  'ฝึกความจำและสมาธิ',
                  () {
                    // TODO: ไปยังหน้าเกมฝึกสมอง
                  }
                ),
                _buildEnhancedMenuTile(
                  context,
                  'สรุปรายวัน',
                  Icons.assessment,
                  Color(0xFF20B2AA),
                  'ดูสรุปกิจกรรม',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DailySummaryScreen()),
                    );
                  }
                ),
                _buildEnhancedMenuTile(
                  context,
                  'ข้อมูลสุขภาพ',
                  Icons.favorite,
                  Color(0xFFE91E63),
                  'ตรวจสอบสุขภาพ',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HealthDataScreen()),
                    );
                  }
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedMenuTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 36,
                    color: color
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}