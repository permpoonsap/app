import 'package:flutter/material.dart';
import 'calculation_game_screen.dart';
import 'memory_game_screen.dart';
import 'matching_game_screen.dart';
import 'sequence_game_screen.dart';

class BrainGameScreen extends StatelessWidget {
  const BrainGameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF9370DB),
        title: Text(
          'เกมฝึกสมอง',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF9370DB), Color(0xFF8A2BE2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.psychology_alt,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ฝึกสมองให้แข็งแรง',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'เลือกเกมที่คุณสนใจเพื่อฝึกสมอง',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              Text(
                'เกมที่แนะนำ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),

              SizedBox(height: 16),

              // Games Grid
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  _buildGameCard(
                    context,
                    'เกมคำนวณ',
                    Icons.calculate,
                    Color(0xFF4CAF50),
                    'ฝึกการคำนวณพื้นฐาน',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CalculationGameScreen(),
                        ),
                      );
                    },
                  ),
                  _buildGameCard(
                    context,
                    'เกมความจำ',
                    Icons.memory,
                    Color(0xFF2196F3),
                    'ฝึกความจำและสมาธิ',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MemoryGameScreen(),
                        ),
                      );
                    },
                  ),
                  _buildGameCard(
                    context,
                    'เกมจับคู่',
                    Icons.grid_on,
                    Color(0xFFFF9800),
                    'ฝึกการจับคู่และสังเกต',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchingGameScreen(),
                        ),
                      );
                    },
                  ),
                  _buildGameCard(
                    context,
                    'เกมเรียงลำดับ',
                    Icons.sort,
                    Color(0xFF9C27B0),
                    'ฝึกการเรียงลำดับ',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SequenceGameScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Add some bottom padding to ensure content doesn't get cut off
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String description,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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
}
