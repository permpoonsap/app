import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/health_profile.dart';

class FirestoreHealthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get collection reference for health profiles
  static CollectionReference get _healthProfilesCollection =>
      _firestore.collection('health_profiles');

  // Get current user ID
  static String? get _currentUserId => _auth.currentUser?.uid;

  // Save health profile to Firestore
  static Future<void> saveHealthProfile(HealthProfile profile) async {
    if (_currentUserId == null) {
      throw Exception('ผู้ใช้ยังไม่ได้เข้าสู่ระบบ');
    }

    try {
      // Use userId as document ID for easy access
      await _healthProfilesCollection.doc(_currentUserId).set({
        'id': profile.id,
        'userId': profile.userId,
        'height': profile.height,
        'weight': profile.weight,
        'waistCircumference': profile.waistCircumference,
        'chronicDiseases': profile.chronicDiseases,
        'bloodType': profile.bloodType,
        'systolicBloodPressure': profile.systolicBloodPressure,
        'diastolicBloodPressure': profile.diastolicBloodPressure,
        'drugAllergies': profile.drugAllergies,
        'bloodSugarLevel': profile.bloodSugarLevel,
        'createdAt': Timestamp.fromDate(profile.createdAt),
        'updatedAt': Timestamp.fromDate(profile.updatedAt),
      });

      print('Health profile saved to Firestore successfully');
    } catch (e) {
      print('Error saving health profile to Firestore: $e');
      throw Exception('ไม่สามารถบันทึกข้อมูลสุขภาพไปยัง Cloud ได้: $e');
    }
  }

  // Get health profile from Firestore
  static Future<HealthProfile?> getHealthProfile(String? userId) async {
    final targetUserId = userId ?? _currentUserId;
    if (targetUserId == null) return null;

    try {
      final doc = await _healthProfilesCollection.doc(targetUserId).get();

      if (!doc.exists) {
        print('No health profile found in Firestore for user: $targetUserId');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;

      // Convert Firestore data to HealthProfile
      return HealthProfile(
        id: data['id'] ?? '',
        userId: data['userId'] ?? targetUserId,
        height: data['height']?.toDouble(),
        weight: data['weight']?.toDouble(),
        waistCircumference: data['waistCircumference']?.toDouble(),
        chronicDiseases: List<String>.from(data['chronicDiseases'] ?? []),
        bloodType: data['bloodType'],
        systolicBloodPressure: data['systolicBloodPressure']?.toInt(),
        diastolicBloodPressure: data['diastolicBloodPressure']?.toInt(),
        drugAllergies: List<String>.from(data['drugAllergies'] ?? []),
        bloodSugarLevel: data['bloodSugarLevel']?.toDouble(),
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      print('Error getting health profile from Firestore: $e');
      throw Exception('ไม่สามารถดึงข้อมูลสุขภาพจาก Cloud ได้: $e');
    }
  }

  // Update health profile in Firestore
  static Future<void> updateHealthProfile(HealthProfile profile) async {
    if (_currentUserId == null) {
      throw Exception('ผู้ใช้ยังไม่ได้เข้าสู่ระบบ');
    }

    try {
      await _healthProfilesCollection.doc(_currentUserId).update({
        'height': profile.height,
        'weight': profile.weight,
        'waistCircumference': profile.waistCircumference,
        'chronicDiseases': profile.chronicDiseases,
        'bloodType': profile.bloodType,
        'systolicBloodPressure': profile.systolicBloodPressure,
        'diastolicBloodPressure': profile.diastolicBloodPressure,
        'drugAllergies': profile.drugAllergies,
        'bloodSugarLevel': profile.bloodSugarLevel,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('Health profile updated in Firestore successfully');
    } catch (e) {
      print('Error updating health profile in Firestore: $e');
      throw Exception('ไม่สามารถอัปเดตข้อมูลสุขภาพใน Cloud ได้: $e');
    }
  }

  // Delete health profile from Firestore
  static Future<void> deleteHealthProfile(String? userId) async {
    final targetUserId = userId ?? _currentUserId;
    if (targetUserId == null) {
      throw Exception('ไม่สามารถระบุผู้ใช้ได้');
    }

    try {
      await _healthProfilesCollection.doc(targetUserId).delete();
      print('Health profile deleted from Firestore successfully');
    } catch (e) {
      print('Error deleting health profile from Firestore: $e');
      throw Exception('ไม่สามารถลบข้อมูลสุขภาพจาก Cloud ได้: $e');
    }
  }

  // Listen to health profile changes (real-time)
  static Stream<HealthProfile?> listenToHealthProfile(String? userId) {
    final targetUserId = userId ?? _currentUserId;
    if (targetUserId == null) {
      return Stream.value(null);
    }

    return _healthProfilesCollection.doc(targetUserId).snapshots().map((doc) {
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;

      return HealthProfile(
        id: data['id'] ?? '',
        userId: data['userId'] ?? targetUserId,
        height: data['height']?.toDouble(),
        weight: data['weight']?.toDouble(),
        waistCircumference: data['waistCircumference']?.toDouble(),
        chronicDiseases: List<String>.from(data['chronicDiseases'] ?? []),
        bloodType: data['bloodType'],
        systolicBloodPressure: data['systolicBloodPressure']?.toInt(),
        diastolicBloodPressure: data['diastolicBloodPressure']?.toInt(),
        drugAllergies: List<String>.from(data['drugAllergies'] ?? []),
        bloodSugarLevel: data['bloodSugarLevel']?.toDouble(),
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    });
  }

  // Sync local data to Firestore
  static Future<void> syncLocalToFirestore(HealthProfile profile) async {
    try {
      await saveHealthProfile(profile);
      print('Local health profile synced to Firestore');
    } catch (e) {
      print('Failed to sync local health profile to Firestore: $e');
      // Don't throw error here to allow offline functionality
    }
  }

  // Check if user has health profile in Firestore
  static Future<bool> hasHealthProfile(String? userId) async {
    final targetUserId = userId ?? _currentUserId;
    if (targetUserId == null) return false;

    try {
      final doc = await _healthProfilesCollection.doc(targetUserId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking health profile existence: $e');
      return false;
    }
  }

  // Get health profile history (if we implement versioning later)
  static Future<List<HealthProfile>> getHealthProfileHistory(
      String? userId) async {
    final targetUserId = userId ?? _currentUserId;
    if (targetUserId == null) return [];

    try {
      // For now, just return the current profile as a single-item list
      final profile = await getHealthProfile(targetUserId);
      return profile != null ? [profile] : [];
    } catch (e) {
      print('Error getting health profile history: $e');
      return [];
    }
  }
}


