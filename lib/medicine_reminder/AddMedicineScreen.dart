import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../model/medicine_item.dart';
import '../provider/medicine_provider.dart';
import '../notification/notification_service.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  _AddMedicineScreenState createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController doseController = TextEditingController();
  final TextEditingController hourController = TextEditingController();
  final TextEditingController minuteController = TextEditingController();

  TimeOfDay selectedTime = TimeOfDay.now();

  String get formattedTime {
    final now = DateTime.now();
    final dt = DateTime(
        now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
    return "${DateFormat('HH:mm').format(dt)} น.";
  }

  void _updateTimeFromText() {
    final hour = int.tryParse(hourController.text);
    final minute = int.tryParse(minuteController.text);
    if (hour != null &&
        minute != null &&
        hour >= 0 &&
        hour < 24 &&
        minute >= 0 &&
        minute < 60) {
      setState(() {
        selectedTime = TimeOfDay(hour: hour, minute: minute);
      });
    }
  }

  Future<void> _saveMedicine() async {
    // บันทึก context ก่อน
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final name = nameController.text.trim();
    final dose = doseController.text.trim();

    if (name.isEmpty ||
        dose.isEmpty ||
        hourController.text.isEmpty ||
        minuteController.text.isEmpty) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("กรุณากรอกข้อมูลให้ครบถ้วน",
                style: TextStyle(fontSize: 18)),
            backgroundColor: Colors.red[400],
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final now = DateTime.now();
    DateTime scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(Duration(days: 1));
    }

    final item = MedicineItem(
      userId: 'local_user', // Use local user ID
      name: name,
      dose: dose,
      time: selectedTime,
      scheduledDate: scheduledDate,
    );

    try {
      await Provider.of<MedicineProvider>(context, listen: false)
          .addMedicine(item);

      // Schedule notification
      await NotificationService.scheduleNotification(
        id: name.hashCode ^ scheduledDate.hashCode, // simple unique id
        title: 'แจ้งเตือนยา',
        body: 'ถึงเวลาที่ต้องทานยาแล้ว $name ($dose เม็ด)',
        scheduledDate: scheduledDate,
      );

      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content:
                Text("บันทึกรายการยาสำเร็จ", style: TextStyle(fontSize: 18)),
            backgroundColor: Colors.green[400],
            duration: Duration(seconds: 2),
          ),
        );
        navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("เกิดข้อผิดพลาด: ${e.toString()}",
                style: TextStyle(fontSize: 18)),
            backgroundColor: Colors.red[400],
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("เพิ่มรายการยา",
            style: TextStyle(fontSize: 24, color: Colors.white)),
        backgroundColor: Colors.teal[600],
        toolbarHeight: 70,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ข้อมูลยา",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    Text("ชื่อยา", style: TextStyle(fontSize: 16)),
                    SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        hintText: "กรอกชื่อยา",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text("จำนวนเม็ดที่ต้องทาน", style: TextStyle(fontSize: 16)),
                    SizedBox(height: 6),
                    TextField(
                      controller: doseController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        hintText: "กรอกจำนวน",
                        border: OutlineInputBorder(),
                        suffixText: "เม็ด",
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("เวลาที่ต้องทานยา",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: hourController,
                            keyboardType: TextInputType.number,
                            maxLength: 2,
                            style: TextStyle(fontSize: 18),
                            decoration: InputDecoration(
                              labelText: "ชั่วโมง (0–23)",
                              counterText: "",
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _updateTimeFromText(),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: minuteController,
                            keyboardType: TextInputType.number,
                            maxLength: 2,
                            style: TextStyle(fontSize: 18),
                            decoration: InputDecoration(
                              labelText: "นาที (0–59)",
                              counterText: "",
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _updateTimeFromText(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.teal[200]!, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Text("เวลาที่เลือก", style: TextStyle(fontSize: 16)),
                          SizedBox(height: 6),
                          Text(
                            formattedTime,
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _saveMedicine,
                icon: Icon(Icons.save, size: 24),
                label: Text("บันทึกรายการยา", style: TextStyle(fontSize: 22)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
