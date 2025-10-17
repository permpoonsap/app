class AppointmentItem {
  final String? id;
  final String doctorName;
  final String reason;
  final DateTime dateTime;
  final Duration alertBefore;

  AppointmentItem({
    this.id,
    required this.doctorName,
    required this.reason,
    required this.dateTime,
    required this.alertBefore,
  });

  // สร้างสำเนาของ AppointmentItem พร้อมอัปเดตข้อมูล
  AppointmentItem copyWith({
    String? id,
    String? doctorName,
    String? reason,
    DateTime? dateTime,
    Duration? alertBefore,
  }) {
    return AppointmentItem(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
      reason: reason ?? this.reason,
      dateTime: dateTime ?? this.dateTime,
      alertBefore: alertBefore ?? this.alertBefore,
    );
  }
}
