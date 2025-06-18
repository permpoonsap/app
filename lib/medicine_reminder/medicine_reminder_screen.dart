import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'AddMedicineScreen.dart';
import 'medicine_history_screen.dart';
import '../provider/medicine_provider.dart';
import '../model/medicine_item.dart';

class MedicineReminderScreen extends StatelessWidget {
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
              fontSize: 32, 
              fontWeight: FontWeight.bold,
              color: Colors.white,
            )),
        backgroundColor: Colors.teal[600],
        toolbarHeight: 80,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Colors.white, size: 36), 
          onPressed: () => Navigator.pop(context),
          iconSize: 36,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history,
                size: 40, color: Colors.white), // Increased from 32
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MedicineHistoryScreen()),
                ),

            tooltip: "ประวัติการทานยา",
            iconSize: 40,
          ),
          SizedBox(width: 16), // Increased spacing
        ],
      ),
      body: Column(
        children: [
          // วันที่ปัจจุบัน
          Container(
            margin: EdgeInsets.all(20), // Increased margin
            padding: EdgeInsets.all(24), // Increased padding
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 182, 240, 232),
              borderRadius: BorderRadius.circular(16), // Slightly larger radius
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 6,
                    spreadRadius: 2)
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today,
                        color: Colors.teal[600], size: 28),
                    SizedBox(width: 12),
                    Text(thaiDay,
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.teal[500],
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(thaiDate,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(width: 16),
                    Text(thaiMonthYear,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),

          // หัวข้อ
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20), 
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("รายการยาวันนี้",
                  style: TextStyle(
                    fontSize: 32, 
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 0, 0, 0),
                  )),
            ),
          ),
          SizedBox(height: 16), // Increased spacing

          // รายการยา
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 20), // Added horizontal padding
              child: ListView.builder(
                itemCount: medicines.length,
                itemBuilder: (context, index) {
                  final item = medicines[index];

                  // สร้าง DateTime เพื่อใช้ format แบบไทย
                  final now = DateTime.now();
                  final dt = DateTime(now.year, now.month, now.day,
                      item.time.hour, item.time.minute);
                  final thaiTime = DateFormat.Hm().format(dt)+ " น.";
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
      floatingActionButton: Container(
        width: 80, // Larger FAB
        height: 80,
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddMedicineScreen()),
          ),
          child: Icon(Icons.add, size: 40), // Increased icon size
          backgroundColor: Colors.teal[600],
          foregroundColor: Colors.white,
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
        margin: EdgeInsets.only(bottom: 16), // Increased margin
        padding: EdgeInsets.all(24), // Increased padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), // Larger radius
          border: Border.all(
            color: isDone ? Colors.green[300]! : Colors.orange[300]!,
            width: 2,
          ), // Added border for better visibility
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 6,
              spreadRadius: 1,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70, // Increased size
              height: 70,
              decoration: BoxDecoration(
                color: isDone ? Colors.green[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: isDone ? Colors.green[400]! : Colors.orange[400]!,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.medical_services,
                size: 36, // Increased from 28
                color: isDone ? Colors.green[600] : Colors.orange[600],
              ),
            ),
            SizedBox(width: 20), // Increased spacing
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(time,
                      style: TextStyle(
                        fontSize: 24, // Increased from 18
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      )),
                  SizedBox(height: 8), // Increased spacing
                  Text(name,
                      style: TextStyle(
                        fontSize: 26, // Increased from 20
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      )),
                  SizedBox(height: 8), // Increased spacing
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDone ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isDone ? Colors.green[300]! : Colors.orange[300]!,
                        width: 1,
                      ),
                    ),
                    child: Text(status,
                        style: TextStyle(
                          fontSize: 20, // Increased from 16
                          fontWeight: FontWeight.w600,
                          color:
                              isDone ? Colors.green[700] : Colors.orange[700],
                        )),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDone ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                isDone ? Icons.check_circle : Icons.access_time,
                size: 44, // Increased from 35
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
                      fontSize: 28,
                      color: Colors.grey[800],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, size: 28, color: Colors.grey[600]),
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Medicine details
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow("🕒", "เวลา", thaiTime),
                  SizedBox(height: 16),
                  _buildDetailRow("💊", "ยา", item.name),
                  SizedBox(height: 16),
                  _buildDetailRow("📊", "ปริมาณ", "${item.dose} เม็ด"),
                  SizedBox(height: 16),
                  _buildDetailRow(
                      "📋", "สถานะ", item.isTaken ? "ทานแล้ว ✅" : "ยังไม่ทาน ⏳"),
                ],
              ),
              
              SizedBox(height: 30),
              
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
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      child: Text(item.isTaken ? "ยกเลิกการทาน" : "ทานยาแล้ว"),
                    ),
                  ),
                  
                  SizedBox(width: 12),
                  
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
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
    return Container(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 24)),
          SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 22, color: Colors.grey[800]),
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