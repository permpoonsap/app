import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/exercise_log_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final String name;
  final String image;
  final String reps;
  final String videoUrl;
  final String muscle;

  const ExerciseDetailScreen({
    Key? key,
    required this.name,
    required this.image,
    required this.reps,
    required this.videoUrl,
    required this.muscle,
  }) : super(key: key);

  void _launchVideo(BuildContext context) async {
    final uri = Uri.parse(Uri.encodeFull(videoUrl));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเปิดวิดีโอได้')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFFC107),
        title: Text(name),
        leading: BackButton(color: Colors.black),
      ),
      backgroundColor: Color(0xFFFFF3CD),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(image, height: 180),
            SizedBox(height: 24),
            Text(
              name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'จำนวนครั้งที่แนะนำ: $reps ครั้ง',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            Text(
              'กล้ามเนื้อที่ได้ประโยชน์: $muscle',
              style: TextStyle(fontSize: 18, color: Colors.deepPurple),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _launchVideo(context),
              icon: Icon(Icons.play_circle_fill),
              label: Text('ดูวิดีโอสอน'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await Provider.of<ExerciseLogProvider>(context, listen: false)
                      .addLog(name);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('บันทึกกิจกรรมเรียบร้อย!')),
                  );
                  Navigator.pop(context);
                },
                child: Text('บันทึกกิจกรรม'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
