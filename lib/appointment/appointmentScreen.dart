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
          ? Center(child: Text('ยังไม่มีนัดหมาย'))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return _buildAppointmentCardFromModel(
                    context, appointment, index);
              },
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

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.medical_services_outlined, color: Colors.teal[700]),
        title: Text(item.doctorName,
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("เหตุผล: " + item.reason),
            Text("วันที่: $dateStr  เวลา: $timeStr"),
          ],
        ),
        trailing: PopupMenuButton<String>(
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
                  Text('ลบ', style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ),
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

  const EditAppointmentDialog({
    Key? key,
    required this.appointment,
    required this.index,
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
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text('เวลา'),
                    subtitle: Text(_selectedTime.format(context)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (time != null) {
                        setState(() {
                          _selectedTime = time;
                        });
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
            if (_doctorNameController.text.isNotEmpty &&
                _reasonController.text.isNotEmpty) {
              final updatedAppointment = widget.appointment.copyWith(
                doctorName: _doctorNameController.text,
                reason: _reasonController.text,
                dateTime: DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  _selectedTime.hour,
                  _selectedTime.minute,
                ),
              );

              context
                  .read<AppointmentProvider>()
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
          },
          child: Text('บันทึก'),
        ),
      ],
    );
  }
}
