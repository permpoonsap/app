import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/appointment_provider.dart';
import '../model/appointment_item.dart';

class AddAppointmentScreen extends StatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  _AddAppointmentScreenState createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  void _submitForm() {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedTime != null) {
      final date = _selectedDate!;
      final time = _selectedTime!;
      final combinedDateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      final newAppointment = AppointmentItem(
        doctorName: _titleController.text,
        reason: _descriptionController.text,
        dateTime: combinedDateTime,
        alertBefore: Duration(minutes: 30), // หรือให้เลือกจากผู้ใช้ก็ได้
      );
      Provider.of<AppointmentProvider>(context, listen: false)
          .addAppointment(newAppointment);
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

  void _presentTimePicker() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
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
              Row(
                children: [
                  Text(
                    _selectedTime == null
                        ? 'ยังไม่เลือกเวลา'
                        : 'เวลา: ${_selectedTime!.format(context)}',
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: _presentTimePicker,
                    child: Text('เลือกเวลา'),
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
