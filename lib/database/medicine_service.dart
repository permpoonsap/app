import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/medicine_item.dart';

class MedicineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'medicines';

  // Add new medicine
  Future<String> addMedicine(MedicineItem medicine) async {
    try {
      DocumentReference docRef =
          await _firestore.collection(_collection).add(medicine.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add medicine: $e');
    }
  }

  // Get medicines for specific user
  Stream<List<MedicineItem>> getMedicinesForUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('scheduledDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MedicineItem.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get medicines for specific user and date
  Stream<List<MedicineItem>> getMedicinesForUserAndDate(
      String userId, DateTime date) {
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = startOfDay.add(Duration(days: 1));

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      List<MedicineItem> medicines = snapshot.docs.map((doc) {
        return MedicineItem.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // กรองเฉพาะรายการที่อยู่ในวันที่ต้องการ
      medicines = medicines.where((medicine) {
        return medicine.scheduledDate.isAfter(startOfDay) &&
            medicine.scheduledDate.isBefore(endOfDay);
      }).toList();

      // เรียงลำดับใน Dart แทน
      medicines.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

      return medicines;
    });
  }

  // Update medicine (toggle taken status)
  Future<void> updateMedicine(MedicineItem medicine) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(medicine.id)
          .update(medicine.toMap());
    } catch (e) {
      throw Exception('Failed to update medicine: $e');
    }
  }

  // Delete medicine
  Future<void> deleteMedicine(String medicineId) async {
    try {
      await _firestore.collection(_collection).doc(medicineId).delete();
    } catch (e) {
      throw Exception('Failed to delete medicine: $e');
    }
  }

  // Get medicine history for user
  Stream<List<MedicineItem>> getMedicineHistory(String userId, {int days = 7}) {
    DateTime startDate = DateTime.now().subtract(Duration(days: days));

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      List<MedicineItem> medicines = snapshot.docs.map((doc) {
        return MedicineItem.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // กรองเฉพาะรายการที่อยู่ในช่วงเวลาที่ต้องการ
      medicines = medicines.where((medicine) {
        return medicine.scheduledDate.isAfter(startDate);
      }).toList();

      // เรียงลำดับใน Dart แทน
      medicines.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

      return medicines;
    });
  }

  // Get statistics for user
  Future<Map<String, dynamic>> getMedicineStatistics(String userId,
      {int days = 30}) async {
    try {
      DateTime startDate = DateTime.now().subtract(Duration(days: days));

      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      List<MedicineItem> medicines = snapshot.docs.map((doc) {
        return MedicineItem.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // กรองเฉพาะรายการที่อยู่ในช่วงเวลาที่ต้องการ
      medicines = medicines.where((medicine) {
        return medicine.scheduledDate.isAfter(startDate);
      }).toList();

      int totalMedicines = medicines.length;
      int takenMedicines = 0;
      int missedMedicines = 0;

      for (var medicine in medicines) {
        if (medicine.isTaken) {
          takenMedicines++;
        } else if (medicine.scheduledDate.isBefore(DateTime.now())) {
          missedMedicines++;
        }
      }

      return {
        'total': totalMedicines,
        'taken': takenMedicines,
        'missed': missedMedicines,
        'compliance': totalMedicines > 0
            ? (takenMedicines / totalMedicines * 100).round()
            : 0,
      };
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }
}
