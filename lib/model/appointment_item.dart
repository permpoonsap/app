import 'package:flutter/material.dart';

class AppointmentItem {
  final String doctorName;
  final String reason;
  final DateTime dateTime;
  final Duration alertBefore;

  AppointmentItem({
    required this.doctorName,
    required this.reason,
    required this.dateTime,
    required this.alertBefore,
  });
}
