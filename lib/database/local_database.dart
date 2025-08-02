import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import '../model/medicine_item.dart';

class LocalDatabase {
  static Database? _database;

  // Get database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'elderly_health.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Create tables
  static Future<void> _onCreate(Database db, int version) async {
    // Medicines table
    await db.execute('''
      CREATE TABLE medicines(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        dose TEXT NOT NULL,
        time TEXT NOT NULL,
        scheduledDate TEXT NOT NULL,
        isTaken INTEGER NOT NULL DEFAULT 0,
        takenAt TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Users table (for local user management)
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Appointments table
    await db.execute('''
      CREATE TABLE appointments(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // Medicine operations
  static Future<String> addMedicine(MedicineItem medicine) async {
    final db = await database;
    await db.insert(
      'medicines',
      {
        'id': medicine.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': medicine.userId,
        'name': medicine.name,
        'dose': medicine.dose,
        'time': '${medicine.time.hour}:${medicine.time.minute}',
        'scheduledDate': medicine.scheduledDate.toIso8601String(),
        'isTaken': medicine.isTaken ? 1 : 0,
        'takenAt': medicine.takenAt?.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return medicine.id ?? DateTime.now().millisecondsSinceEpoch.toString();
  }

  static Future<List<MedicineItem>> getMedicinesForUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medicines',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'scheduledDate DESC',
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      final timeParts = map['time'].split(':');
      return MedicineItem(
        id: map['id'],
        userId: map['userId'],
        name: map['name'],
        dose: map['dose'],
        time: TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        ),
        scheduledDate: DateTime.parse(map['scheduledDate']),
        isTaken: map['isTaken'] == 1,
        takenAt: map['takenAt'] != null ? DateTime.parse(map['takenAt']) : null,
      );
    });
  }

  static Future<List<MedicineItem>> getMedicinesForUserAndDate(
      String userId, DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'medicines',
      where: 'userId = ? AND scheduledDate >= ? AND scheduledDate < ?',
      whereArgs: [
        userId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'scheduledDate ASC',
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      final timeParts = map['time'].split(':');
      return MedicineItem(
        id: map['id'],
        userId: map['userId'],
        name: map['name'],
        dose: map['dose'],
        time: TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        ),
        scheduledDate: DateTime.parse(map['scheduledDate']),
        isTaken: map['isTaken'] == 1,
        takenAt: map['takenAt'] != null ? DateTime.parse(map['takenAt']) : null,
      );
    });
  }

  static Future<void> updateMedicine(MedicineItem medicine) async {
    final db = await database;
    await db.update(
      'medicines',
      {
        'name': medicine.name,
        'dose': medicine.dose,
        'time': '${medicine.time.hour}:${medicine.time.minute}',
        'scheduledDate': medicine.scheduledDate.toIso8601String(),
        'isTaken': medicine.isTaken ? 1 : 0,
        'takenAt': medicine.takenAt?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
  }

  static Future<void> deleteMedicine(String medicineId) async {
    final db = await database;
    await db.delete(
      'medicines',
      where: 'id = ?',
      whereArgs: [medicineId],
    );
  }

  static Future<List<MedicineItem>> getMedicineHistory(String userId,
      {int days = 7}) async {
    final db = await database;
    final startDate = DateTime.now().subtract(Duration(days: days));

    final List<Map<String, dynamic>> maps = await db.query(
      'medicines',
      where: 'userId = ? AND scheduledDate >= ?',
      whereArgs: [userId, startDate.toIso8601String()],
      orderBy: 'scheduledDate DESC',
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      final timeParts = map['time'].split(':');
      return MedicineItem(
        id: map['id'],
        userId: map['userId'],
        name: map['name'],
        dose: map['dose'],
        time: TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        ),
        scheduledDate: DateTime.parse(map['scheduledDate']),
        isTaken: map['isTaken'] == 1,
        takenAt: map['takenAt'] != null ? DateTime.parse(map['takenAt']) : null,
      );
    });
  }

  static Future<Map<String, dynamic>> getMedicineStatistics(String userId,
      {int days = 30}) async {
    final db = await database;
    final startDate = DateTime.now().subtract(Duration(days: days));

    final List<Map<String, dynamic>> maps = await db.query(
      'medicines',
      where: 'userId = ? AND scheduledDate >= ?',
      whereArgs: [userId, startDate.toIso8601String()],
    );

    int totalMedicines = maps.length;
    int takenMedicines = 0;
    int missedMedicines = 0;

    for (var map in maps) {
      bool isTaken = map['isTaken'] == 1;
      DateTime scheduledDate = DateTime.parse(map['scheduledDate']);

      if (isTaken) {
        takenMedicines++;
      } else if (scheduledDate.isBefore(DateTime.now())) {
        missedMedicines++;
      }
    }

    return {
      'total': totalMedicines,
      'taken': takenMedicines,
      'missed': missedMedicines,
      'compliance': totalMedicines > 0
          ? (takenMedicines / totalMedicines * 100).round()
          : 0,
    };
  }

  // User operations
  static Future<void> addUser(String userId, String name,
      {String? email, String? phone}) async {
    final db = await database;
    await db.insert(
      'users',
      {
        'id': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>?> getUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // Sync operations
  static Future<void> syncWithFirestore() async {
    // TODO: Implement sync logic with Firestore
    // This will sync local data with Firestore when internet is available
  }

  // Clear all data
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete('medicines');
    await db.delete('users');
    await db.delete('appointments');
  }

  // Close database
  static Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
