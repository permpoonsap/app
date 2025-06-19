import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'addMedicineScreen.dart';
import 'medicine_history_screen.dart';
import '../provider/medicine_provider.dart';
import '../model/medicine_item.dart';

class MedicineReminderScreen extends StatelessWidget {
  const MedicineReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thaiDay = DateFormat.EEEE('th_TH').format(now);
    final thaiDate = DateFormat.d().format(now);
    final thaiMonthYear = DateFormat.yMMMM('th_TH').format(now);

    final medicines = Provider.of<MedicineProvider>(context).items;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("เตือนกินยา",
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold,
              color: Colors.white,
            )),
        backgroundColor: Colors.teal[600],
        toolbarHeight: 60,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Colors.white, size: 24), 
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history,
                size: 24, color: Colors.white),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MedicineHistoryScreen()),
                ),
            tooltip: "ประวัติการทานยา",
          ),
          SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // วันที่ปัจจุบัน
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 182, 240, 232),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 4,
                    spreadRadius: 1)
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today,
                        color: Colors.teal[600], size: 20),
                    SizedBox(width: 8),
                    Text(thaiDay,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.teal[500],
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(thaiDate,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(width: 12),
                    Text(thaiMonthYear,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),

          // หัวข้อ
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16), 
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("รายการยาวันนี้",
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 0, 0, 0),
                  )),
            ),
          ),
          SizedBox(height: 12),

          // รายการยา
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                itemCount: medicines.length,
                itemBuilder: (context, index) {
                  final item = medicines[index];

                  // สร้าง DateTime เพื่อใช้ format แบบไทย
                  final now = DateTime.now();
                  final dt = DateTime(now.year, now.month, now.day,
                      item.time.hour, item.time.minute);
                  final thaiTime = "${DateFormat.Hm().format(dt)} น.";
                  return GestureDetector(
                    onTap: () => _showMedicineDetailDialog(context, item),
                    child: _buildMedicineCard(
                      time: thaiTime,
                      name: "${item.name} ${item.dose} เม็ด",
                      status: item.isTaken ? "ทานแล้ว" : "ยังไม่ทาน",
                      isDone: item.isTaken,
                      onTap: () => _showMedicineDetailDialog(context, item),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddMedicineScreen()),
          ),
          backgroundColor: Colors.teal[600],
          foregroundColor: Colors.white,
          child: Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  Widget _buildMedicineCard({
    required String time,
    required String name,
    required String status,
    required bool isDone,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDone ? Colors.green[300]! : Colors.orange[300]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 4,
              spreadRadius: 1,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDone ? Colors.green[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isDone ? Colors.green[400]! : Colors.orange[400]!,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.medical_services,
                size: 24,
                color: isDone ? Colors.green[600] : Colors.orange[600],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(time,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      )),
                  SizedBox(height: 4),
                  Text(name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      )),
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDone ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isDone ? Colors.green[300]! : Colors.orange[300]!,
                        width: 1,
                      ),
                    ),
                    child: Text(status,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              isDone ? Colors.green[700] : Colors.orange[700],
                        )),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDone ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isDone ? Icons.check_circle : Icons.access_time,
                size: 28,
                color: isDone ? Colors.green[600] : Colors.orange[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMedicineDetailDialog(BuildContext context, MedicineItem item) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, item.time.hour, item.time.minute);
    final thaiTime = DateFormat.Hm('th').format(dt);
    
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "รายละเอียดยา",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.grey[800],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, size: 24, color: Colors.grey[600]),
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Medicine details
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow("🕒", "เวลา", thaiTime),
                  SizedBox(height: 12),
                  _buildDetailRow("💊", "ยา", item.name),
                  SizedBox(height: 12),
                  _buildDetailRow("📊", "ปริมาณ", "${item.dose} เม็ด"),
                  SizedBox(height: 12),
                  _buildDetailRow(
                      "📋", "สถานะ", item.isTaken ? "ทานแล้ว ✅" : "ยังไม่ทาน ⏳"),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Action buttons - centered
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Take medicine button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Provider.of<MedicineProvider>(context, listen: false)
                            .toggleTaken(item);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            item.isTaken ? Colors.orange[600] : Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      child: Text(item.isTaken ? "ยกเลิกการทาน" : "ทานยาแล้ว"),
                    ),
                  ),
                  
                  SizedBox(width: 8),
                  
                  // Delete button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Provider.of<MedicineProvider>(context, listen: false)
                            .removeMedicine(item);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      child: Text("ลบรายการ"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String emoji, String label, String value) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}