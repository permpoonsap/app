import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/brain_game_provider.dart';

class MatchingGameScreen extends StatefulWidget {
  const MatchingGameScreen({Key? key}) : super(key: key);

  @override
  State<MatchingGameScreen> createState() => _MatchingGameScreenState();
}

class _MatchingGameScreenState extends State<MatchingGameScreen> {
  int currentLevel = 0;
  int score = 0;
  int totalLevels = 0;
  bool gameCompleted = false;
  List<MatchingCard> cards = [];
  List<MatchingCard> selectedCards = [];
  bool isProcessing = false;
  int totalMatches = 0;
  int currentMatches = 0;
  List<MatchingLevel> levels = [];

  @override
  void initState() {
    super.initState();
    _generateLevels();
    _startCurrentLevel();
  }

  void _generateLevels() {
    levels = [
      MatchingLevel(
        name: 'ระดับง่าย',
        pairs: 4,
        icons: [Icons.home, Icons.pets, Icons.favorite, Icons.star],
        colors: [Colors.blue, Colors.green, Colors.red, Colors.orange],
      ),
      MatchingLevel(
        name: 'ระดับปานกลาง',
        pairs: 6,
        icons: [
          Icons.home,
          Icons.pets,
          Icons.favorite,
          Icons.star,
          Icons.cake,
          Icons.local_florist
        ],
        colors: [
          Colors.blue,
          Colors.green,
          Colors.red,
          Colors.orange,
          Colors.purple,
          Colors.teal
        ],
      ),
      MatchingLevel(
        name: 'ระดับยาก',
        pairs: 8,
        icons: [
          Icons.home,
          Icons.pets,
          Icons.favorite,
          Icons.star,
          Icons.cake,
          Icons.local_florist,
          Icons.music_note,
          Icons.sports_soccer
        ],
        colors: [
          Colors.blue,
          Colors.green,
          Colors.red,
          Colors.orange,
          Colors.purple,
          Colors.teal,
          Colors.pink,
          Colors.amber
        ],
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
    cards = [];
    selectedCards = [];
    currentMatches = 0;
    isProcessing = false;

    // สร้างการ์ดคู่
    for (int i = 0; i < level.pairs; i++) {
      cards.add(MatchingCard(
        id: i * 2,
        icon: level.icons[i],
        color: level.colors[i],
        isMatched: false,
        isFlipped: false,
      ));
      cards.add(MatchingCard(
        id: i * 2 + 1,
        icon: level.icons[i],
        color: level.colors[i],
        isMatched: false,
        isFlipped: false,
      ));
    }

    // สลับตำแหน่งการ์ด
    cards.shuffle(Random());
    totalMatches = level.pairs;

    setState(() {});
  }

  void _flipCard(MatchingCard card) {
    if (isProcessing || card.isFlipped || card.isMatched) return;

    setState(() {
      card.isFlipped = true;
      selectedCards.add(card);
    });

    if (selectedCards.length == 2) {
      _checkMatch();
    }
  }

  void _checkMatch() {
    setState(() {
      isProcessing = true;
    });

    final card1 = selectedCards[0];
    final card2 = selectedCards[1];

    if (card1.icon == card2.icon) {
      // จับคู่ได้
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            card1.isMatched = true;
            card2.isMatched = true;
            selectedCards.clear();
            isProcessing = false;
            currentMatches++;
            // คะแนนจะถูกเพิ่มเมื่อจบระดับ
          });

          if (currentMatches == totalMatches) {
            _levelComplete();
          }
        }
      });
    } else {
      // จับคู่ไม่ได้
      Future.delayed(Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            card1.isFlipped = false;
            card2.isFlipped = false;
            selectedCards.clear();
            isProcessing = false;
          });
        }
      });
    }
  }

  void _levelComplete() {
    // เพิ่มคะแนนเมื่อจบระดับ (จับคู่ได้ครบทุกคู่)
    setState(() {
      score += 1;
    });

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
    gameProvider.addGameResult('เกมจับคู่', score, totalLevels);
  }

  void _restartGame() {
    setState(() {
      currentLevel = 0;
      score = 0;
      gameCompleted = false;
    });
    _startCurrentLevel();
  }

  @override
  Widget build(BuildContext context) {
    if (gameCompleted) {
      return _buildResultScreen();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFF9800),
        title: Text(
          'เกมจับคู่',
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
                          '${levels[currentLevel].name}',
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
                            color: Color(0xFFFF9800),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'จับคู่: $currentMatches / $totalMatches',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'ระดับ: ${currentLevel + 1} / ${levels.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: currentMatches / totalMatches,
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
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
                  color: Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xFFFF9800),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFFFF9800),
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'แตะการ์ดเพื่อเปิด จำตำแหน่งแล้วจับคู่การ์ดที่มีไอคอนเหมือนกัน',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2D3748),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Game Grid
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
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return GestureDetector(
                      onTap: () => _flipCard(card),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: card.isFlipped || card.isMatched
                              ? Colors.white
                              : Color(0xFFFF9800),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: card.isMatched
                                ? Colors.green
                                : card.isFlipped
                                    ? Color(0xFFFF9800)
                                    : Color(0xFFFF9800).withOpacity(0.3),
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
                        child: card.isFlipped || card.isMatched
                            ? Icon(
                                card.icon,
                                color:
                                    card.isMatched ? Colors.green : card.color,
                                size: 32,
                              )
                            : Icon(
                                Icons.help_outline,
                                color: Colors.white,
                                size: 32,
                              ),
                      ),
                    );
                  },
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
      message = 'ยอดเยี่ยม! ความจำและสมาธิของคุณดีมาก';
      messageColor = Color(0xFFFF9800);
    } else if (percentage >= 60) {
      message = 'ดีมาก! คุณทำได้ดีมาก';
      messageColor = Color(0xFF4CAF50);
    } else {
      message = 'ไม่เป็นไร ลองใหม่อีกครั้ง';
      messageColor = Color(0xFFF44336);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFF9800),
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
                          backgroundColor: Color(0xFFFF9800),
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

class MatchingCard {
  final int id;
  final IconData icon;
  final Color color;
  bool isMatched;
  bool isFlipped;

  MatchingCard({
    required this.id,
    required this.icon,
    required this.color,
    required this.isMatched,
    required this.isFlipped,
  });
}

class MatchingLevel {
  final String name;
  final int pairs;
  final List<IconData> icons;
  final List<Color> colors;

  MatchingLevel({
    required this.name,
    required this.pairs,
    required this.icons,
    required this.colors,
  });
}
