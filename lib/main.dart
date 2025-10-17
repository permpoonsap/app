import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'provider/medicine_provider.dart';
import 'provider/appointment_provider.dart';
import 'provider/exercise_log_provider.dart';
import 'provider/brain_game_provider.dart';
import 'provider/daily_goal_provider.dart';
import 'provider/health_profile_provider.dart';
import 'services/auth_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_screen.dart';
import 'home_screen.dart';
import 'database/firebase_options.dart';
import 'notification/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ตั้งค่า Firebase Auth Persistence - จำการ login ไว้ในเครื่อง
  // หมายเหตุ: setPersistence() ทำงานได้เฉพาะบน web เท่านั้น
  // บน mobile (Android/iOS) Firebase จะจำการ login ไว้โดยอัตโนมัติ
  try {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } catch (e) {
    // บน mobile จะไม่สามารถใช้ setPersistence() ได้ แต่ Firebase จะจำการ login ไว้โดยอัตโนมัติ
    print(
        'setPersistence() ไม่รองรับบน platform นี้ แต่ Firebase จะจำการ login ไว้โดยอัตโนมัติ');
  }

  tz.initializeTimeZones();
  await initializeDateFormatting('th');
  await NotificationService.initialize();
  await NotificationService.requestPermissions();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MedicineProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseLogProvider()),
        ChangeNotifierProvider(create: (_) => BrainGameProvider()),
        ChangeNotifierProvider(create: (_) => DailyGoalProvider()),
        ChangeNotifierProvider(create: (_) => HealthProfileProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  void _checkAndResetMedicines(BuildContext context) {
    final prefs = SharedPreferences.getInstance();
    prefs.then((prefs) {
      final lastResetDate = prefs.getString('last_medicine_reset_date');
      final today = DateTime.now();
      final todayKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      if (lastResetDate != todayKey) {
        // It's a new day, reset medicines
        Provider.of<MedicineProvider>(context, listen: false)
            .resetMedicinesForNewDay();
        prefs.setString('last_medicine_reset_date', todayKey);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Senior Health App',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: StreamBuilder<User?>(
        stream: AuthService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            // User is logged in, set user ID for all providers
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (context.mounted) {
                try {
                  await AuthService.setCurrentUserForProviders(context);
                  // Check if it's a new day and reset medicines
                  _checkAndResetMedicines(context);
                } catch (e) {
                  print('Error setting user for providers: $e');
                }
              }
            });

            return HomeScreen();
          }

          // User is not logged in
          return AuthScreen();
        },
      ),
    );
  }
}
