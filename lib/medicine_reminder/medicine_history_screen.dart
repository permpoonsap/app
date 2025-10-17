import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../provider/medicine_provider.dart';
import '../model/medicine_item.dart';

class MedicineHistoryScreen extends StatelessWidget {
  const MedicineHistoryScreen({super.key});

  // Load medicine history efficiently
  Future<List<MedicineItem>> _loadMedicineHistory(
      MedicineProvider medicineProvider) async {
    // Load medicines if not already loaded
    if (medicineProvider.medicines.isEmpty &&
        medicineProvider.medicineHistory.isEmpty) {
      await medicineProvider.loadMedicines();
    }

    // Get medicine history for last 30 days
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: 30));
    final historyList =
        medicineProvider.getMedicineHistoryForDateRange(startDate, endDate);
    final takenMedicines = historyList.where((item) => item.isTaken).toList();

    // เรียงจากล่าสุดไปเก่าสุด
    takenMedicines.sort((a, b) {
      final aTime = a.takenAt ?? DateTime.now();
      final bTime = b.takenAt ?? DateTime.now();
      return bTime.compareTo(aTime);
    });

    return takenMedicines;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineProvider>(
      builder: (context, medicineProvider, child) {
        return Scaffold(
          backgroundColor: Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Color(0xFF2E7D5F),
            elevation: 2,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "ประวัติการทานยา",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
          ),
          body: FutureBuilder(
            future: _loadMedicineHistory(medicineProvider),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF2E7D5F)),
                      SizedBox(height: 16),
                      Text(
                        "กำลังโหลดประวัติ...",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      SizedBox(height: 16),
                      Text(
                        "เกิดข้อผิดพลาดในการโหลดข้อมูล",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final takenMedicines = snapshot.data ?? [];

              return takenMedicines.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: takenMedicines.length,
                      itemBuilder: (context, index) {
                        final item = takenMedicines[index];
                        return _buildHistoryCard(context, item, index == 0);
                      },
                    );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 24),
            Text(
              "ยังไม่มีประวัติการทานยา",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              "เมื่อคุณทานยาแล้ว ประวัติจะแสดงที่นี่",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
      BuildContext context, MedicineItem item, bool isLatest) {
    final takenTime = item.takenAt ?? DateTime.now();
    final thaiDate = _formatThaiDate(takenTime);
    final thaiTime = _formatThaiTime(takenTime);
    final isToday = _isToday(takenTime);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isLatest
            ? Border.all(color: Color(0xFF32CD32), width: 2)
            : Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            spreadRadius: 0,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            // ไอคอนสถานะ
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF32CD32).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Color(0xFF32CD32),
                size: 28,
              ),
            ),
            SizedBox(width: 16),
            // ข้อมูลยา
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ชื่อยาและขนาด
                  Text(
                    "${item.name}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF4A90E2).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${item.dose} เม็ด",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A90E2),
                          ),
                        ),
                      ),
                      if (isLatest) ...[
                        SizedBox(width: 8),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFF32CD32).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "ล่าสุด",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF32CD32),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 8),
                  // วันที่และเวลา
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: 6),
                      Text(
                        isToday
                            ? "วันนี้ เวลา $thaiTime"
                            : "$thaiDate เวลา $thaiTime ",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatThaiTime(DateTime dateTime) {
    return DateFormat.Hm('th').format(dateTime);
  }

  String _formatThaiDate(DateTime dateTime) {
    return DateFormat.MMMMd('th').format(dateTime); // ไม่แสดงปี
  }

  bool _isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.day == now.day &&
        dateTime.month == now.month &&
        dateTime.year == now.year;
  }
}
