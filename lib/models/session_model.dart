class SessionModel {
  final String id;
  final String studentId;
  final String studentName;
  final String specialistId;
  final String specialistName;
  final String specialistRole;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String status; // Bajarildi, Rejalashtirilgan, Qatnashmadi, Bekor qilindi
  final String topic;
  final String? activities;
  final String? observations;
  final String? nextSteps;

  SessionModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.specialistId,
    required this.specialistName,
    required this.specialistRole,
    required this.scheduledAt,
    this.durationMinutes = 45,
    required this.status,
    required this.topic,
    this.activities,
    this.observations,
    this.nextSteps,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'specialistId': specialistId,
        'specialistName': specialistName,
        'specialistRole': specialistRole,
        'scheduledAt': scheduledAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'status': status,
        'topic': topic,
        'activities': activities,
        'observations': observations,
        'nextSteps': nextSteps,
      };

  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String? ?? '',
        specialistId: json['specialistId'] as String,
        specialistName: json['specialistName'] as String? ?? '',
        specialistRole: json['specialistRole'] as String? ?? '',
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        durationMinutes: json['durationMinutes'] as int? ?? 45,
        status: json['status'] as String,
        topic: json['topic'] as String,
        activities: json['activities'] as String?,
        observations: json['observations'] as String?,
        nextSteps: json['nextSteps'] as String?,
      );
}
