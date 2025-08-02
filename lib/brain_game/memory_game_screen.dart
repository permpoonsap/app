import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/brain_game_provider.dart';

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({Key? key}) : super(key: key);

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  int currentQuestionIndex = 0;
  int score = 0;
  bool gameCompleted = false;
  List<MemoryQuestion> questions = [];
  List<int> userSequence = [];
  List<int> correctSequence = [];
  bool isShowingSequence = false;
  bool isWaitingForAnswer = false;
  int currentSequenceIndex = 0;
  Timer? sequenceTimer;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  @override
  void dispose() {
    sequenceTimer?.cancel();
    super.dispose();
  }

  void _generateQuestions() {
    final random = Random();
    questions = [];

    for (int i = 0; i < 5; i++) {
      int sequenceLength = 3 + i; // 3, 4, 5, 6, 7 digits
      List<int> sequence = [];

      for (int j = 0; j < sequenceLength; j++) {
        sequence.add(random.nextInt(9) + 1); // 1-9
      }

      questions.add(MemoryQuestion(
        sequence: sequence,
        options: _generateOptions(sequence, random),
      ));
    }

    _startCurrentQuestion();
  }

  List<List<int>> _generateOptions(List<int> correctSequence, Random random) {
    List<List<int>> options = [correctSequence];

    // สร้างตัวเลือกที่ผิด 3 ตัว
    while (options.length < 4) {
      List<int> wrongSequence = List.from(correctSequence);

      // สุ่มเปลี่ยนตัวเลข 1-2 ตัว
      int changes = random.nextInt(2) + 1;
      for (int i = 0; i < changes; i++) {
        int index = random.nextInt(wrongSequence.length);
        wrongSequence[index] = random.nextInt(9) + 1;
      }

      // ตรวจสอบว่าไม่ซ้ำ
      bool isDuplicate = false;
      for (var option in options) {
        if (listEquals(option, wrongSequence)) {
          isDuplicate = true;
          break;
        }
      }

      if (!isDuplicate) {
        options.add(wrongSequence);
      }
    }

    // สลับตำแหน่งตัวเลือก
    options.shuffle(random);
    return options;
  }

  void _startCurrentQuestion() {
    if (currentQuestionIndex >= questions.length) {
      _completeGame();
      return;
    }

    setState(() {
      isShowingSequence = true;
      isWaitingForAnswer = false;
      currentSequenceIndex = 0;
      correctSequence = List.from(questions[currentQuestionIndex].sequence);
    });

    _showSequence();
  }

  void _showSequence() {
    if (currentSequenceIndex >= correctSequence.length) {
      setState(() {
        isShowingSequence = false;
        isWaitingForAnswer = true;
      });
      return;
    }

    setState(() {
      currentSequenceIndex++;
    });

    sequenceTimer = Timer(Duration(milliseconds: 800), () {
      if (mounted) {
        _showSequence();
      }
    });
  }

  void _selectAnswer(List<int> selectedSequence) {
    if (!isWaitingForAnswer) return;

    setState(() {
      isWaitingForAnswer = false;
    });

    bool isCorrect = listEquals(selectedSequence, correctSequence);
    if (isCorrect) {
      score++;
    }

    // รอ 1 วินาทีแล้วไปข้อถัดไป
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    currentQuestionIndex++;
    _startCurrentQuestion();
  }

  void _completeGame() {
    setState(() {
      gameCompleted = true;
    });

    // บันทึกผลคะแนน
    final gameProvider = Provider.of<BrainGameProvider>(context, listen: false);
    gameProvider.addGameResult('เกมความจำ', score, questions.length);
  }

  void _restartGame() {
    setState(() {
      currentQuestionIndex = 0;
      score = 0;
      gameCompleted = false;
      userSequence = [];
      correctSequence = [];
      isShowingSequence = false;
      isWaitingForAnswer = false;
      currentSequenceIndex = 0;
    });
    sequenceTimer?.cancel();
    _generateQuestions();
  }

  @override
  Widget build(BuildContext context) {
    if (gameCompleted) {
      return _buildResultScreen();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF2196F3),
        title: Text(
          'เกมความจำ',
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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight -
                  32, // 32 for padding
            ),
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
                            'ข้อที่ ${currentQuestionIndex + 1} จาก ${questions.length}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          Text(
                            'คะแนน: $score',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (currentQuestionIndex + 1) / questions.length,
                        backgroundColor: Colors.grey[300],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Main Content Area
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.memory,
                        size: 48,
                        color: Color(0xFF2196F3),
                      ),
                      SizedBox(height: 24),
                      if (isShowingSequence) ...[
                        Text(
                          'จำลำดับตัวเลขนี้',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Color(0xFF2196F3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(0xFF2196F3),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            correctSequence
                                .take(currentSequenceIndex)
                                .join(' '),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2196F3),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ] else if (isWaitingForAnswer) ...[
                        Text(
                          'เลือกลำดับที่ถูกต้อง',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'จำลำดับที่เพิ่งเห็นได้ไหม?',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),

                if (isWaitingForAnswer) ...[
                  SizedBox(height: 24),

                  // Answer Options
                  Column(
                    children: questions[currentQuestionIndex]
                        .options
                        .asMap()
                        .entries
                        .map((entry) {
                      int optionIndex = entry.key;
                      List<int> sequence = entry.value;
                      bool isCorrect = listEquals(sequence, correctSequence);

                      return Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 12),
                        child: ElevatedButton(
                          onPressed: () => _selectAnswer(sequence),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF2D3748),
                            side: BorderSide(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            sequence.join(' - '),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Add some bottom padding to ensure content doesn't get cut off
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    double percentage = (score / questions.length) * 100;
    String message;
    Color messageColor;

    if (percentage >= 80) {
      message = 'ยอดเยี่ยม! ความจำของคุณดีมาก';
      messageColor = Color(0xFF2196F3);
    } else if (percentage >= 60) {
      message = 'ดีมาก! เกือบจะสมบูรณ์แล้ว';
      messageColor = Color(0xFFFF9800);
    } else {
      message = 'ไม่เป็นไร ลองใหม่อีกครั้ง';
      messageColor = Color(0xFFF44336);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF2196F3),
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
                  32, // 32 for padding
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
                        '$score / ${questions.length}',
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
                          backgroundColor: Color(0xFF2196F3),
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

                // Add some bottom padding to ensure content doesn't get cut off
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MemoryQuestion {
  final List<int> sequence;
  final List<List<int>> options;

  MemoryQuestion({
    required this.sequence,
    required this.options,
  });
}
