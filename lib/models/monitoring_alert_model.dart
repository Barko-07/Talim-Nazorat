class MonitoringAlertModel {
  final String id;
  final String ruleCode;
  final String ruleTitle;
  final String studentId;
  final String studentName;
  final String studentGrade;
  final String severity; // 'XAVF' (High), 'DIQQAT' (Medium), 'MA’LUMOT' (Low)
  final String message;
  final String suggestedAction;
  final String? responsiblePersonId;
  final String? responsiblePersonName;
  final String status; // 'Ochiq', 'Ko‘rib chiqilmoqda', 'Hal qilindi', 'Rad etildi'
  final bool isResolved;
  final String? resolvedNotes;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  MonitoringAlertModel({
    required this.id,
    required this.ruleCode,
    required this.ruleTitle,
    required this.studentId,
    required this.studentName,
    required this.studentGrade,
    required this.severity,
    required this.message,
    required this.suggestedAction,
    this.responsiblePersonId,
    this.responsiblePersonName,
    this.status = 'Ochiq',
    this.isResolved = false,
    this.resolvedNotes,
    this.resolvedAt,
    required this.createdAt,
  });

  MonitoringAlertModel copyWith({
    String? id,
    String? ruleCode,
    String? ruleTitle,
    String? studentId,
    String? studentName,
    String? studentGrade,
    String? severity,
    String? message,
    String? suggestedAction,
    String? responsiblePersonId,
    String? responsiblePersonName,
    String? status,
    bool? isResolved,
    String? resolvedNotes,
    DateTime? resolvedAt,
    DateTime? createdAt,
  }) {
    return MonitoringAlertModel(
      id: id ?? this.id,
      ruleCode: ruleCode ?? this.ruleCode,
      ruleTitle: ruleTitle ?? this.ruleTitle,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentGrade: studentGrade ?? this.studentGrade,
      severity: severity ?? this.severity,
      message: message ?? this.message,
      suggestedAction: suggestedAction ?? this.suggestedAction,
      responsiblePersonId: responsiblePersonId ?? this.responsiblePersonId,
      responsiblePersonName: responsiblePersonName ?? this.responsiblePersonName,
      status: status ?? this.status,
      isResolved: isResolved ?? this.isResolved,
      resolvedNotes: resolvedNotes ?? this.resolvedNotes,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ruleCode': ruleCode,
        'ruleTitle': ruleTitle,
        'studentId': studentId,
        'studentName': studentName,
        'studentGrade': studentGrade,
        'severity': severity,
        'message': message,
        'suggestedAction': suggestedAction,
        'responsiblePersonId': responsiblePersonId,
        'responsiblePersonName': responsiblePersonName,
        'status': status,
        'isResolved': isResolved,
        'resolvedNotes': resolvedNotes,
        'resolvedAt': resolvedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory MonitoringAlertModel.fromJson(Map<String, dynamic> json) =>
      MonitoringAlertModel(
        id: json['id'] as String,
        ruleCode: json['ruleCode'] as String,
        ruleTitle: json['ruleTitle'] as String,
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String? ?? '',
        studentGrade: json['studentGrade'] as String? ?? '',
        severity: json['severity'] as String,
        message: json['message'] as String,
        suggestedAction: json['suggestedAction'] as String,
        responsiblePersonId: json['responsiblePersonId'] as String?,
        responsiblePersonName: json['responsiblePersonName'] as String?,
        status: json['status'] as String? ??
            ((json['isResolved'] as bool? ?? false) ? 'Hal qilindi' : 'Ochiq'),
        isResolved: json['isResolved'] as bool? ?? false,
        resolvedNotes: json['resolvedNotes'] as String?,
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.parse(json['resolvedAt'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
