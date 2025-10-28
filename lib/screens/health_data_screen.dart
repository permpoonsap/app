import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../provider/health_profile_provider.dart';
import '../model/health_profile.dart';

class HealthDataScreen extends StatefulWidget {
  const HealthDataScreen({super.key});

  @override
  _HealthDataScreenState createState() => _HealthDataScreenState();
}

class _HealthDataScreenState extends State<HealthDataScreen> {
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    // Load health profile when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HealthProfileProvider>(context, listen: false)
          .loadHealthProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'ข้อมูลสุขภาพ',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal[600],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.sync, color: Colors.white),
            onPressed: () => _syncHealthData(context),
            tooltip: 'ซิงค์ข้อมูลกับ Cloud',
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            onPressed: () => _showEditHealthProfileDialog(context),
            tooltip: 'แก้ไขข้อมูลสุขภาพ',
          ),
        ],
      ),
      body: Consumer<HealthProfileProvider>(
        builder: (context, healthProvider, child) {
          final healthProfile = healthProvider.healthProfile;
          final healthSummary = healthProvider.getHealthSummary();

          return Column(
            children: [
              // แท็บเลือกหมวดหมู่
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton('ข้อมูลพื้นฐาน', 0),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildTabButton('การประเมิน', 1),
                    ),
                  ],
                ),
              ),

              // เนื้อหาตามแท็บที่เลือก
              Expanded(
                child: selectedTab == 0
                    ? _buildBasicHealthData(healthProfile, healthSummary)
                    : _buildHealthAssessment(healthProfile, healthSummary),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditHealthProfileDialog(context),
        backgroundColor: Colors.teal[600],
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'เพิ่มข้อมูลสุขภาพ',
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    bool isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal[600] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBasicHealthData(
      HealthProfile? healthProfile, Map<String, dynamic> healthSummary) {
    if (healthProfile == null) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildHealthCard(
            'ส่วนสูง',
            healthProfile.height != null
                ? '${healthProfile.height} ซม.'
                : 'ไม่ระบุ',
            Icons.height,
            Colors.blue,
            null,
          ),
          _buildHealthCard(
            'น้ำหนักตัว',
            healthProfile.weight != null
                ? '${healthProfile.weight} กก.'
                : 'ไม่ระบุ',
            Icons.monitor_weight,
            Colors.green,
            null,
          ),
          _buildHealthCard(
            'รอบเอว',
            healthProfile.waistCircumference != null
                ? '${healthProfile.waistCircumference} ซม.'
                : 'ไม่ระบุ',
            Icons.straighten,
            Colors.orange,
            null,
          ),
          _buildHealthCard(
            'หมู่เลือด',
            healthProfile.bloodType ?? 'ไม่ระบุ',
            Icons.bloodtype,
            Colors.red,
            null,
          ),
          _buildHealthCard(
            'ความดันโลหิตบน',
            healthProfile.systolicBloodPressure != null
                ? '${healthProfile.systolicBloodPressure} mmHg'
                : 'ไม่ระบุ',
            Icons.favorite,
            Colors.purple,
            null,
          ),
          _buildHealthCard(
            'ความดันโลหิตล่าง',
            healthProfile.diastolicBloodPressure != null
                ? '${healthProfile.diastolicBloodPressure} mmHg'
                : 'ไม่ระบุ',
            Icons.favorite,
            Colors.purple,
            null,
          ),
          _buildHealthCard(
            'ระดับน้ำตาลในเลือด',
            healthProfile.bloodSugarLevel != null
                ? '${healthProfile.bloodSugarLevel} mg/dL'
                : 'ไม่ระบุ',
            Icons.water_drop,
            Colors.cyan,
            healthSummary['bloodSugarStatus'],
          ),
          _buildListCard(
            'โรคประจำตัว',
            healthProfile.chronicDiseases,
            Icons.medical_services,
            Colors.red[300]!,
          ),
          _buildListCard(
            'ประวัติแพ้ยา',
            healthProfile.drugAllergies,
            Icons.warning,
            Colors.orange[300]!,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthAssessment(
      HealthProfile? healthProfile, Map<String, dynamic> healthSummary) {
    if (healthProfile == null) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildAssessmentCard(
            'ดัชนีมวลกาย (BMI)',
            healthSummary['bmi'] != null
                ? '${healthSummary['bmi']!.toStringAsFixed(1)}'
                : 'ไม่สามารถคำนวณได้',
            Icons.calculate,
            Colors.indigo,
            healthSummary['bmiStatus'],
            _getBMIDescription(healthSummary['bmi']),
          ),
          _buildAssessmentCard(
            'สถานะความดันโลหิต',
            healthSummary['bloodPressureStatus'] ?? 'ไม่สามารถประเมินได้',
            Icons.favorite,
            Colors.red,
            healthSummary['bloodPressureStatus'],
            _getBloodPressureDescription(healthSummary['bloodPressureStatus']),
          ),
          _buildAssessmentCard(
            'สถานะน้ำตาลในเลือด',
            healthSummary['bloodSugarStatus'] ?? 'ไม่สามารถประเมินได้',
            Icons.water_drop,
            Colors.cyan,
            healthSummary['bloodSugarStatus'],
            _getBloodSugarDescription(healthSummary['bloodSugarStatus']),
          ),
          _buildLastUpdatedCard(healthProfile.updatedAt),
          Consumer<HealthProfileProvider>(
            builder: (context, provider, child) {
              return _buildCloudStatusCard(provider);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.health_and_safety,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'ยังไม่มีข้อมูลสุขภาพ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'กดปุ่ม + เพื่อเพิ่มข้อมูลสุขภาพ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(
      String title, String value, IconData icon, Color color, String? status) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 18, color: color, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (status != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                status,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListCard(
      String title, List<String> items, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 32),
              SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'ไม่ระบุ',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic),
            )
          else
            ...items
                .map((item) => Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.fiber_manual_record,
                              size: 8, color: color),
                          SizedBox(width: 8),
                          Expanded(
                              child:
                                  Text(item, style: TextStyle(fontSize: 14))),
                        ],
                      ),
                    ))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard(String title, String value, IconData icon,
      Color color, String? status, String? description) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                          fontSize: 18,
                          color: color,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (status != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          if (description != null) ...[
            SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLastUpdatedCard(DateTime updatedAt) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.update, color: Colors.grey[600], size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'อัปเดตล่าสุด',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(updatedAt),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudStatusCard(HealthProfileProvider healthProvider) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
              Icon(Icons.cloud, color: Colors.blue[600], size: 24),
              SizedBox(width: 12),
              Text(
                'สถานะ Cloud',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: () => _syncHealthData(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sync, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'ซิงค์',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          FutureBuilder<bool>(
            future: healthProvider.needsSync(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'กำลังตรวจสอบ...',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                );
              }

              final needsSync = snapshot.data ?? false;
              return Row(
                children: [
                  Icon(
                    needsSync ? Icons.sync_problem : Icons.cloud_done,
                    color: needsSync ? Colors.orange[600] : Colors.green[600],
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      needsSync
                          ? 'ข้อมูลในเครื่องใหม่กว่า Cloud'
                          : 'ข้อมูลซิงค์กับ Cloud แล้ว',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            needsSync ? Colors.orange[700] : Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 8),
          Text(
            'ข้อมูลจะถูกบันทึกทั้งในเครื่องและ Cloud เพื่อความปลอดภัย',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ปกติ':
      case 'น้ำหนักปกติ':
        return Colors.green;
      case 'ปกติสูง':
      case 'น้ำหนักเกิน':
        return Colors.orange;
      case 'ความดันโลหิตสูงระดับ 1':
      case 'เสี่ยงเบาหวาน':
        return Colors.red[300]!;
      case 'ความดันโลหิตสูงระดับ 2':
      case 'เบาหวาน':
      case 'อ้วน':
        return Colors.red;
      case 'น้ำหนักต่ำกว่าเกณฑ์':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String? _getBMIDescription(double? bmi) {
    if (bmi == null) return null;
    if (bmi < 18.5) return 'น้ำหนักต่ำกว่าเกณฑ์มาตรฐาน ควรปรึกษาแพทย์';
    if (bmi < 25) return 'น้ำหนักอยู่ในเกณฑ์ปกติ';
    if (bmi < 30) return 'น้ำหนักเกิน ควรควบคุมอาหารและออกกำลังกาย';
    return 'อ้วน ควรปรึกษาแพทย์เพื่อวางแผนลดน้ำหนัก';
  }

  String? _getBloodPressureDescription(String? status) {
    switch (status) {
      case 'ปกติ':
        return 'ความดันโลหิตอยู่ในเกณฑ์ปกติ';
      case 'ปกติสูง':
        return 'ความดันโลหิตสูงกว่าปกติเล็กน้อย ควรติดตาม';
      case 'ความดันโลหิตสูงระดับ 1':
        return 'ความดันโลหิตสูง ควรปรึกษาแพทย์';
      case 'ความดันโลหิตสูงระดับ 2':
        return 'ความดันโลหิตสูงมาก ควรปรึกษาแพทย์ทันที';
      default:
        return null;
    }
  }

  String? _getBloodSugarDescription(String? status) {
    switch (status) {
      case 'ปกติ':
        return 'ระดับน้ำตาลในเลือดปกติ';
      case 'เสี่ยงเบาหวาน':
        return 'ระดับน้ำตาลในเลือดสูง ควรปรึกษาแพทย์';
      case 'เบาหวาน':
        return 'ระดับน้ำตาลในเลือดสูงมาก ควรปรึกษาแพทย์ทันที';
      default:
        return null;
    }
  }

  void _showEditHealthProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditHealthProfileDialog(),
    );
  }

  void _syncHealthData(BuildContext context) async {
    final healthProvider =
        Provider.of<HealthProfileProvider>(context, listen: false);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('กำลังซิงค์ข้อมูล'),
          ],
        ),
      ),
    );

    try {
      final needsSync = await healthProvider.needsSync();
      if (needsSync) {
        await healthProvider.syncToFirestore();
      } else {
        await healthProvider.syncFromFirestore();
      }
      if (context.mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ซิงค์ข้อมูลสำเร็จ'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'ไม่สามารถซิงค์ข้อมูลได้: กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class EditHealthProfileDialog extends StatefulWidget {
  @override
  _EditHealthProfileDialogState createState() =>
      _EditHealthProfileDialogState();
}

class _EditHealthProfileDialogState extends State<EditHealthProfileDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _bloodSugarController = TextEditingController();
  final TextEditingController _chronicDiseasesController =
      TextEditingController();
  final TextEditingController _drugAllergiesController =
      TextEditingController();
  final TextEditingController _bloodTypeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final healthProvider =
        Provider.of<HealthProfileProvider>(context, listen: false);
    final profile = healthProvider.healthProfile;

    if (profile != null) {
      _heightController.text = profile.height?.toString() ?? '';
      _weightController.text = profile.weight?.toString() ?? '';
      _waistController.text = profile.waistCircumference?.toString() ?? '';
      _systolicController.text =
          profile.systolicBloodPressure?.toString() ?? '';
      _diastolicController.text =
          profile.diastolicBloodPressure?.toString() ?? '';
      _bloodSugarController.text = profile.bloodSugarLevel?.toString() ?? '';
      _bloodTypeController.text = profile.bloodType ?? '';
      _chronicDiseasesController.text = profile.chronicDiseases.join(', ');
      _drugAllergiesController.text = profile.drugAllergies.join(', ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal[600],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'แก้ไขข้อมูลสุขภาพ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _heightController,
                        label: 'ส่วนสูง (ซม.)',
                        icon: Icons.height,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: _weightController,
                        label: 'น้ำหนักตัว (กก.)',
                        icon: Icons.monitor_weight,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: _waistController,
                        label: 'รอบเอว (ซม.)',
                        icon: Icons.straighten,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16),
                      _buildBloodPressureFields(),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: _bloodSugarController,
                        label: 'ระดับน้ำตาลในเลือด (mg/dL)',
                        icon: Icons.water_drop,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: _bloodTypeController,
                        label: 'หมู่เลือด',
                        icon: Icons.bloodtype,
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: _chronicDiseasesController,
                        label:
                            'โรคประจำตัว (กรอกแยกด้วยจุลภาค เช่น เบาหวาน, ความดันโลหิตสูง)',
                        icon: Icons.medical_services,
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: _drugAllergiesController,
                        label:
                            'ประวัติแพ้ยา (กรอกแยกด้วยจุลภาค เช่น เพนิซิลลิน, แอสไพริน)',
                        icon: Icons.warning,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('ยกเลิก'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveHealthProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[600],
                        foregroundColor: Colors.white,
                      ),
                      child: Text('บันทึก'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildBloodPressureFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _systolicController,
          label: 'ความดันโลหิตบน',
          icon: Icons.favorite,
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _diastolicController,
          label: 'ความดันโลหิตล่าง',
          icon: Icons.favorite,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  void _saveHealthProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final healthProvider =
          Provider.of<HealthProfileProvider>(context, listen: false);
      final existingProfile = healthProvider.healthProfile;

      // แปลงข้อมูลจากช่องพิมพ์เป็น List โดยแยกด้วยจุลภาค
      List<String> chronicDiseasesList = _chronicDiseasesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      List<String> drugAllergiesList = _drugAllergiesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final profile = HealthProfile(
        id: existingProfile?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: existingProfile?.userId ?? healthProvider.currentUserId ?? '',
        height: double.tryParse(_heightController.text),
        weight: double.tryParse(_weightController.text),
        waistCircumference: double.tryParse(_waistController.text),
        chronicDiseases: chronicDiseasesList,
        bloodType: _bloodTypeController.text.isNotEmpty
            ? _bloodTypeController.text
            : null,
        systolicBloodPressure: int.tryParse(_systolicController.text),
        diastolicBloodPressure: int.tryParse(_diastolicController.text),
        drugAllergies: drugAllergiesList,
        bloodSugarLevel: double.tryParse(_bloodSugarController.text),
        createdAt: existingProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (existingProfile != null) {
        await healthProvider.updateHealthProfile(profile);
      } else {
        await healthProvider.saveHealthProfile(profile);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกข้อมูลสุขภาพสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _waistController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _bloodSugarController.dispose();
    _chronicDiseasesController.dispose();
    _drugAllergiesController.dispose();
    _bloodTypeController.dispose();
    super.dispose();
  }
}
