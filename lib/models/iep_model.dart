class PlanObjectiveModel {
  final String id;
  final String title;
  final String
  domain; // Nutq, Kognitiv, O'quv, Ijtimoiy-hissiy, Sensor-motorika
  final String? startingLevel; // Boshlang'ich daraja
  final String? targetLevel; // Kutilayotgan maqsadli daraja
  final String? measurementCriteria; // O'lchov mezoni
  final String? responsibleSpecialistId;
  final String? responsibleSpecialistName;
  final DateTime? startDate;
  final DateTime targetDate;
  final String status; // 'Rejalashtirilgan', 'Jarayonda', 'Bajarildi', 'Qayta ko‘rib chiqish'
  final int progressPercent; // 0 - 100
  final String? successCriteria;
  final String? evidenceNotes;

  PlanObjectiveModel({
    required this.id,
    required this.title,
    required this.domain,
    this.startingLevel,
    this.targetLevel,
    this.measurementCriteria,
    this.responsibleSpecialistId,
    this.responsibleSpecialistName,
    this.startDate,
    required this.targetDate,
    required this.status,
    required this.progressPercent,
    this.successCriteria,
    this.evidenceNotes,
  });

  bool get isCompleted => status == 'Bajarildi' || progressPercent >= 100;

  PlanObjectiveModel copyWith({
    String? id,
    String? title,
    String? domain,
    String? startingLevel,
    String? targetLevel,
    String? measurementCriteria,
    String? responsibleSpecialistId,
    String? responsibleSpecialistName,
    DateTime? startDate,
    DateTime? targetDate,
    String? status,
    int? progressPercent,
    String? successCriteria,
    String? evidenceNotes,
  }) {
    return PlanObjectiveModel(
      id: id ?? this.id,
      title: title ?? this.title,
      domain: domain ?? this.domain,
      startingLevel: startingLevel ?? this.startingLevel,
      targetLevel: targetLevel ?? this.targetLevel,
      measurementCriteria: measurementCriteria ?? this.measurementCriteria,
      responsibleSpecialistId:
          responsibleSpecialistId ?? this.responsibleSpecialistId,
      responsibleSpecialistName:
          responsibleSpecialistName ?? this.responsibleSpecialistName,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      progressPercent: progressPercent ?? this.progressPercent,
      successCriteria: successCriteria ?? this.successCriteria,
      evidenceNotes: evidenceNotes ?? this.evidenceNotes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'domain': domain,
    'startingLevel': startingLevel,
    'targetLevel': targetLevel,
    'measurementCriteria': measurementCriteria,
    'responsibleSpecialistId': responsibleSpecialistId,
    'responsibleSpecialistName': responsibleSpecialistName,
    'startDate': startDate?.toIso8601String(),
    'targetDate': targetDate.toIso8601String(),
    'status': status,
    'progressPercent': progressPercent,
    'successCriteria': successCriteria,
    'evidenceNotes': evidenceNotes,
  };

  factory PlanObjectiveModel.fromJson(Map<String, dynamic> json) =>
      PlanObjectiveModel(
        id: json['id'] as String,
        title: json['title'] as String,
        domain: json['domain'] as String,
        startingLevel: json['startingLevel'] as String?,
        targetLevel: json['targetLevel'] as String?,
        measurementCriteria: json['measurementCriteria'] as String?,
        responsibleSpecialistId: json['responsibleSpecialistId'] as String?,
        responsibleSpecialistName: json['responsibleSpecialistName'] as String?,
        startDate: json['startDate'] != null
            ? DateTime.parse(json['startDate'] as String)
            : null,
        targetDate: DateTime.parse(json['targetDate'] as String),
        status: json['status'] as String,
        progressPercent: json['progressPercent'] as int? ?? 0,
        successCriteria: json['successCriteria'] as String?,
        evidenceNotes: json['evidenceNotes'] as String?,
      );
}

class IndividualEducationPlanModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentGrade;
  final String institutionName;
  final String title;
  final String academicYear;
  final DateTime startDate;
  final DateTime reviewDate;
  final String responsibleTeacherId;
  final String responsibleTeacherName;
  final String? coordinatorId;
  final String? coordinatorName;
  final String status; // 'Qoralamada', 'Ko‘rib chiqilmoqda', 'Faol', 'Yakunlangan', 'Arxivlangan'
  final String baselineSummary;
  final String longTermGoals;
  final String? supportStrategies;
  final List<PlanObjectiveModel> objectives;

  IndividualEducationPlanModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentGrade,
    required this.institutionName,
    required this.title,
    required this.academicYear,
    required this.startDate,
    required this.reviewDate,
    required this.responsibleTeacherId,
    required this.responsibleTeacherName,
    this.coordinatorId,
    this.coordinatorName,
    required this.status,
    required this.baselineSummary,
    required this.longTermGoals,
    this.supportStrategies,
    this.objectives = const [],
  });

  /// Aniq hisoblangan progress (har bir o'lchanadigan maqsad progressi o'rtachasi)
  double get averageProgress {
    if (objectives.isEmpty) return 0.0;
    final total = objectives.fold<int>(0, (sum, o) => sum + o.progressPercent);
    return total / objectives.length;
  }

  int get completedObjectivesCount =>
      objectives.where((o) => o.isCompleted).length;

  int get totalObjectivesCount => objectives.length;

  IndividualEducationPlanModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentGrade,
    String? institutionName,
    String? title,
    String? academicYear,
    DateTime? startDate,
    DateTime? reviewDate,
    String? responsibleTeacherId,
    String? responsibleTeacherName,
    String? coordinatorId,
    String? coordinatorName,
    String? status,
    String? baselineSummary,
    String? longTermGoals,
    String? supportStrategies,
    List<PlanObjectiveModel>? objectives,
  }) {
    return IndividualEducationPlanModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentGrade: studentGrade ?? this.studentGrade,
      institutionName: institutionName ?? this.institutionName,
      title: title ?? this.title,
      academicYear: academicYear ?? this.academicYear,
      startDate: startDate ?? this.startDate,
      reviewDate: reviewDate ?? this.reviewDate,
      responsibleTeacherId: responsibleTeacherId ?? this.responsibleTeacherId,
      responsibleTeacherName:
          responsibleTeacherName ?? this.responsibleTeacherName,
      coordinatorId: coordinatorId ?? this.coordinatorId,
      coordinatorName: coordinatorName ?? this.coordinatorName,
      status: status ?? this.status,
      baselineSummary: baselineSummary ?? this.baselineSummary,
      longTermGoals: longTermGoals ?? this.longTermGoals,
      supportStrategies: supportStrategies ?? this.supportStrategies,
      objectives: objectives ?? this.objectives,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'studentGrade': studentGrade,
    'institutionName': institutionName,
    'title': title,
    'academicYear': academicYear,
    'startDate': startDate.toIso8601String(),
    'reviewDate': reviewDate.toIso8601String(),
    'responsibleTeacherId': responsibleTeacherId,
    'responsibleTeacherName': responsibleTeacherName,
    'coordinatorId': coordinatorId,
    'coordinatorName': coordinatorName,
    'status': status,
    'baselineSummary': baselineSummary,
    'longTermGoals': longTermGoals,
    'supportStrategies': supportStrategies,
    'objectives': objectives.map((o) => o.toJson()).toList(),
  };

  factory IndividualEducationPlanModel.fromJson(Map<String, dynamic> json) =>
      IndividualEducationPlanModel(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String? ?? '',
        studentGrade: json['studentGrade'] as String? ?? '',
        institutionName:
            json['institutionName'] as String? ?? '14-Inklyuziv maktab',
        title: json['title'] as String,
        academicYear: json['academicYear'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        reviewDate: DateTime.parse(json['reviewDate'] as String),
        responsibleTeacherId: json['responsibleTeacherId'] as String,
        responsibleTeacherName: json['responsibleTeacherName'] as String? ?? '',
        coordinatorId: json['coordinatorId'] as String?,
        coordinatorName: json['coordinatorName'] as String?,
        status: json['status'] as String,
        baselineSummary: json['baselineSummary'] as String,
        longTermGoals: json['longTermGoals'] as String,
        supportStrategies: json['supportStrategies'] as String?,
        objectives:
            (json['objectives'] as List<dynamic>?)
                ?.map(
                  (o) => PlanObjectiveModel.fromJson(o as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );
}
