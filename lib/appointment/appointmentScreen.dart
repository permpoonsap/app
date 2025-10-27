import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/appointment_provider.dart';
import '../model/appointment_item.dart';
import 'AddAppointmentScreen.dart';

class AppointmentScreen extends StatelessWidget {
  const AppointmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appointments = context.watch<AppointmentProvider>().appointments;

    return Scaffold(
      appBar: AppBar(
        title: Text("นัดหมายแพทย์"),
        backgroundColor: Colors.teal[600],
      ),
      body: appointments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'ยังไม่มีนัดหมาย',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'กดปุ่ม + เพื่อเพิ่มนัดหมายใหม่',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // หมายเหตุเกี่ยวกับระบบแจ้งเตือน
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.notifications_active,
                            color: Colors.blue[600],
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'ระบบแจ้งเตือนนัดหมาย',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        '• แจ้งเตือนล่วงหน้า 1 วันก่อนนัดหมาย\n'
                        '• แจ้งเตือนอีกครั้ง 30 นาทีก่อนนัดหมาย\n'
                        '• การแจ้งเตือนจะแสดงบนหน้าจอและส่งเสียงเตือน',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // รายการนัดหมาย
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      final appointment = appointments[index];
                      return _buildAppointmentCardFromModel(
                          context, appointment, index);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<AppointmentProvider>(),
                child: AddAppointmentScreen(),
              ),
            ),
          );
        },
        backgroundColor: Colors.teal[600],
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppointmentCardFromModel(
      BuildContext context, AppointmentItem item, int index) {
    final date = item.dateTime;
    final dateStr = "${date.day}/${date.month}/${date.year}";
    final timeStr =
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} น.";

    // คำนวณเวลาที่เหลือจนถึงนัดหมาย
    final now = DateTime.now();
    final timeUntilAppointment = date.difference(now);
    final daysUntil = timeUntilAppointment.inDays;
    final hoursUntil = timeUntilAppointment.inHours;

    String notificationStatus = '';
    Color statusColor = Colors.grey;

    if (timeUntilAppointment.isNegative) {
      notificationStatus = 'นัดหมายผ่านไปแล้ว';
      statusColor = Colors.red;
    } else if (daysUntil == 0) {
      if (hoursUntil <= 1) {
        notificationStatus = 'แจ้งเตือนแล้ว (30 นาที)';
        statusColor = Colors.orange;
      } else {
        notificationStatus = 'วันนี้นัดหมาย';
        statusColor = Colors.blue;
      }
    } else if (daysUntil == 1) {
      notificationStatus = 'แจ้งเตือนแล้ว (1 วัน)';
      statusColor = Colors.green;
    } else if (daysUntil <= 7) {
      notificationStatus = 'จะแจ้งเตือนในอีก ${daysUntil} วัน';
      statusColor = Colors.blue;
    } else {
      notificationStatus = 'จะแจ้งเตือนในอีก ${daysUntil} วัน';
      statusColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services_outlined,
                    color: Colors.teal[700], size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.doctorName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "เหตุผล: " + item.reason,
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditAppointmentDialog(context, item, index);
                        break;
                      case 'delete':
                        _showDeleteConfirmationDialog(context, index);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('แก้ไข', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text('ลบ',
                              style:
                                  TextStyle(color: Colors.red, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                SizedBox(width: 8),
                Text(
                  "วันที่: $dateStr  เวลา: $timeStr",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.notifications, color: statusColor, size: 16),
                SizedBox(width: 8),
                Text(
                  notificationStatus,
                  style: TextStyle(
                    fontSize: 14,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // แสดง dialog แก้ไขข้อมูลนัดพบแพทย์
  void _showEditAppointmentDialog(
      BuildContext context, AppointmentItem item, int index) {
    showDialog(
      context: context,
      builder: (context) => EditAppointmentDialog(
        appointment: item,
        index: index,
        appointmentProvider: context.read<AppointmentProvider>(),
      ),
    );
  }

  // แสดง dialog ยืนยันการลบ
  void _showDeleteConfirmationDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบรายการนัดพบแพทย์นี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AppointmentProvider>().deleteAppointment(index);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ลบรายการนัดพบแพทย์เรียบร้อยแล้ว'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('ลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Dialog สำหรับแก้ไขข้อมูลนัดพบแพทย์
class EditAppointmentDialog extends StatefulWidget {
  final AppointmentItem appointment;
  final int index;
  final AppointmentProvider appointmentProvider;

  const EditAppointmentDialog({
    Key? key,
    required this.appointment,
    required this.index,
    required this.appointmentProvider,
  }) : super(key: key);

  @override
  State<EditAppointmentDialog> createState() => _EditAppointmentDialogState();
}

class _EditAppointmentDialogState extends State<EditAppointmentDialog> {
  late TextEditingController _doctorNameController;
  late TextEditingController _reasonController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _doctorNameController =
        TextEditingController(text: widget.appointment.doctorName);
    _reasonController = TextEditingController(text: widget.appointment.reason);
    _selectedDate = widget.appointment.dateTime;
    _selectedTime = TimeOfDay.fromDateTime(widget.appointment.dateTime);
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('แก้ไขข้อมูลนัดพบแพทย์'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _doctorNameController,
              decoration: InputDecoration(
                labelText: 'ชื่อแพทย์/คลินิก',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'เหตุผล/อาการ',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text('วันที่'),
                    subtitle: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                    onTap: () async {
                      try {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.teal[600]!,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      } catch (e) {
                        print('Error showing date picker: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('เกิดข้อผิดพลาดในการเลือกวันที่'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text('เวลา'),
                    subtitle: Text(_selectedTime.format(context)),
                    onTap: () async {
                      try {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.teal[600]!,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (time != null) {
                          setState(() {
                            _selectedTime = time;
                          });
                        }
                      } catch (e) {
                        print('Error showing time picker: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('เกิดข้อผิดพลาดในการเลือกเวลา'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: () {
            try {
              if (_doctorNameController.text.isNotEmpty &&
                  _reasonController.text.isNotEmpty) {
                final updatedAppointment = widget.appointment.copyWith(
                  doctorName: _doctorNameController.text.trim(),
                  reason: _reasonController.text.trim(),
                  dateTime: DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    _selectedTime.hour,
                    _selectedTime.minute,
                  ),
                );

                widget.appointmentProvider
                    .updateAppointment(widget.index, updatedAppointment);

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('แก้ไขข้อมูลนัดพบแพทย์เรียบร้อยแล้ว'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              print('Error updating appointment: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Text('บันทึก'),
        ),
      ],
    );
  }
}
