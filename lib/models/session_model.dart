class SessionModel {
  final String id;
  final String studentId;
  final String studentName;
  final String specialistId;
  final String specialistName;
  final String specialistRole;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String
  status; // 'Bajarildi', 'Rejalashtirilgan', 'Qatnashmadi', 'Bekor qilindi'
  final String topic;
  final String sessionType; // 'Individual', 'Kichik guruhda'
  final String? goalDescription; // Aloqador ITR maqsadi
  final String? activities;
  final String? observations;
  final String? nextSteps;
  final bool attendanceConfirmed;

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
    this.sessionType = 'Individual',
    this.goalDescription,
    this.activities,
    this.observations,
    this.nextSteps,
    this.attendanceConfirmed = false,
  });

  bool get isCompleted => status == 'Bajarildi';
  bool get isMissed => status == 'Qatnashmadi';
  bool get isCancelled => status == 'Bekor qilindi';
  bool get isScheduled => status == 'Rejalashtirilgan';

  SessionModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? specialistId,
    String? specialistName,
    String? specialistRole,
    DateTime? scheduledAt,
    int? durationMinutes,
    String? status,
    String? topic,
    String? sessionType,
    String? goalDescription,
    String? activities,
    String? observations,
    String? nextSteps,
    bool? attendanceConfirmed,
  }) {
    return SessionModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      specialistId: specialistId ?? this.specialistId,
      specialistName: specialistName ?? this.specialistName,
      specialistRole: specialistRole ?? this.specialistRole,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      topic: topic ?? this.topic,
      sessionType: sessionType ?? this.sessionType,
      goalDescription: goalDescription ?? this.goalDescription,
      activities: activities ?? this.activities,
      observations: observations ?? this.observations,
      nextSteps: nextSteps ?? this.nextSteps,
      attendanceConfirmed: attendanceConfirmed ?? this.attendanceConfirmed,
    );
  }

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
    'sessionType': sessionType,
    'goalDescription': goalDescription,
    'activities': activities,
    'observations': observations,
    'nextSteps': nextSteps,
    'attendanceConfirmed': attendanceConfirmed,
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
    sessionType: json['sessionType'] as String? ?? 'Individual',
    goalDescription: json['goalDescription'] as String?,
    activities: json['activities'] as String?,
    observations: json['observations'] as String?,
    nextSteps: json['nextSteps'] as String?,
    attendanceConfirmed: json['attendanceConfirmed'] as bool? ?? false,
  );
}
