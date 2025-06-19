import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/appointment_provider.dart';
import '../model/appointment_item.dart';
import 'appointmentScreen.dart';

class AddAppointmentScreen extends StatefulWidget {
  @override
  _AddAppointmentScreenState createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final newAppointment = AppointmentItem(
        doctorName: _titleController.text,
        reason: _descriptionController.text,
        dateTime: _selectedDate!,
        alertBefore: Duration(minutes: 30), // หรือให้เลือกจากผู้ใช้ก็ได้
      );

      // ✅ เรียกผ่าน Provider
      Provider.of<AppointmentProvider>(context, listen: false)
          .addAppointment(newAppointment);

      // ✅ ปิดหน้าจอ
      Navigator.pop(context);
    }
  }

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เพิ่มการนัดหมาย'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'ชื่อหมอ/คลินิก'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกหัวข้อ';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'รายละเอียด'),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    _selectedDate == null
                        ? 'ยังไม่เลือกวันที่'
                        : 'วันที่: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: _presentDatePicker,
                    child: Text('เลือกวันที่'),
                  )
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('บันทึก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
