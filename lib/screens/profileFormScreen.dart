import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  _ProfileFormScreenState createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emergencyNameController = TextEditingController();
  final TextEditingController emergencyPhoneController =
      TextEditingController();
  final TextEditingController emergencyEmailController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()
          as Map<String, dynamic>; // Cast เพื่อแก้ปัญหา The operator '[]'
      nameController.text = data['name'] ?? '';
      dobController.text = data['birthday'] ?? '';
      ageController.text = data['age'] ?? '';
      genderController.text = data['gender'] ?? '';
      phoneController.text = data['phone'] ?? '';
      emergencyNameController.text = data['emergencyName'] ?? '';
      emergencyPhoneController.text = data['emergencyPhone'] ?? '';
      emergencyEmailController.text = data['emergencyEmail'] ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': nameController.text.trim(),
        'birthday': dobController.text.trim(),
        'dob': FieldValue.delete(), // remove legacy field
        'age': ageController.text.trim(),
        'gender': genderController.text.trim(),
        'phone': phoneController.text.trim(),
        'emergencyName': emergencyNameController.text.trim(),
        'emergencyPhone': emergencyPhoneController.text.trim(),
        'emergencyEmail': emergencyEmailController.text.trim(),
      }, SetOptions(merge: true));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
        );
      }
    }
  }

  // **** ฟังก์ชันใหม่สำหรับ DatePicker ****
  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // วันที่เริ่มต้นในปฏิทิน
      firstDate: DateTime(1900), // วันที่เริ่มต้นที่เลือกได้
      lastDate: DateTime.now(), // วันที่สิ้นสุดที่เลือกได้ (วันนี้)
      helpText: 'เลือกวันเกิด', // ข้อความด้านบนของ DatePicker
      cancelText: 'ยกเลิก',
      confirmText: 'ยืนยัน',
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF2E7D5F), // สีหัว DatePicker
            colorScheme: const ColorScheme.light(
                primary: Color(0xFF2E7D5F)), // สีเลือกวันที่
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != DateTime.now()) {
      // ตรวจสอบว่าเลือกวันที่แล้วและไม่ใช่ null
      setState(() {
        dobController.text =
            DateFormat('dd/MM/yyyy').format(pickedDate); // กำหนดรูปแบบวันที่
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFF2E7D5F),
        title: Text("กรอกข้อมูลโปรไฟล์", style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildField("ชื่อ - นามสกุล", nameController, Icons.person),
              _buildDateField("วันเดือนปีเกิด", dobController),
              _buildField("อายุ", ageController, Icons.cake),
              _buildField("เพศ", genderController, Icons.wc),
              _buildField("เบอร์โทรศัพท์", phoneController, Icons.phone),
              Divider(height: 32, thickness: 1),
              Text("ข้อมูลผู้ติดต่อฉุกเฉิน",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              _buildField(
                  "ชื่อญาติ", emergencyNameController, Icons.person_outline),
              _buildField("เบอร์ฉุกเฉิน", emergencyPhoneController,
                  Icons.phone_android),
              _buildField(
                  "อีเมลของญาติ", emergencyEmailController, Icons.email),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: Icon(Icons.save),
                  label: Text("บันทึกข้อมูล", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2E7D5F),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'กรุณากรอก $label' : null,
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _selectDate(context),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.calendar_today),
          suffixIcon: Icon(Icons.edit_calendar_outlined),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'กรุณากรอก $label' : null,
      ),
    );
  }
}
