import 'package:flutter/material.dart';

enum GoalStatus {
  pending, // รอทำ
  completed, // ทำสำเร็จ
  missed // ไม่ได้ทำ (เลยเวลา)
}

class DailyGoal {
  final String? id;
  final String userId;
  final String title;
  final String description;
  final TimeOfDay targetTime;
  final DateTime targetDate;
  final GoalStatus status;
  final DateTime? completedAt;
  final DateTime createdAt;
  final List<String> tags; // เช่น "สุขภาพ", "ออกกำลังกาย", "ยา"

  DailyGoal({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.targetTime,
    required this.targetDate,
    this.status = GoalStatus.pending,
    this.completedAt,
    DateTime? createdAt,
    this.tags = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  // ตรวจสอบว่าเป้าหมายเลยเวลาหรือยัง
  bool get isOverdue {
    final now = DateTime.now();
    final targetDateTime = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      targetTime.hour,
      targetTime.minute,
    );
    return now.isAfter(targetDateTime) && status == GoalStatus.pending;
  }

  // ตรวจสอบว่าเป้าหมายสามารถทำได้หรือไม่
  bool get canComplete {
    return status == GoalStatus.pending && !isOverdue;
  }

  // ตรวจสอบว่าเป้าหมายควรถูกทำเครื่องหมายว่าไม่ได้ทำ
  bool get shouldMarkAsMissed {
    return status == GoalStatus.pending && isOverdue;
  }

  // สร้างเป้าหมายใหม่ที่ทำสำเร็จ
  DailyGoal markAsCompleted() {
    return copyWith(
      status: GoalStatus.completed,
      completedAt: DateTime.now(),
    );
  }

  // สร้างเป้าหมายใหม่ที่ไม่ได้ทำ
  DailyGoal markAsMissed() {
    return copyWith(
      status: GoalStatus.missed,
    );
  }

  // สร้างเป้าหมายใหม่สำหรับวันถัดไป
  DailyGoal createForNextDay() {
    final nextDay = targetDate.add(Duration(days: 1));
    return copyWith(
      id: null,
      targetDate: nextDay,
      status: GoalStatus.pending,
      completedAt: null,
      createdAt: DateTime.now(),
    );
  }

  // แปลงเป็น Map สำหรับ Firebase
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'targetTimeHour': targetTime.hour,
      'targetTimeMinute': targetTime.minute,
      'targetDate': targetDate.toIso8601String(),
      'status': status.index,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
    };
  }

  // แปลงเป็น JSON สำหรับ SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'targetTimeHour': targetTime.hour,
      'targetTimeMinute': targetTime.minute,
      'targetDate': targetDate.toIso8601String(),
      'status': status.index,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
    };
  }

  // สร้างจาก Map (จาก Firebase)
  factory DailyGoal.fromMap(Map<String, dynamic> map, String documentId) {
    return DailyGoal(
      id: documentId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      targetTime: TimeOfDay(
        hour: map['targetTimeHour'] ?? 0,
        minute: map['targetTimeMinute'] ?? 0,
      ),
      targetDate: map['targetDate'] != null
          ? DateTime.parse(map['targetDate'])
          : DateTime.now(),
      status: GoalStatus.values[map['status'] ?? 0],
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  // สร้างจาก JSON (จาก SharedPreferences)
  factory DailyGoal.fromJson(Map<String, dynamic> json) {
    return DailyGoal(
      id: json['id'],
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      targetTime: TimeOfDay(
        hour: json['targetTimeHour'] ?? 0,
        minute: json['targetTimeMinute'] ?? 0,
      ),
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'])
          : DateTime.now(),
      status: GoalStatus.values[json['status'] ?? 0],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  // สร้างสำเนาที่มีการเปลี่ยนแปลง
  DailyGoal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TimeOfDay? targetTime,
    DateTime? targetDate,
    GoalStatus? status,
    DateTime? completedAt,
    DateTime? createdAt,
    List<String>? tags,
  }) {
    return DailyGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetTime: targetTime ?? this.targetTime,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
    );
  }

  // แสดงสถานะเป็นภาษาไทย
  String get statusText {
    switch (status) {
      case GoalStatus.pending:
        return 'รอทำ';
      case GoalStatus.completed:
        return 'ทำสำเร็จ';
      case GoalStatus.missed:
        return 'ไม่ได้ทำ';
    }
  }

  // แสดงสถานะเป็นสี
  Color get statusColor {
    switch (status) {
      case GoalStatus.pending:
        return Colors.orange;
      case GoalStatus.completed:
        return Colors.green;
      case GoalStatus.missed:
        return Colors.red;
    }
  }

  // แสดงเวลาที่กำหนดในรูปแบบที่อ่านง่าย
  String get targetTimeText {
    return '${targetTime.hour.toString().padLeft(2, '0')}:${targetTime.minute.toString().padLeft(2, '0')}';
  }

  // แสดงวันที่ในรูปแบบที่อ่านง่าย
  String get targetDateText {
    return '${targetDate.day}/${targetDate.month}/${targetDate.year}';
  }

  // ตรวจสอบว่าเป้าหมายเป็นของวันนี้หรือไม่
  bool get isToday {
    final now = DateTime.now();
    return targetDate.year == now.year &&
        targetDate.month == now.month &&
        targetDate.day == now.day;
  }

  // ตรวจสอบว่าเป้าหมายเป็นของวันนี้และยังไม่เลยเวลา
  bool get isActiveToday {
    return isToday && canComplete;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyGoal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DailyGoal(id: $id, title: $title, status: $status, targetTime: $targetTimeText)';
  }
}
