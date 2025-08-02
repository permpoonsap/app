import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/brain_game_provider.dart';

class CalculationGameScreen extends StatefulWidget {
  const CalculationGameScreen({Key? key}) : super(key: key);

  @override
  State<CalculationGameScreen> createState() => _CalculationGameScreenState();
}

class _CalculationGameScreenState extends State<CalculationGameScreen> {
  int currentQuestionIndex = 0;
  int score = 0;
  bool gameCompleted = false;
  List<CalculationQuestion> questions = [];
  int? selectedAnswer;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  void _generateQuestions() {
    final random = Random();
    questions = [];

    for (int i = 0; i < 5; i++) {
      int num1 = 0, num2 = 0, correctAnswer = 0;
      String operator = '';

      // สร้างโจทย์ที่เหมาะสมสำหรับผู้สูงอายุ
      switch (i) {
        case 0: // บวกเลขง่าย
          num1 = random.nextInt(20) + 1;
          num2 = random.nextInt(20) + 1;
          operator = '+';
          correctAnswer = num1 + num2;
          break;
        case 1: // ลบเลขง่าย
          num1 = random.nextInt(30) + 10;
          num2 = random.nextInt(num1 - 5) + 1;
          operator = '-';
          correctAnswer = num1 - num2;
          break;
        case 2: // คูณเลขง่าย
          num1 = random.nextInt(9) + 1;
          num2 = random.nextInt(9) + 1;
          operator = '×';
          correctAnswer = num1 * num2;
          break;
        case 3: // หารเลขง่าย
          num2 = random.nextInt(9) + 1;
          correctAnswer = random.nextInt(9) + 1;
          num1 = num2 * correctAnswer;
          operator = '÷';
          break;
        case 4: // บวกเลข 3 ตัว
          num1 = random.nextInt(15) + 1;
          num2 = random.nextInt(15) + 1;
          int num3 = random.nextInt(15) + 1;
          operator = '+';
          correctAnswer = num1 + num2 + num3;
          questions.add(CalculationQuestion(
            question: '$num1 + $num2 + $num3 = ?',
            correctAnswer: correctAnswer,
            options: _generateOptions(correctAnswer, random),
          ));
          continue;
      }

      questions.add(CalculationQuestion(
        question: '$num1 $operator $num2 = ?',
        correctAnswer: correctAnswer,
        options: _generateOptions(correctAnswer, random),
      ));
    }
  }

  List<int> _generateOptions(int correctAnswer, Random random) {
    List<int> options = [correctAnswer];

    // สร้างตัวเลือกที่ผิด 3 ตัว
    while (options.length < 4) {
      int wrongAnswer;
      if (random.nextBool()) {
        // เพิ่มหรือลดจากคำตอบที่ถูกต้อง
        wrongAnswer = correctAnswer +
            (random.nextBool() ? 1 : -1) * (random.nextInt(5) + 1);
      } else {
        // สร้างตัวเลขสุ่มใกล้เคียง
        wrongAnswer = correctAnswer + (random.nextInt(10) - 5);
      }

      // ตรวจสอบว่าไม่ซ้ำและไม่ติดลบ
      if (!options.contains(wrongAnswer) && wrongAnswer > 0) {
        options.add(wrongAnswer);
      }
    }

    // สลับตำแหน่งตัวเลือก
    options.shuffle(random);
    return options;
  }

  void _selectAnswer(int answer) {
    if (selectedAnswer != null) return; // ป้องกันการเลือกซ้ำ

    setState(() {
      selectedAnswer = answer;
    });

    // รอ 1 วินาทีแล้วไปข้อถัดไป
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    if (selectedAnswer == questions[currentQuestionIndex].correctAnswer) {
      score++;
    }

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
      });
    } else {
      _completeGame();
    }
  }

  void _completeGame() {
    setState(() {
      gameCompleted = true;
    });

    // บันทึกผลคะแนน
    final gameProvider = Provider.of<BrainGameProvider>(context, listen: false);
    gameProvider.addGameResult('เกมคำนวณ', score, questions.length);
  }

  void _restartGame() {
    setState(() {
      currentQuestionIndex = 0;
      score = 0;
      gameCompleted = false;
      selectedAnswer = null;
    });
    _generateQuestions();
  }

  @override
  Widget build(BuildContext context) {
    if (gameCompleted) {
      return _buildResultScreen();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4CAF50),
        title: Text(
          'เกมคำนวณ',
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
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (currentQuestionIndex + 1) / questions.length,
                        backgroundColor: Colors.grey[300],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Question Card
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
                        Icons.calculate,
                        size: 48,
                        color: Color(0xFF4CAF50),
                      ),
                      SizedBox(height: 24),
                      Text(
                        questions[currentQuestionIndex].question,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32),
                      Text(
                        'เลือกคำตอบที่ถูกต้อง',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Answer Options
                Column(
                  children: questions[currentQuestionIndex]
                      .options
                      .asMap()
                      .entries
                      .map((entry) {
                    int answer = entry.value;
                    bool isCorrect =
                        answer == questions[currentQuestionIndex].correctAnswer;
                    bool isSelected = selectedAnswer == answer;

                    Color buttonColor = Colors.white;
                    Color textColor = Color(0xFF2D3748);
                    Color borderColor = Colors.grey[300]!;

                    if (selectedAnswer != null) {
                      if (isCorrect) {
                        buttonColor = Color(0xFF4CAF50);
                        textColor = Colors.white;
                        borderColor = Color(0xFF4CAF50);
                      } else if (isSelected) {
                        buttonColor = Color(0xFFF44336);
                        textColor = Colors.white;
                        borderColor = Color(0xFFF44336);
                      }
                    } else if (isSelected) {
                      buttonColor = Color(0xFF4CAF50);
                      textColor = Colors.white;
                      borderColor = Color(0xFF4CAF50);
                    }

                    return Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 12),
                      child: ElevatedButton(
                        onPressed: selectedAnswer == null
                            ? () => _selectAnswer(answer)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: textColor,
                          side: BorderSide(color: borderColor, width: 2),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          answer.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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

  Widget _buildResultScreen() {
    double percentage = (score / questions.length) * 100;
    String message;
    Color messageColor;

    if (percentage >= 80) {
      message = 'ยอดเยี่ยม! คุณทำได้ดีมาก';
      messageColor = Color(0xFF4CAF50);
    } else if (percentage >= 60) {
      message = 'ดีมาก! เกือบจะสมบูรณ์แล้ว';
      messageColor = Color(0xFFFF9800);
    } else {
      message = 'ไม่เป็นไร ลองใหม่อีกครั้ง';
      messageColor = Color(0xFFF44336);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4CAF50),
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
                          backgroundColor: Color(0xFF4CAF50),
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

class CalculationQuestion {
  final String question;
  final int correctAnswer;
  final List<int> options;

  CalculationQuestion({
    required this.question,
    required this.correctAnswer,
    required this.options,
  });
}
