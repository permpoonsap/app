import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/brain_game_provider.dart';

class SequenceGameScreen extends StatefulWidget {
  const SequenceGameScreen({Key? key}) : super(key: key);

  @override
  State<SequenceGameScreen> createState() => _SequenceGameScreenState();
}

class _SequenceGameScreenState extends State<SequenceGameScreen> {
  int currentLevel = 0;
  int score = 0;
  int totalLevels = 0;
  bool gameCompleted = false;
  List<SequenceItem> sequenceItems = [];
  List<SequenceItem> shuffledItems = [];
  List<SequenceItem> userSequence = [];
  bool isProcessing = false;
  List<SequenceLevel> levels = [];

  @override
  void initState() {
    super.initState();
    _generateLevels();
    _startCurrentLevel();
  }

  void _generateLevels() {
    levels = [
      SequenceLevel(
        name: 'ระดับง่าย',
        type: SequenceType.numbers,
        itemCount: 4,
        items: [1, 2, 3, 4],
      ),
      SequenceLevel(
        name: 'ระดับง่าย',
        type: SequenceType.letters,
        itemCount: 4,
        items: ['A', 'B', 'C', 'D'],
      ),
      SequenceLevel(
        name: 'ระดับปานกลาง',
        type: SequenceType.numbers,
        itemCount: 5,
        items: [5, 3, 8, 1, 6],
      ),
      SequenceLevel(
        name: 'ระดับปานกลาง',
        type: SequenceType.colors,
        itemCount: 4,
        items: [Colors.red, Colors.blue, Colors.green, Colors.yellow],
      ),
      SequenceLevel(
        name: 'ระดับยาก',
        type: SequenceType.numbers,
        itemCount: 6,
        items: [12, 5, 18, 3, 9, 15],
      ),
      SequenceLevel(
        name: 'ระดับยาก',
        type: SequenceType.sizes,
        itemCount: 5,
        items: ['S', 'M', 'L', 'XL', 'XXL'],
      ),
    ];
    totalLevels = levels.length;
  }

  void _startCurrentLevel() {
    if (currentLevel >= levels.length) {
      _completeGame();
      return;
    }

    final level = levels[currentLevel];
    sequenceItems = [];
    shuffledItems = [];
    userSequence = [];
    isProcessing = false;

    // สร้างลำดับที่ถูกต้อง
    for (int i = 0; i < level.itemCount; i++) {
      sequenceItems.add(SequenceItem(
        id: i,
        value: level.items[i],
        type: level.type,
        isSelected: false,
      ));
    }

    // สร้างลำดับที่สลับแล้ว
    shuffledItems = List.from(sequenceItems);
    shuffledItems.shuffle(Random());

    setState(() {});
  }

  void _selectItem(SequenceItem item) {
    if (isProcessing || item.isSelected) return;

    setState(() {
      item.isSelected = true;
      userSequence.add(item);
    });

    // ตรวจสอบว่าจบเกมหรือยัง
    if (userSequence.length == sequenceItems.length) {
      _checkSequence();
    }
  }

  void _checkSequence() {
    setState(() {
      isProcessing = true;
    });

    bool isCorrect = true;
    for (int i = 0; i < sequenceItems.length; i++) {
      if (userSequence[i].id != sequenceItems[i].id) {
        isCorrect = false;
        break;
      }
    }

    Future.delayed(Duration(milliseconds: 1500), () {
      if (mounted) {
        if (isCorrect) {
          // ถูกต้อง
          score += 1;
          _levelComplete();
        } else {
          // ผิด
          _resetLevel();
        }
      }
    });
  }

  void _resetLevel() {
    setState(() {
      // รีเซ็ตสถานะการเลือก
      for (var item in shuffledItems) {
        item.isSelected = false;
      }
      userSequence.clear();
      isProcessing = false;
    });
  }

  void _levelComplete() {
    Future.delayed(Duration(milliseconds: 1000), () {
      if (mounted) {
        currentLevel++;
        _startCurrentLevel();
      }
    });
  }

  void _completeGame() {
    setState(() {
      gameCompleted = true;
    });

    // บันทึกผลคะแนน
    final gameProvider = Provider.of<BrainGameProvider>(context, listen: false);
    gameProvider.addGameResult('เกมเรียงลำดับ', score, totalLevels);
  }

