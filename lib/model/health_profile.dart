class HealthProfile {
  final String id;
  final String userId;
  final double? height; // ส่วนสูง (ซม.)
  final double? weight; // น้ำหนักตัว (กก.)
  final double? waistCircumference; // รอบเอว (ซม.)
  final List<String> chronicDiseases; // โรคประจำตัว
  final String? bloodType; // หมู่เลือด
  final int? systolicBloodPressure; // ความดันโลหิตตัวบน
  final int? diastolicBloodPressure; // ความดันโลหิตตัวล่าง
  final List<String> drugAllergies; // ประวัติแพ้ยา
  final double? bloodSugarLevel; // ระดับน้ำตาลในเลือด (mg/dL)
  final DateTime createdAt;
  final DateTime updatedAt;

  HealthProfile({
    required this.id,
    required this.userId,
    this.height,
    this.weight,
    this.waistCircumference,
    required this.chronicDiseases,
    this.bloodType,
    this.systolicBloodPressure,
    this.diastolicBloodPressure,
    required this.drugAllergies,
    this.bloodSugarLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  // คำนวณ BMI
  double? get bmi {
    if (height != null && weight != null && height! > 0) {
      return weight! / ((height! / 100) * (height! / 100));
    }
    return null;
  }

  // ประเมินสถานะ BMI
  String? get bmiStatus {
    if (bmi == null) return null;
    if (bmi! < 18.5) return 'น้ำหนักต่ำกว่าเกณฑ์';
    if (bmi! < 25) return 'น้ำหนักปกติ';
    if (bmi! < 30) return 'น้ำหนักเกิน';
    return 'อ้วน';
  }

  // ประเมินความดันโลหิต
  String? get bloodPressureStatus {
    if (systolicBloodPressure == null || diastolicBloodPressure == null)
      return null;

    if (systolicBloodPressure! < 120 && diastolicBloodPressure! < 80) {
      return 'ปกติ';
    } else if (systolicBloodPressure! < 130 && diastolicBloodPressure! < 80) {
      return 'ปกติสูง';
    } else if (systolicBloodPressure! < 140 && diastolicBloodPressure! < 90) {
      return 'ความดันโลหิตสูงระดับ 1';
    } else if (systolicBloodPressure! >= 140 || diastolicBloodPressure! >= 90) {
      return 'ความดันโลหิตสูงระดับ 2';
    }
    return 'ไม่ทราบ';
  }

  // ประเมินระดับน้ำตาลในเลือด
  String? get bloodSugarStatus {
    if (bloodSugarLevel == null) return null;
    if (bloodSugarLevel! < 100) return 'ปกติ';
    if (bloodSugarLevel! < 126) return 'เสี่ยงเบาหวาน';
    return 'เบาหวาน';
  }

  // แปลงเป็น Map สำหรับเก็บในฐานข้อมูล
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'height': height,
      'weight': weight,
      'waistCircumference': waistCircumference,
      'chronicDiseases': chronicDiseases.join(','),
      'bloodType': bloodType,
      'systolicBloodPressure': systolicBloodPressure,
      'diastolicBloodPressure': diastolicBloodPressure,
      'drugAllergies': drugAllergies.join(','),
      'bloodSugarLevel': bloodSugarLevel,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // สร้างจาก Map
  factory HealthProfile.fromMap(Map<String, dynamic> map) {
    return HealthProfile(
      id: map['id'],
      userId: map['userId'],
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      waistCircumference: map['waistCircumference']?.toDouble(),
      chronicDiseases: map['chronicDiseases']?.split(',') ?? [],
      bloodType: map['bloodType'],
      systolicBloodPressure: map['systolicBloodPressure']?.toInt(),
      diastolicBloodPressure: map['diastolicBloodPressure']?.toInt(),
      drugAllergies: map['drugAllergies']?.split(',') ?? [],
      bloodSugarLevel: map['bloodSugarLevel']?.toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // สร้างสำเนาใหม่
  HealthProfile copyWith({
    String? id,
    String? userId,
    double? height,
    double? weight,
    double? waistCircumference,
    List<String>? chronicDiseases,
    String? bloodType,
    int? systolicBloodPressure,
    int? diastolicBloodPressure,
    List<String>? drugAllergies,
    double? bloodSugarLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      waistCircumference: waistCircumference ?? this.waistCircumference,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      bloodType: bloodType ?? this.bloodType,
      systolicBloodPressure:
          systolicBloodPressure ?? this.systolicBloodPressure,
      diastolicBloodPressure:
          diastolicBloodPressure ?? this.diastolicBloodPressure,
      drugAllergies: drugAllergies ?? this.drugAllergies,
      bloodSugarLevel: bloodSugarLevel ?? this.bloodSugarLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


