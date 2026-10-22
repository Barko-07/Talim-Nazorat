class PlanObjectiveModel {
  final String id;
  final String title;
  final String domain; // Nutq, Kognitiv, O'quv, Ijtimoiy
  final DateTime targetDate;
  final String status; // Rejalashtirilgan, Jarayonda, Bajarildi, Qayta ko'rib chiqish kerak
  final int progressPercent;
  final String? successCriteria;

  PlanObjectiveModel({
    required this.id,
    required this.title,
    required this.domain,
    required this.targetDate,
    required this.status,
    required this.progressPercent,
    this.successCriteria,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'domain': domain,
        'targetDate': targetDate.toIso8601String(),
        'status': status,
        'progressPercent': progressPercent,
        'successCriteria': successCriteria,
      };

  factory PlanObjectiveModel.fromJson(Map<String, dynamic> json) =>
      PlanObjectiveModel(
        id: json['id'] as String,
        title: json['title'] as String,
        domain: json['domain'] as String,
        targetDate: DateTime.parse(json['targetDate'] as String),
        status: json['status'] as String,
        progressPercent: json['progressPercent'] as int? ?? 0,
        successCriteria: json['successCriteria'] as String?,
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
  final String status; // Faol, Qoralamada, Qayta ko'rib chiqilgan, Yakunlangan
  final String baselineSummary;
  final String longTermGoals;
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
    required this.status,
    required this.baselineSummary,
    required this.longTermGoals,
    this.objectives = const [],
  });

  double get averageProgress {
    if (objectives.isEmpty) return 0;
    final total = objectives.fold<int>(0, (sum, o) => sum + o.progressPercent);
    return total / objectives.length;
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
        'status': status,
        'baselineSummary': baselineSummary,
        'longTermGoals': longTermGoals,
        'objectives': objectives.map((o) => o.toJson()).toList(),
      };

  factory IndividualEducationPlanModel.fromJson(Map<String, dynamic> json) =>
      IndividualEducationPlanModel(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String? ?? '',
        studentGrade: json['studentGrade'] as String? ?? '',
        institutionName: json['institutionName'] as String? ?? '14-Inklyuziv maktab',
        title: json['title'] as String,
        academicYear: json['academicYear'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        reviewDate: DateTime.parse(json['reviewDate'] as String),
        responsibleTeacherId: json['responsibleTeacherId'] as String,
        responsibleTeacherName: json['responsibleTeacherName'] as String? ?? '',
        status: json['status'] as String,
        baselineSummary: json['baselineSummary'] as String,
        longTermGoals: json['longTermGoals'] as String,
        objectives: (json['objectives'] as List<dynamic>?)
                ?.map((o) =>
                    PlanObjectiveModel.fromJson(o as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
