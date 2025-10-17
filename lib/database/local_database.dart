import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import '../model/medicine_item.dart';
import '../model/daily_goal.dart';
import '../model/health_profile.dart';

class LocalDatabase {
  static Database? _database;
  static String? _currentUserId;

  // Get database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Set current user ID
  static void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  // Get current user ID
  static String? getCurrentUserId() {
    return _currentUserId;
  }

  // Initialize database
  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'elderly_health.db');
    return await openDatabase(
      path,
      version: 4, // Increment version for new schema
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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
        createdAt TEXT NOT NULL,
        lastLoginAt TEXT
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

    // Daily Goals table
    await db.execute('''
      CREATE TABLE daily_goals(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        targetTimeHour INTEGER NOT NULL,
        targetTimeMinute INTEGER NOT NULL,
        targetDate TEXT NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        completedAt TEXT,
        createdAt TEXT NOT NULL,
        tags TEXT
      )
    ''');

    // User sessions table for tracking active users
    await db.execute('''
      CREATE TABLE user_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        loginAt TEXT NOT NULL,
        logoutAt TEXT,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Health Profiles table
    await db.execute('''
      CREATE TABLE health_profiles(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        height REAL,
        weight REAL,
        waistCircumference REAL,
        chronicDiseases TEXT,
        bloodType TEXT,
        systolicBloodPressure INTEGER,
        diastolicBloodPressure INTEGER,
        drugAllergies TEXT,
        bloodSugarLevel REAL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  // Handle database upgrades
  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add lastLoginAt column to users table
      await db.execute('ALTER TABLE users ADD COLUMN lastLoginAt TEXT');

      // Create user_sessions table
      await db.execute('''
        CREATE TABLE user_sessions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT NOT NULL,
          loginAt TEXT NOT NULL,
          logoutAt TEXT,
          isActive INTEGER NOT NULL DEFAULT 1
        )
      ''');
    }

    if (oldVersion < 3) {
      // Create daily_goals table
      await db.execute('''
        CREATE TABLE daily_goals(
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          targetTimeHour INTEGER NOT NULL,
          targetTimeMinute INTEGER NOT NULL,
          targetDate TEXT NOT NULL,
          status INTEGER NOT NULL DEFAULT 0,
          completedAt TEXT,
          createdAt TEXT NOT NULL,
          tags TEXT
        )
      ''');
    }

    if (oldVersion < 4) {
      // Create health_profiles table
      await db.execute('''
        CREATE TABLE health_profiles(
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          height REAL,
          weight REAL,
          waistCircumference REAL,
          chronicDiseases TEXT,
          bloodType TEXT,
          systolicBloodPressure INTEGER,
          diastolicBloodPressure INTEGER,
          drugAllergies TEXT,
          bloodSugarLevel REAL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');
    }
  }

  // Medicine operations
  static Future<String> addMedicine(MedicineItem medicine) async {
    final db = await database;
    final userId = _currentUserId ?? medicine.userId;

    await db.insert(
      'medicines',
      {
        'id': medicine.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': userId,
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

  // Appointment operations
  static Future<String> addAppointmentForUser(
      {required String userId,
      required String title,
      required String description,
      required DateTime dateTime}) async {
    final db = await database;
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    await db.insert(
      'appointments',
      {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'date': DateTime(dateTime.year, dateTime.month, dateTime.day)
            .toIso8601String(),
        'time': '${dateTime.hour}:${dateTime.minute}',
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  static Future<List<Map<String, dynamic>>> getAppointmentsForUser(
      String userId) async {
    final db = await database;
    final targetUserId = userId.isNotEmpty ? userId : _currentUserId;
    if (targetUserId == null) return [];

    final List<Map<String, dynamic>> maps = await db.query(
      'appointments',
      where: 'userId = ?',
      whereArgs: [targetUserId],
      orderBy: 'date ASC, time ASC',
    );
    return maps;
  }

  static Future<void> deleteAppointment(String appointmentId) async {
    final db = await database;
    await db.delete(
      'appointments',
      where: 'id = ?',
      whereArgs: [appointmentId],
    );
  }

  static Future<List<MedicineItem>> getMedicinesForUser(String userId) async {
    final db = await database;
    final targetUserId = userId.isNotEmpty ? userId : _currentUserId;

    if (targetUserId == null) return [];

    final List<Map<String, dynamic>> maps = await db.query(
      'medicines',
      where: 'userId = ?',
      whereArgs: [targetUserId],
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
    final targetUserId = userId.isNotEmpty ? userId : _currentUserId;

    if (targetUserId == null) return [];

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'medicines',
      where: 'userId = ? AND scheduledDate >= ? AND scheduledDate < ?',
      whereArgs: [
        targetUserId,
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
    final targetUserId = userId.isNotEmpty ? userId : _currentUserId;

    if (targetUserId == null) return [];

    final startDate = DateTime.now().subtract(Duration(days: days));

    final List<Map<String, dynamic>> maps = await db.query(
      'medicines',
      where: 'userId = ? AND scheduledDate >= ?',
      whereArgs: [targetUserId, startDate.toIso8601String()],
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
    final targetUserId = userId.isNotEmpty ? userId : _currentUserId;

    if (targetUserId == null)
      return {'total': 0, 'taken': 0, 'missed': 0, 'compliance': 0};

    final startDate = DateTime.now().subtract(Duration(days: days));

    final List<Map<String, dynamic>> maps = await db.query(
      'medicines',
      where: 'userId = ? AND scheduledDate >= ?',
      whereArgs: [targetUserId, startDate.toIso8601String()],
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
        'lastLoginAt': DateTime.now().toIso8601String(),
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

  // User session management
  static Future<void> startUserSession(String userId) async {
    final db = await database;

    // Update last login time
    await db.update(
      'users',
      {'lastLoginAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );

    // Mark previous sessions as inactive
    await db.update(
      'user_sessions',
      {'isActive': 0, 'logoutAt': DateTime.now().toIso8601String()},
      where: 'isActive = 1',
    );

    // Create new active session
    await db.insert('user_sessions', {
      'userId': userId,
      'loginAt': DateTime.now().toIso8601String(),
      'isActive': 1,
    });

    // Set current user ID
    setCurrentUserId(userId);
  }

  static Future<void> endUserSession(String userId) async {
    final db = await database;

    // Mark current session as inactive
    await db.update(
      'user_sessions',
      {'isActive': 0, 'logoutAt': DateTime.now().toIso8601String()},
      where: 'userId = ? AND isActive = 1',
      whereArgs: [userId],
    );

    // Clear current user ID
    _currentUserId = null;
  }

  // Get all users who have data in the system
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      orderBy: 'lastLoginAt DESC',
    );
    return maps;
  }

  // Get user's data summary
  static Future<Map<String, dynamic>> getUserDataSummary(String userId) async {
    final db = await database;

    // Count medicines
    final medicinesResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM medicines WHERE userId = ?',
      [userId],
    );
    final medicinesCount = medicinesResult.first['count'] as int;

    // Count appointments
    final appointmentsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM appointments WHERE userId = ?',
      [userId],
    );
    final appointmentsCount = appointmentsResult.first['count'] as int;

    // Count daily goals
    final goalsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM daily_goals WHERE userId = ?',
      [userId],
    );
    final goalsCount = goalsResult.first['count'] as int;

    // Get last activity
    final lastActivityResult = await db.rawQuery(
      'SELECT MAX(createdAt) as lastActivity FROM (SELECT createdAt FROM medicines WHERE userId = ? UNION SELECT createdAt FROM appointments WHERE userId = ? UNION SELECT createdAt FROM daily_goals WHERE userId = ?)',
      [userId, userId, userId],
    );
    final lastActivity = lastActivityResult.first['lastActivity'] as String?;

    return {
      'userId': userId,
      'medicinesCount': medicinesCount,
      'appointmentsCount': appointmentsCount,
      'goalsCount': goalsCount,
      'lastActivity': lastActivity,
    };
  }

  // Daily Goals operations
  static Future<String> addDailyGoal(DailyGoal goal) async {
    final db = await database;
    final userId = _currentUserId ?? goal.userId;

    await db.insert(
      'daily_goals',
      {
        'id': goal.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': userId,
        'title': goal.title,
        'description': goal.description,
        'targetTimeHour': goal.targetTime.hour,
        'targetTimeMinute': goal.targetTime.minute,
        'targetDate': goal.targetDate.toIso8601String(),
        'status': goal.status.index,
        'completedAt': goal.completedAt?.toIso8601String(),
        'createdAt': goal.createdAt.toIso8601String(),
        'tags': goal.tags.join(','),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return goal.id ?? DateTime.now().millisecondsSinceEpoch.toString();
  }

  static Future<List<DailyGoal>> getDailyGoalsForUserAndDate(
      String userId, DateTime date) async {
    final db = await database;
    final targetUserId = userId.isNotEmpty ? userId : _currentUserId;

    if (targetUserId == null) return [];

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'daily_goals',
      where: 'userId = ? AND targetDate >= ? AND targetDate < ?',
      whereArgs: [
        targetUserId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'targetTimeHour ASC, targetTimeMinute ASC',
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      final tags =
          map['tags'] != null ? (map['tags'] as String).split(',') : <String>[];

      return DailyGoal(
        id: map['id'],
        userId: map['userId'],
        title: map['title'],
        description: map['description'],
        targetTime: TimeOfDay(
          hour: map['targetTimeHour'],
          minute: map['targetTimeMinute'],
        ),
        targetDate: DateTime.parse(map['targetDate']),
        status: GoalStatus.values[map['status']],
        completedAt: map['completedAt'] != null
            ? DateTime.parse(map['completedAt'])
            : null,
        createdAt: DateTime.parse(map['createdAt']),
        tags: tags,
      );
    });
  }

  static Future<void> updateDailyGoal(DailyGoal goal) async {
    final db = await database;
    await db.update(
      'daily_goals',
      {
        'title': goal.title,
        'description': goal.description,
        'targetTimeHour': goal.targetTime.hour,
        'targetTimeMinute': goal.targetTime.minute,
        'targetDate': goal.targetDate.toIso8601String(),
        'status': goal.status.index,
        'completedAt': goal.completedAt?.toIso8601String(),
        'tags': goal.tags.join(','),
      },
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  static Future<void> deleteDailyGoal(String goalId) async {
    final db = await database;
    await db.delete(
      'daily_goals',
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  static Future<Map<String, dynamic>> getDailyGoalSummary(String userId) async {
    final db = await database;
    final targetUserId = userId.isNotEmpty ? userId : _currentUserId;

    if (targetUserId == null)
      return {
        'goalsCount': 0,
        'completedCount': 0,
        'missedCount': 0,
        'completionRate': 0
      };

    final List<Map<String, dynamic>> maps = await db.query(
      'daily_goals',
      where: 'userId = ?',
      whereArgs: [targetUserId],
    );

    int totalGoals = maps.length;
    int completedGoals =
        maps.where((m) => m['status'] == GoalStatus.completed.index).length;
    int missedGoals =
        maps.where((m) => m['status'] == GoalStatus.missed.index).length;

    return {
      'goalsCount': totalGoals,
      'completedCount': completedGoals,
      'missedCount': missedGoals,
      'completionRate':
          totalGoals > 0 ? (completedGoals / totalGoals * 100).round() : 0,
    };
  }

  // Sync operations
  static Future<void> syncWithFirestore() async {
    // TODO: Implement sync logic with Firestore
    // This will sync local data with Firestore when internet is available
  }

  // Health Profile operations
  static Future<String> addHealthProfile(HealthProfile profile) async {
    final db = await database;
    final userId = _currentUserId ?? profile.userId;

    await db.insert(
      'health_profiles',
      {
        'id': profile.id,
        'userId': userId,
        'height': profile.height,
        'weight': profile.weight,
        'waistCircumference': profile.waistCircumference,
        'chronicDiseases': profile.chronicDiseases.join(','),
        'bloodType': profile.bloodType,
        'systolicBloodPressure': profile.systolicBloodPressure,
        'diastolicBloodPressure': profile.diastolicBloodPressure,
        'drugAllergies': profile.drugAllergies.join(','),
        'bloodSugarLevel': profile.bloodSugarLevel,
        'createdAt': profile.createdAt.toIso8601String(),
        'updatedAt': profile.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return profile.id;
  }

  static Future<HealthProfile?> getHealthProfileForUser(String userId) async {
    final db = await database;
    final targetUserId = userId.isNotEmpty ? userId : _currentUserId;

    if (targetUserId == null) return null;

    final List<Map<String, dynamic>> maps = await db.query(
      'health_profiles',
      where: 'userId = ?',
      whereArgs: [targetUserId],
      orderBy: 'updatedAt DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return HealthProfile.fromMap(maps.first);
  }

  static Future<void> updateHealthProfile(HealthProfile profile) async {
    final db = await database;
    await db.update(
      'health_profiles',
      {
        'height': profile.height,
        'weight': profile.weight,
        'waistCircumference': profile.waistCircumference,
        'chronicDiseases': profile.chronicDiseases.join(','),
        'bloodType': profile.bloodType,
        'systolicBloodPressure': profile.systolicBloodPressure,
        'diastolicBloodPressure': profile.diastolicBloodPressure,
        'drugAllergies': profile.drugAllergies.join(','),
        'bloodSugarLevel': profile.bloodSugarLevel,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  static Future<void> deleteHealthProfile(String profileId) async {
    final db = await database;
    await db.delete(
      'health_profiles',
      where: 'id = ?',
      whereArgs: [profileId],
    );
  }

  // Clear data for specific user only
  static Future<void> clearUserData(String userId) async {
    final db = await database;
    await db.delete('medicines', where: 'userId = ?', whereArgs: [userId]);
    await db.delete('appointments', where: 'userId = ?', whereArgs: [userId]);
    await db.delete('daily_goals', where: 'userId = ?', whereArgs: [userId]);
    await db
        .delete('health_profiles', where: 'userId = ?', whereArgs: [userId]);
    await db.delete('users', where: 'userId = ?', whereArgs: [userId]);
    await db.delete('user_sessions', where: 'userId = ?', whereArgs: [userId]);
  }

  // Clear daily goal data for specific user only
  static Future<void> clearUserDailyGoalData(String userId) async {
    final db = await database;
    await db.delete('daily_goals', where: 'userId = ?', whereArgs: [userId]);
  }

  // Clear all data (for admin purposes)
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete('medicines');
    await db.delete('users');
    await db.delete('appointments');
    await db.delete('daily_goals');
    await db.delete('health_profiles');
    await db.delete('user_sessions');
  }

  // Close database
  static Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
