class ReferralModel {
  final String id;
  final String studentId;
  final String studentName;
  final String fromSpecialistId;
  final String fromSpecialistName;
  final String? fromSpecialistRole;
  final String toSpecialistType; // 'Amaliyotchi psixolog', 'Logoped-defektolog', 'Maxsus pedagog (Defektolog)', 'Tibbiy PMPK'
  final String? toSpecialistId;
  final String? toSpecialistName;
  final String reason;
  final String? supportingObservations;
  final String priority; // 'Shoshilinch', 'Rejali', 'Konsultatsiya'
  final String status; // 'Qoralamada', 'Yuborildi', 'Qabul qilindi', 'Jarayonda', 'Yakunlandi', 'Rad etildi'
  final String? outcomeNotes;
  final String? followUpAction;
  final DateTime? followUpDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReferralModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.fromSpecialistId = '',
    required this.fromSpecialistName,
    this.fromSpecialistRole,
    required this.toSpecialistType,
    this.toSpecialistId,
    this.toSpecialistName,
    required this.reason,
    this.supportingObservations,
    required this.priority,
    required this.status,
    this.outcomeNotes,
    this.followUpAction,
    this.followUpDate,
    required this.createdAt,
    this.updatedAt,
  });

  ReferralModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? fromSpecialistId,
    String? fromSpecialistName,
    String? fromSpecialistRole,
    String? toSpecialistType,
    String? toSpecialistId,
    String? toSpecialistName,
    String? reason,
    String? supportingObservations,
    String? priority,
    String? status,
    String? outcomeNotes,
    String? followUpAction,
    DateTime? followUpDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReferralModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      fromSpecialistId: fromSpecialistId ?? this.fromSpecialistId,
      fromSpecialistName: fromSpecialistName ?? this.fromSpecialistName,
      fromSpecialistRole: fromSpecialistRole ?? this.fromSpecialistRole,
      toSpecialistType: toSpecialistType ?? this.toSpecialistType,
      toSpecialistId: toSpecialistId ?? this.toSpecialistId,
      toSpecialistName: toSpecialistName ?? this.toSpecialistName,
      reason: reason ?? this.reason,
      supportingObservations:
          supportingObservations ?? this.supportingObservations,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      outcomeNotes: outcomeNotes ?? this.outcomeNotes,
      followUpAction: followUpAction ?? this.followUpAction,
      followUpDate: followUpDate ?? this.followUpDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'fromSpecialistId': fromSpecialistId,
    'fromSpecialistName': fromSpecialistName,
    'fromSpecialistRole': fromSpecialistRole,
    'toSpecialistType': toSpecialistType,
    'toSpecialistId': toSpecialistId,
    'toSpecialistName': toSpecialistName,
    'reason': reason,
    'supportingObservations': supportingObservations,
    'priority': priority,
    'status': status,
    'outcomeNotes': outcomeNotes,
    'followUpAction': followUpAction,
    'followUpDate': followUpDate?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory ReferralModel.fromJson(Map<String, dynamic> json) => ReferralModel(
    id: json['id'] as String,
    studentId: json['studentId'] as String,
    studentName: json['studentName'] as String? ?? '',
    fromSpecialistId: json['fromSpecialistId'] as String? ?? '',
    fromSpecialistName: json['fromSpecialistName'] as String,
    fromSpecialistRole: json['fromSpecialistRole'] as String?,
    toSpecialistType: json['toSpecialistType'] as String,
    toSpecialistId: json['toSpecialistId'] as String?,
    toSpecialistName: json['toSpecialistName'] as String?,
    reason: json['reason'] as String,
    supportingObservations: json['supportingObservations'] as String?,
    priority: json['priority'] as String,
    status: json['status'] as String,
    outcomeNotes: json['outcomeNotes'] as String?,
    followUpAction: json['followUpAction'] as String?,
    followUpDate: json['followUpDate'] != null
        ? DateTime.parse(json['followUpDate'] as String)
        : null,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
  );
}
