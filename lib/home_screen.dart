import 'package:elderly_health_app/Appointment/appointmentScreen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'screens/daily_summary_screen.dart';
import 'screens/health_data_screen.dart';
import 'medicine_reminder/medicine_reminder_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/ProfileFormScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';
import 'utils/context_utils.dart';
import 'exercise/exercise_screen.dart';
import 'brain_game/brain_game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = "กำลังโหลด...";
  late Stream<DocumentSnapshot> _userStream;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _listenToUserChanges();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _userName =
              (doc.data() as Map<String, dynamic>)['name'] ?? 'ผู้ใช้งาน';
        });
      } else if (mounted) {
        setState(() {
          _userName = 'ผู้ใช้งาน';
        });
      }
    } else if (mounted) {
      setState(() {
        _userName = 'ผู้ใช้งาน';
      });
    }
  }

  void _listenToUserChanges() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();
      _userSubscription = _userStream.listen((snapshot) {
        if (snapshot.exists && mounted) {
          setState(() {
            _userName = (snapshot.data() as Map<String, dynamic>)['name'] ??
                'ผู้ใช้งาน';
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<void> _navigateToProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileFormScreen()),
    );
    if (mounted) {
      _loadUserName();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Color(0xFF2E7D5F),
          elevation: 2,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(Icons.menu, color: Colors.white, size: 28),
          ),
          title: Text(
            'หน้าหลัก',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white, size: 28),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("ออกจากระบบ"),
                    content: Text("คุณต้องการออกจากระบบหรือไม่?"),
                    actions: [
                      TextButton(
                        child: Text("ยกเลิก"),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () async {
                          // บันทึก context ก่อน
                          final navigator = Navigator.of(context);

                          navigator.pop();
                          try {
                            await AuthService.signOut(context);
                            if (context.mounted) {
                              ContextUtils.showWarningSnackBar(
                                  context, 'ออกจากระบบแล้ว');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ContextUtils.showErrorSnackBar(
                                  context, 'เกิดข้อผิดพลาด: $e');
                            }
                          }
                        },
                        child: Text("ออกจากระบบ"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Section - Now clickable
                Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _navigateToProfile,
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Color(0xFF2E7D5F),
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: Color(0xFFE8F5E8),
                              child: Icon(
                                Icons.account_circle,
                                size: 48,
                                color: Color(0xFF2E7D5F),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'สวัสดี',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _userName,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D5F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Edit Profile Indicator
                          Container(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.edit,
                              color: Colors.grey[500],
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Search Bar
                Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: TextField(
                    style: TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'ค้นหาฟังก์ชันที่ต้องการ...',
                      hintStyle:
                          TextStyle(fontSize: 14, color: Colors.grey[500]),
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.search,
                            size: 20, color: Colors.grey[600]),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Color(0xFF2E7D5F), width: 2),
                      ),
                    ),
                  ),
                ),

                // Menu Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                  children: [
                    _buildEnhancedMenuTile(
                      context,
                      'เตือนกินยา',
                      Icons.medication_liquid,
                      Color(0xFF4A90E2),
                      'จัดการยาประจำวัน',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MedicineReminderScreen(),
                          ),
                        );
                      },
                    ),
                    _buildEnhancedMenuTile(
                      context,
                      'นัดพบแพทย์',
                      Icons.local_hospital,
                      Color(0xFF7B68EE),
                      'จัดการการนัดหมาย',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentScreen(),
                          ),
                        );
                      },
                    ),
                    _buildEnhancedMenuTile(
                      context,
                      'เป้าหมายประจำวัน',
                      Icons.track_changes,
                      Color(0xFF32CD32),
                      'ตั้งเป้าหมายสุขภาพ',
                      () {
                        //
                      },
                    ),
                    _buildEnhancedMenuTile(
                      context,
                      'ขอความช่วยเหลือ',
                      Icons.support_agent,
                      Color(0xFFFF6B6B),
                      'ติดต่อเจ้าหน้าที่',
                      () {
                        // TODO: ไปยังหน้าขอความช่วยเหลือ
                      },
                    ),
                    _buildEnhancedMenuTile(
                      context,
                      'ออกกำลังกาย',
                      Icons.directions_walk,
                      Color(0xFFFF8C00),
                      'ท่าออกกำลังกาย',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ExerciseListScreen()),
                        );
                      },
                    ),
                    _buildEnhancedMenuTile(
                      context,
                      'เกมฝึกสมอง',
                      Icons.psychology_alt,
                      Color(0xFF9370DB),
                      'ฝึกความจำและสมาธิ',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BrainGameScreen(),
                          ),
                        );
                      },
                    ),
                    _buildEnhancedMenuTile(
                      context,
                      'สรุปรายวัน',
                      Icons.assessment,
                      Color(0xFF20B2AA),
                      'ดูสรุปกิจกรรม',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DailySummaryScreen(),
                          ),
                        );
                      },
                    ),
                    _buildEnhancedMenuTile(
                      context,
                      'ข้อมูลสุขภาพ',
                      Icons.favorite,
                      Color(0xFFE91E63),
                      'ตรวจสอบสุขภาพ',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HealthDataScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }
}

Widget _buildEnhancedMenuTile(
  BuildContext context,
  String title,
  IconData icon,
  Color color,
  String subtitle,
  VoidCallback onTap,
) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[200]!, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          spreadRadius: 0,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
