import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/health_profile.dart';
import '../database/local_database.dart';
import '../services/firestore_health_service.dart';

class HealthProfileProvider extends ChangeNotifier {
  HealthProfile? _healthProfile;
  String? _currentUserId;

  HealthProfile? get healthProfile => _healthProfile;
  String? get currentUserId => _currentUserId;

  // Set current user ID
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
    LocalDatabase.setCurrentUserId(userId);
    // Clear current data when switching users
    _healthProfile = null;
    notifyListeners();
  }

  // Load health profile for current user
  Future<void> loadHealthProfile() async {
    if (_currentUserId == null) return;

    try {
      // Try to load from Firestore first
      _healthProfile =
          await FirestoreHealthService.getHealthProfile(_currentUserId);

      if (_healthProfile != null) {
        // If found in Firestore, save to local database for offline access
        await LocalDatabase.addHealthProfile(_healthProfile!);
        await _saveToSharedPreferences(_healthProfile!);
      } else {
        // If not found in Firestore, try local database
        _healthProfile =
            await LocalDatabase.getHealthProfileForUser(_currentUserId!);

        if (_healthProfile == null) {
          // Finally, fallback to SharedPreferences
          await _loadFromSharedPreferences();
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error loading health profile from Firestore: $e');

      // Fallback to local database
      try {
        _healthProfile =
            await LocalDatabase.getHealthProfileForUser(_currentUserId!);

        if (_healthProfile == null) {
          // Finally, fallback to SharedPreferences
          await _loadFromSharedPreferences();
        }

        notifyListeners();
      } catch (localError) {
        print('Error loading health profile from local database: $localError');
        await _loadFromSharedPreferences();
      }
    }
  }

  // Fallback to SharedPreferences
  Future<void> _loadFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString('health_profile_$_currentUserId');

    if (profileJson != null) {
      try {
        final Map<String, dynamic> profileMap = json.decode(profileJson);
        _healthProfile = HealthProfile.fromMap(profileMap);
      } catch (e) {
        print('Error parsing health profile from SharedPreferences: $e');
        _healthProfile = null;
      }
    } else {
      _healthProfile = null;
    }

    notifyListeners();
  }

  // Add or update health profile
  Future<void> saveHealthProfile(HealthProfile profile) async {
    try {
      // Ensure userId is set
      final profileWithUserId = profile.userId.isEmpty
          ? profile.copyWith(userId: _currentUserId ?? '')
          : profile;

      // Save to Firestore first
      try {
        await FirestoreHealthService.saveHealthProfile(profileWithUserId);
        print('Health profile saved to Firestore');
      } catch (firestoreError) {
        print('Failed to save to Firestore: $firestoreError');
        // Continue with local save even if Firestore fails
      }

      // Save to LocalDatabase
      await LocalDatabase.addHealthProfile(profileWithUserId);

      // Save to SharedPreferences as backup
      await _saveToSharedPreferences(profileWithUserId);

      // Update local state
      _healthProfile = profileWithUserId;

      notifyListeners();
    } catch (e) {
      print('Error saving health profile: $e');
      throw Exception('ไม่สามารถบันทึกข้อมูลสุขภาพได้: $e');
    }
  }

  // Update existing health profile
  Future<void> updateHealthProfile(HealthProfile profile) async {
    try {
      // Update in Firestore first
      try {
        await FirestoreHealthService.updateHealthProfile(profile);
        print('Health profile updated in Firestore');
      } catch (firestoreError) {
        print('Failed to update in Firestore: $firestoreError');
        // Continue with local update even if Firestore fails
      }

      // Update in LocalDatabase
      await LocalDatabase.updateHealthProfile(profile);

      // Save to SharedPreferences as backup
      await _saveToSharedPreferences(profile);

      // Update local state
      _healthProfile = profile;

      notifyListeners();
    } catch (e) {
      print('Error updating health profile: $e');
      throw Exception('ไม่สามารถอัปเดตข้อมูลสุขภาพได้: $e');
    }
  }

  // Save to SharedPreferences
  Future<void> _saveToSharedPreferences(HealthProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'health_profile_${profile.userId}', json.encode(profile.toMap()));
  }

  // Delete health profile
  Future<void> deleteHealthProfile() async {
    if (_healthProfile == null) return;

    try {
      // Delete from Firestore first
      try {
        await FirestoreHealthService.deleteHealthProfile(_currentUserId);
        print('Health profile deleted from Firestore');
      } catch (firestoreError) {
        print('Failed to delete from Firestore: $firestoreError');
        // Continue with local delete even if Firestore fails
      }

      // Delete from LocalDatabase
      await LocalDatabase.deleteHealthProfile(_healthProfile!.id);

      // Clear from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('health_profile_$_currentUserId');

      _healthProfile = null;
      notifyListeners();
    } catch (e) {
      print('Error deleting health profile: $e');
      throw Exception('ไม่สามารถลบข้อมูลสุขภาพได้: $e');
    }
  }

  // Clear all data for current user
  Future<void> clearAllData() async {
    try {
      // Clear from LocalDatabase
      if (_currentUserId != null) {
        await LocalDatabase.clearUserData(_currentUserId!);
      }

      // Clear from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('health_profile_$_currentUserId');

      _healthProfile = null;
      notifyListeners();
    } catch (e) {
      print('Error clearing health profile data: $e');
    }
  }

  // Get health summary
  Map<String, dynamic> getHealthSummary() {
    if (_healthProfile == null) {
      return {
        'hasData': false,
        'bmi': null,
        'bmiStatus': null,
        'bloodPressureStatus': null,
        'bloodSugarStatus': null,
      };
    }

    return {
      'hasData': true,
      'bmi': _healthProfile!.bmi,
      'bmiStatus': _healthProfile!.bmiStatus,
      'bloodPressureStatus': _healthProfile!.bloodPressureStatus,
      'bloodSugarStatus': _healthProfile!.bloodSugarStatus,
      'height': _healthProfile!.height,
      'weight': _healthProfile!.weight,
      'bloodType': _healthProfile!.bloodType,
      'chronicDiseases': _healthProfile!.chronicDiseases,
      'drugAllergies': _healthProfile!.drugAllergies,
    };
  }

  // Check if profile exists
  bool get hasProfile => _healthProfile != null;

  // Get last updated date
  DateTime? get lastUpdated => _healthProfile?.updatedAt;

  // Sync local data to Firestore
  Future<void> syncToFirestore() async {
    if (_healthProfile == null) return;

    try {
      await FirestoreHealthService.syncLocalToFirestore(_healthProfile!);
      print('Health profile synced to Firestore successfully');
    } catch (e) {
      print('Failed to sync health profile to Firestore: $e');
      // Don't throw error to allow offline functionality
    }
  }

  // Force sync from Firestore
  Future<void> syncFromFirestore() async {
    if (_currentUserId == null) return;

    try {
      final firestoreProfile =
          await FirestoreHealthService.getHealthProfile(_currentUserId);

      if (firestoreProfile != null) {
        // Update local database
        await LocalDatabase.addHealthProfile(firestoreProfile);
        await _saveToSharedPreferences(firestoreProfile);

        // Update local state
        _healthProfile = firestoreProfile;
        notifyListeners();

        print('Health profile synced from Firestore successfully');
      }
    } catch (e) {
      print('Failed to sync health profile from Firestore: $e');
      // Don't throw error to allow offline functionality
    }
  }

  // Check if local data is different from Firestore
  Future<bool> needsSync() async {
    if (_healthProfile == null || _currentUserId == null) return false;

    try {
      final firestoreProfile =
          await FirestoreHealthService.getHealthProfile(_currentUserId);

      if (firestoreProfile == null)
        return true; // Local data exists but not in Firestore

      // Compare update timestamps
      return _healthProfile!.updatedAt.isAfter(firestoreProfile.updatedAt);
    } catch (e) {
      print('Error checking sync status: $e');
      return false;
    }
  }
}
