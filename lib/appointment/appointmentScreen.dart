import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/appointment_provider.dart';
import '../model/appointment_item.dart';
import 'AddAppointmentScreen.dart';

class AppointmentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appointments = context.watch<AppointmentProvider>().appointments;

    return Scaffold(
      appBar: AppBar(
        title: Text("นัดหมายแพทย์"),
        backgroundColor: Colors.teal[600],
      ),
      body: appointments.isEmpty
          ? Center(child: Text('ยังไม่มีนัดหมาย'))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return _buildAppointmentCardFromModel(appointment);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<AppointmentProvider>(),
                child: AddAppointmentScreen(),
              ),
            ),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.teal[600],
      ),
    );
  }

  Widget _buildAppointmentCardFromModel(AppointmentItem item) {
    final date = item.dateTime;
    final dateStr = "${date.day}/${date.month}/${date.year}";
    final timeStr = "${date.hour}:${date.minute.toString().padLeft(2, '0')} น.";

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.medical_services_outlined, color: Colors.teal[700]),
        title: Text(item.doctorName, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("เหตุผล: ${item.reason}"),
            Text("วันที่: $dateStr  เวลา: $timeStr"),
          ],
        ),
      ),
    );
  }
}
