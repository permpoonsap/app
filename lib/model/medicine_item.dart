import 'package:flutter/material.dart';

class MedicineItem {
  final String name;
  final String dose;
  final TimeOfDay time;
  bool isTaken;
  DateTime? takenAt;

  MedicineItem({
    required this.name,
    required this.dose,
    required this.time,
    this.isTaken = false,
    this.takenAt,
  });

  void toggleTaken() {
    isTaken = !isTaken;
  }
}
