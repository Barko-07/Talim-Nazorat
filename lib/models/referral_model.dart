class ReferralModel {
  final String id;
  final String studentId;
  final String studentName;
  final String fromSpecialistName;
  final String toSpecialistType; // Psixolog, Logoped, Shifokor-pediatr, PMPK komissiyasi
  final String reason;
  final String priority; // Shoshilinch, Rejali, Konsultatsiya
  final String status; // Yangi, Ko'rib chiqilmoqda, Tasdiqlandi, Yakunlandi
  final DateTime createdAt;

  ReferralModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.fromSpecialistName,
    required this.toSpecialistType,
    required this.reason,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'fromSpecialistName': fromSpecialistName,
        'toSpecialistType': toSpecialistType,
        'reason': reason,
        'priority': priority,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ReferralModel.fromJson(Map<String, dynamic> json) => ReferralModel(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String? ?? '',
        fromSpecialistName: json['fromSpecialistName'] as String,
        toSpecialistType: json['toSpecialistType'] as String,
        reason: json['reason'] as String,
        priority: json['priority'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
