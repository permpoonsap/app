import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'provider/medicine_provider.dart';
import 'home_screen.dart';
import 'package:flutter/services.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService().initialize();
  await initializeDateFormatting('th');

  runApp(MyApp());
  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MedicineProvider(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Senior Health App',
        theme: ThemeData(primarySwatch: Colors.teal),
        home: HomeScreen(),
      ),
    );
  }
  Future<void> requestExactAlarmPermission() async {
  const platform = MethodChannel('alarm_permission');
  try {
    final result = await platform.invokeMethod('requestExactAlarmPermission');
    print('[✅] Exact Alarm permission result: $result');
  } on PlatformException catch (e) {
    print('[❌] Failed to request permission: ${e.message}');
  }
}
  
}
