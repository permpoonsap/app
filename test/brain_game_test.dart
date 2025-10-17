import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../lib/brain_game/matching_game_screen.dart';
import '../lib/brain_game/sequence_game_screen.dart';
import '../lib/provider/brain_game_provider.dart';

void main() {
  group('Brain Game Tests', () {
    testWidgets('Matching Game Screen renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => BrainGameProvider()),
          ],
          child: MaterialApp(
            home: MatchingGameScreen(),
          ),
        ),
      );

      // ตรวจสอบว่า AppBar แสดงผลถูกต้อง
      expect(find.text('เกมจับคู่'), findsOneWidget);

      // ตรวจสอบว่า Progress Bar แสดงผล
      expect(find.text('คะแนน: 0'), findsOneWidget);

      // ตรวจสอบว่ามีการ์ดเกม
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('Sequence Game Screen renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => BrainGameProvider()),
          ],
          child: MaterialApp(
            home: SequenceGameScreen(),
          ),
        ),
      );

      // ตรวจสอบว่า AppBar แสดงผลถูกต้อง
      expect(find.text('เกมเรียงลำดับ'), findsOneWidget);

      // ตรวจสอบว่า Progress Bar แสดงผล
      expect(find.text('คะแนน: 0'), findsOneWidget);

      // ตรวจสอบว่ามี instruction text
      expect(find.textContaining('เรียงลำดับ'), findsOneWidget);
    });

    test('BrainGameProvider adds game result correctly', () {
      final provider = BrainGameProvider();
      provider.setCurrentUserId('test_user');

      // เพิ่มผลเกม
      provider.addGameResult('เกมจับคู่', 50, 3);

      // ตรวจสอบว่าข้อมูลถูกเพิ่มเข้าไป
      final today = DateTime.now();
      final logs = provider.getGameLogsForDate(today);

      expect(logs.length, equals(1));
      expect(logs.first.gameType, equals('เกมจับคู่'));
      expect(logs.first.score, equals(50));
      expect(logs.first.totalQuestions, equals(3));
    });

    test('MatchingLevel creates correct structure', () {
      final level = MatchingLevel(
        name: 'ระดับง่าย',
        pairs: 4,
        icons: [Icons.home, Icons.pets, Icons.favorite, Icons.star],
        colors: [Colors.blue, Colors.green, Colors.red, Colors.orange],
      );

      expect(level.name, equals('ระดับง่าย'));
      expect(level.pairs, equals(4));
      expect(level.icons.length, equals(4));
      expect(level.colors.length, equals(4));
    });

    test('SequenceLevel creates correct structure', () {
      final level = SequenceLevel(
        name: 'ระดับง่าย',
        type: SequenceType.numbers,
        itemCount: 4,
        items: [1, 2, 3, 4],
      );

      expect(level.name, equals('ระดับง่าย'));
      expect(level.type, equals(SequenceType.numbers));
      expect(level.itemCount, equals(4));
      expect(level.items.length, equals(4));
    });
  });
}