  void _restartGame() {
    setState(() {
      currentLevel = 0;
      score = 0;
      gameCompleted = false;
    });
    _startCurrentLevel();
  }

  String _getInstructionText() {
    final level = levels[currentLevel];
    switch (level.type) {
      case SequenceType.numbers:
        return 'เรียงลำดับตัวเลขจากน้อยไปมาก';
      case SequenceType.letters:
        return 'เรียงลำดับตัวอักษรตามลำดับ';
      case SequenceType.colors:
        return 'เรียงลำดับสีตามที่กำหนด';
      case SequenceType.sizes:
        return 'เรียงลำดับขนาดจากเล็กไปใหญ่';
    }
  }

  Widget _buildSequenceItem(SequenceItem item) {
    return GestureDetector(
      onTap: () => _selectItem(item),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 70,
        height: 70,
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: item.isSelected
              ? Color(0xFF9C27B0).withOpacity(0.3)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isSelected ? Color(0xFF9C27B0) : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: _buildItemContent(item),
        ),
      ),
    );
  }

  Widget _buildItemContent(SequenceItem item) {
    switch (item.type) {
      case SequenceType.numbers:
      case SequenceType.letters:
      case SequenceType.sizes:
        return Text(
          item.value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        );
      case SequenceType.colors:
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: item.value as Color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey[400]!,
              width: 2,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (gameCompleted) {
      return _buildResultScreen();
    }

    final level = levels[currentLevel];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF9C27B0),
        title: Text(
          'เกมเรียงลำดับ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
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
            children: [
              // Progress Bar
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          level.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          'คะแนน: $score',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9C27B0),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ระดับ ${currentLevel + 1} จาก ${levels.length}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (currentLevel + 1) / levels.length,
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Instructions
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF9C27B0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xFF9C27B0),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF9C27B0),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getInstructionText(),
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF2D3748),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'แตะเพื่อเลือกตามลำดับที่ถูกต้อง',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Correct Sequence Display
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'ลำดับที่ถูกต้อง',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: sequenceItems.map((item) {
                          return Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Color(0xFF9C27B0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Color(0xFF9C27B0),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: _buildItemContent(item),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Game Area
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'แตะเพื่อเรียงลำดับ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: shuffledItems.map((item) {
                        return _buildSequenceItem(item);
                      }).toList(),
                    ),
                    if (userSequence.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        'ลำดับที่คุณเลือก',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 4,
                          runSpacing: 4,
                          children: userSequence.map((item) {
                            return Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: Color(0xFF9C27B0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: _buildItemContent(item),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    double percentage = (score / totalLevels) * 100;
    String message;
    Color messageColor;

    if (percentage >= 80) {
      message = 'ยอดเยี่ยม! การคิดเชิงตรรกะของคุณดีมาก';
      messageColor = Color(0xFF9C27B0);
    } else if (percentage >= 60) {
      message = 'ดีมาก! คุณทำได้ดีมาก';
      messageColor = Color(0xFF4CAF50);
    } else {
      message = 'ไม่เป็นไร ลองใหม่อีกครั้ง';
      messageColor = Color(0xFFF44336);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF9C27B0),
        title: Text(
          'ผลการเล่นเกม',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight -
                  32,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Result Card
                Container(
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        percentage >= 80
                            ? Icons.emoji_events
                            : percentage >= 60
                                ? Icons.thumb_up
                                : Icons.sentiment_satisfied,
                        size: 64,
                        color: messageColor,
                      ),
                      SizedBox(height: 24),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: messageColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'คะแนนของคุณ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '$score / $totalLevels',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${percentage.toInt()}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: messageColor,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Color(0xFF2D3748),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'กลับหน้าหลัก',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _restartGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF9C27B0),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'เล่นใหม่',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SequenceItem {
  final int id;
  final dynamic value;
  final SequenceType type;
  bool isSelected;

  SequenceItem({
    required this.id,
    required this.value,
    required this.type,
    required this.isSelected,
  });
}

class SequenceLevel {
  final String name;
  final SequenceType type;
  final int itemCount;
  final List<dynamic> items;

  SequenceLevel({
    required this.name,
    required this.type,
    required this.itemCount,
    required this.items,
  });
}

enum SequenceType {
  numbers,
  letters,
  colors,
  sizes,
}
