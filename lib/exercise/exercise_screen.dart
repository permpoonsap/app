import 'package:flutter/material.dart';
import 'exercise_detail_screen.dart';

class ExerciseListScreen extends StatelessWidget {
  final List<Map<String, String>> exercises = [
    {
      'name': 'ลุกนั่งกับเก้าอี้',
      'image': 'assets/images/squat.png',
      'reps': '15',
      'video': 'https://www.youtube.com/watch?v=pPg9tZz1jbM&t=215s',
      'muscle': 'สะโพก/ต้นขาด้านหน้า',
    },
    {
      'name': 'ยื่นย่ำเท้า',
      'image': 'assets/images/leg_lift.png',
      'reps': '12',
      'video': 'https://www.youtube.com/watch?v=pPg9tZz1jbM&t=57s',
      'muscle': 'น่องขา',
    },
    {
      'name': 'ยืดกล้ามเนื้อหัวไหล่',
      'image': 'assets/images/shoulder_stretch.png',
      'reps': '10',
      'video': 'https://www.youtube.com/watch?v=pPg9tZz1jbM&t=801s',
      'muscle': 'หัวไหล่',
    },
    {
      'name': 'ไขว้ขา',
      'image': 'assets/images/leg_cross.png',
      'reps': '10',
      'video': 'https://www.youtube.com/watch?v=pPg9tZz1jbM&t=870s',
      'muscle': 'สะโพก/ต้นขา/หลังส่วนล่าง',
    },
    {
      'name': 'ชูแขนเหนือศีรษะ',
      'image': 'assets/images/arm_stretch.png',
      'reps': '10',
      'video': 'https://www.youtube.com/watch?v=pPg9tZz1jbM&t=7m44s',
      'muscle': 'ลำตัวด้านข้าง/ต้นแขน/หัวไหล่',
    },
    {
      'name': 'ยกขา3ทิศ',
      'image': 'assets/images/side_stretch.png',
      'reps': '10',
      'video': 'https://www.youtube.com/watch?v=pPg9tZz1jbM&t=568s',
      'muscle': 'สะโพก/ต้นขา หน้า-หลัง/หลังส่วนล่าง/หน้าท้องส่วนล่าง',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF3CD), // พื้นหลังสีเหลืองอ่อน
      appBar: AppBar(
        backgroundColor: Color(0xFFFFC107), // สีเหลืองเข้ม
        title: Text("ท่าออกกำลังกาย"),
        leading: BackButton(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.filter_alt_outlined),
                hintText: 'ค้นหาท่าออกกำลังกาย...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 3 / 4, // อัตราส่วนของแต่ละ Grid Item
              children: exercises.map((exercise) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExerciseDetailScreen(
                          name: exercise['name']!,
                          image: exercise['image']!,
                          reps: exercise['reps']!,
                          videoUrl: exercise['video']!,
                          muscle: exercise['muscle']!,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF4CAF50), // สีเขียว
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ใช้ Expanded กับ Image เพื่อให้ภาพขยายเต็มพื้นที่ที่เหลือ
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(
                                8.0), // เพิ่ม padding รอบรูปภาพ
                            child: Image.asset(
                              exercise['image']!,
                              fit: BoxFit
                                  .contain, // จะทำให้ภาพปรับขนาดให้พอดีโดยรักษาสัดส่วนเดิม
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0), // เพิ่ม padding ให้ Text
                          child: Text(
                            exercise['name']!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2, // จำกัดจำนวนบรรทัดของชื่อท่า
                            overflow: TextOverflow
                                .ellipsis, // ถ้าข้อความยาวเกินให้แสดง ...
                          ),
                        ),
                        SizedBox(height: 12), // เพิ่มระยะห่างด้านล่างของชื่อ
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
