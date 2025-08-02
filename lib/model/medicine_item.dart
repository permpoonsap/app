import 'package:flutter/material.dart';

class MedicineItem {
  final String? id;
  final String userId;
  final String name;
  final String dose;
  final TimeOfDay time;
  bool isTaken;
  DateTime? takenAt;
  final DateTime createdAt;
  final DateTime scheduledDate;

  MedicineItem({
    this.id,
    required this.userId,
    required this.name,
    required this.dose,
    required this.time,
    this.isTaken = false,
    this.takenAt,
    DateTime? createdAt,
    required this.scheduledDate,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'dose': dose,
      'timeHour': time.hour,
      'timeMinute': time.minute,
      'isTaken': isTaken,
      'takenAt': takenAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'scheduledDate': scheduledDate.toIso8601String(),
    };
  }

  // Convert to JSON for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'dose': dose,
      'timeHour': time.hour,
      'timeMinute': time.minute,
      'isTaken': isTaken,
      'takenAt': takenAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'scheduledDate': scheduledDate.toIso8601String(),
    };
  }

  // Create from Map (from Firebase)
  factory MedicineItem.fromMap(Map<String, dynamic> map, String documentId) {
    return MedicineItem(
      id: documentId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      dose: map['dose'] ?? '',
      time: TimeOfDay(
        hour: map['timeHour'] ?? 0,
        minute: map['timeMinute'] ?? 0,
      ),
      isTaken: map['isTaken'] ?? false,
      takenAt: map['takenAt'] != null ? DateTime.parse(map['takenAt']) : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      scheduledDate: map['scheduledDate'] != null
          ? DateTime.parse(map['scheduledDate'])
          : DateTime.now(),
    );
  }

  // Create from JSON (from SharedPreferences)
  factory MedicineItem.fromJson(Map<String, dynamic> json) {
    return MedicineItem(
      id: json['id'],
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      dose: json['dose'] ?? '',
      time: TimeOfDay(
        hour: json['timeHour'] ?? 0,
        minute: json['timeMinute'] ?? 0,
      ),
      isTaken: json['isTaken'] ?? false,
      takenAt: json['takenAt'] != null ? DateTime.parse(json['takenAt']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'])
          : DateTime.now(),
    );
  }

  // Create a copy with updated fields
  MedicineItem copyWith({
    String? id,
    String? userId,
    String? name,
    String? dose,
    TimeOfDay? time,
    bool? isTaken,
    DateTime? takenAt,
    DateTime? createdAt,
    DateTime? scheduledDate,
  }) {
    return MedicineItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      time: time ?? this.time,
      isTaken: isTaken ?? this.isTaken,
      takenAt: takenAt ?? this.takenAt,
      createdAt: createdAt ?? this.createdAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
    );
  }

  void toggleTaken() {
    isTaken = !isTaken;
    if (isTaken) {
      takenAt = DateTime.now();
    } else {
      takenAt = null;
    }
  }
}
