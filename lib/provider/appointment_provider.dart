import 'package:flutter/material.dart';
import '../model/appointment_item.dart';

class AppointmentProvider with ChangeNotifier {
  final List<AppointmentItem> _appointments = [];

  List<AppointmentItem> get appointments => _appointments;

  void addAppointment(AppointmentItem item) {
    _appointments.add(item);
    notifyListeners();
  }
}
