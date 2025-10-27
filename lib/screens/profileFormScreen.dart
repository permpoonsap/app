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
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          nameController.text = data['name'] ?? '';
          dobController.text = data['birthday'] ?? '';
          ageController.text = data['age'] ?? '';
          genderController.text = data['gender'] ?? '';
          phoneController.text = data['phone'] ?? '';
          emergencyNameController.text = data['emergencyName'] ?? '';
          emergencyPhoneController.text = data['emergencyPhone'] ?? '';
          emergencyEmailController.text = data['emergencyEmail'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // แสดง loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('กำลังบันทึกข้อมูล...'),
            ],
          ),
        ),
      );

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
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ปิด loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกข้อมูลสำเร็จ'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving profile: $e');

      // ปิด loading dialog ถ้ายังเปิดอยู่
      if (context.mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // **** ฟังก์ชันใหม่สำหรับ DatePicker ****
  Future<void> _selectDate(BuildContext context) async {
    try {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now()
            .subtract(Duration(days: 365 * 65)), // เริ่มที่อายุ 65 ปี
        firstDate: DateTime(1900), // วันที่เริ่มต้นที่เลือกได้
        lastDate: DateTime.now(), // วันที่สิ้นสุดที่เลือกได้ (วันนี้)
        helpText: 'เลือกวันเกิด', // ข้อความด้านบนของ DatePicker
        cancelText: 'ยกเลิก',
        confirmText: 'ยืนยัน',
        builder: (BuildContext context, Widget? child) {
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

      if (pickedDate != null && pickedDate != DateTime.now()) {
        // ตรวจสอบว่าเลือกวันที่แล้วและไม่ใช่ null
        setState(() {
          dobController.text =
              DateFormat('dd/MM/yyyy').format(pickedDate); // กำหนดรูปแบบวันที่

          // คำนวณอายุอัตโนมัติ
          final now = DateTime.now();
          final age = now.year - pickedDate.year;
          final monthDiff = now.month - pickedDate.month;
          final dayDiff = now.day - pickedDate.day;

          int calculatedAge = age;
          if (monthDiff < 0 || (monthDiff == 0 && dayDiff < 0)) {
            calculatedAge = age - 1;
          }

          ageController.text = calculatedAge.toString();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.teal[600],
        elevation: 0,
        title: Text(
          "ข้อมูลส่วนตัว",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ข้อมูลส่วนตัว
              _buildSectionHeader('ข้อมูลส่วนตัว', Icons.person),
              SizedBox(height: 16),
              _buildField("ชื่อ - นามสกุล", nameController, Icons.person),
              _buildDateField("วันเดือนปีเกิด", dobController),
              _buildField("อายุ", ageController, Icons.cake),
              _buildField("เพศ", genderController, Icons.wc),
              _buildField("เบอร์โทรศัพท์", phoneController, Icons.phone),

              SizedBox(height: 32),

              // ข้อมูลผู้ติดต่อฉุกเฉิน
              _buildSectionHeader('ข้อมูลผู้ติดต่อฉุกเฉิน', Icons.emergency),
              SizedBox(height: 16),
              _buildField("ชื่อญาติ/ผู้ดูแล", emergencyNameController,
                  Icons.person_outline),
              _buildField("เบอร์ฉุกเฉิน", emergencyPhoneController,
                  Icons.phone_android),
              _buildField(
                  "อีเมลของญาติ", emergencyEmailController, Icons.email),

              SizedBox(height: 32),

              // ปุ่มบันทึก
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: Icon(Icons.save, size: 24),
                  label: Text(
                    "บันทึกข้อมูล",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal[700],
              ),
              prefixIcon: Icon(
                icon,
                color: Colors.teal[600],
                size: 28,
              ),
              filled: true,
              fillColor: Colors.teal[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal[300]!, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal[300]!, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal[600]!, width: 3),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            ),
            validator: (value) {
              // ไม่บังคับให้กรอกข้อมูลทั้งหมด ยกเว้นชื่อ-นามสกุล
              if (label.contains('ชื่อ - นามสกุล') &&
                  (value == null || value.isEmpty)) {
                return 'กรุณากรอกชื่อ-นามสกุล';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            readOnly: true,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            onTap: () => _selectDate(context),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal[700],
              ),
              prefixIcon: Icon(
                Icons.calendar_today,
                color: Colors.teal[600],
                size: 28,
              ),
              suffixIcon: Icon(
                Icons.edit_calendar_outlined,
                color: Colors.teal[600],
                size: 24,
              ),
              filled: true,
              fillColor: Colors.teal[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal[300]!, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal[300]!, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal[600]!, width: 3),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            ),
            validator: (value) {
              // ไม่บังคับให้กรอกข้อมูลทั้งหมด ยกเว้นชื่อ-นามสกุล
              if (label.contains('ชื่อ - นามสกุล') &&
                  (value == null || value.isEmpty)) {
                return 'กรุณากรอกชื่อ-นามสกุล';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.teal[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal[700], size: 24),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
        ],
      ),
    );
  }
}
