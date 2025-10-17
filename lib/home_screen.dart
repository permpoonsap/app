import 'package:elderly_health_app/Appointment/appointmentScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:url_launcher/url_launcher.dart';

import 'screens/daily_goals_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = "กำลังโหลด...";
  late Stream<DocumentSnapshot> _userStream;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> _callEmergencyContact() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ContextUtils.showErrorSnackBar(context, 'กรุณาเข้าสู่ระบบก่อนใช้งาน');
        }
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!doc.exists) {
        if (mounted) {
          ContextUtils.showWarningSnackBar(context, 'ยังไม่มีข้อมูลผู้ใช้');
        }
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final String? rawPhone = (data['emergencyPhone'] as String?)?.trim();
      if (rawPhone == null || rawPhone.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('กรุณาเพิ่มเบอร์ติดต่อฉุกเฉินก่อน'),
              action: SnackBarAction(
                label: 'เพิ่มตอนนี้',
                onPressed: _navigateToProfile,
              ),
            ),
          );
        }
        return;
      }

      // Show bottom sheet with contact info and actions
      if (mounted) {
        _showEmergencyContactSheet(
          name:
              (data['emergencyName'] as String?)?.trim() ?? 'ผู้ติดต่อฉุกเฉิน',
          phone: rawPhone,
        );
      }
    } catch (e) {
      if (mounted) {
        ContextUtils.showErrorSnackBar(context, 'เกิดข้อผิดพลาด: $e');
      }
    }
  }

  void _showEmergencyContactSheet(
      {required String name, required String phone}) {
    final String phoneNormalized = phone.replaceAll(RegExp(r'\s+'), '');
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.support_agent, color: Colors.red),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ติดต่อฉุกเฉิน',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('ชื่อผู้ติดต่อ: ' + name,
                              style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.phone, color: Colors.grey[700]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          phoneNormalized,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, size: 20),
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: phoneNormalized));
                          if (mounted) {
                            ContextUtils.showSuccessSnackBar(
                                context, 'คัดลอกหมายเลขแล้ว');
                          }
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () async {
                          final uri = Uri(scheme: 'tel', path: phoneNormalized);
                          final can = await canLaunchUrl(uri);
                          if (can) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          } else if (mounted) {
                            ContextUtils.showWarningSnackBar(
                                context, 'อุปกรณ์นี้ไม่รองรับการเปิดแอปโทร');
                          }
                        },
                        icon: Icon(Icons.call, color: Colors.white),
                        label: Text('โทรหา ' + name,
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close),
                        label: Text('ปิด'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
    _searchController.dispose();
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
                        ],
                      ),
                    ),
                  ),
                ),

                // Search Bar
                Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
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
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
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
                Builder(builder: (context) {
                  final List<Map<String, dynamic>> items = [
                    {
                      'title': 'เตือนกินยา',
                      'subtitle': 'จัดการยาประจำวัน',
                      'icon': Icons.medication_liquid,
                      'color': Color(0xFF4A90E2),
                      'onTap': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MedicineReminderScreen(),
                          ),
                        );
                      }
                    },
                    {
                      'title': 'นัดพบแพทย์',
                      'subtitle': 'จัดการการนัดหมาย',
                      'icon': Icons.local_hospital,
                      'color': Color(0xFF7B68EE),
                      'onTap': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentScreen(),
                          ),
                        );
                      }
                    },
                    {
                      'title': 'เป้าหมายประจำวัน',
                      'subtitle': 'ตั้งเป้าหมายสุขภาพ',
                      'icon': Icons.track_changes,
                      'color': Color(0xFF32CD32),
                      'onTap': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DailyGoalsScreen(),
                          ),
                        );
                      }
                    },
                    {
                      'title': 'ขอความช่วยเหลือ',
                      'subtitle': 'ติดต่อญาติใกล้ตัว',
                      'icon': Icons.support_agent,
                      'color': Color(0xFFFF6B6B),
                      'onTap': () {
                        _callEmergencyContact();
                      }
                    },
                    {
                      'title': 'ออกกำลังกาย',
                      'subtitle': 'ท่าออกกำลังกาย',
                      'icon': Icons.directions_walk,
                      'color': Color(0xFFFF8C00),
                      'onTap': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ExerciseListScreen()),
                        );
                      }
                    },
                    {
                      'title': 'เกมฝึกสมอง',
                      'subtitle': 'ฝึกความจำและสมาธิ',
                      'icon': Icons.psychology_alt,
                      'color': Color(0xFF9370DB),
                      'onTap': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BrainGameScreen(),
                          ),
                        );
                      }
                    },
                    {
                      'title': 'สรุปรายวัน',
                      'subtitle': 'ดูสรุปกิจกรรม',
                      'icon': Icons.assessment,
                      'color': Color(0xFF20B2AA),
                      'onTap': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DailySummaryScreen(),
                          ),
                        );
                      }
                    },
                    {
                      'title': 'ข้อมูลสุขภาพ',
                      'subtitle': 'ตรวจสอบสุขภาพ',
                      'icon': Icons.favorite,
                      'color': Color(0xFFE91E63),
                      'onTap': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HealthDataScreen(),
                          ),
                        );
                      }
                    },
                  ];

                  final normalized = _searchQuery;
                  final filtered = normalized.isEmpty
                      ? items
                      : items.where((item) {
                          final title = (item['title'] as String).toLowerCase();
                          final subtitle =
                              (item['subtitle'] as String).toLowerCase();
                          return title.contains(normalized) ||
                              subtitle.contains(normalized);
                        }).toList();

                  return GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                    children: filtered
                        .map((item) => _buildEnhancedMenuTile(
                              context,
                              item['title'] as String,
                              item['icon'] as IconData,
                              item['color'] as Color,
                              item['subtitle'] as String,
                              item['onTap'] as VoidCallback,
                            ))
                        .toList(),
                  );
                }),
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
