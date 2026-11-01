import 'assessment_response_model.dart';

class AssessmentCriterionResult {
  final String criterionName;
  final double score;
  final double maxScore;
  final String? notes;

  AssessmentCriterionResult({
    required this.criterionName,
    required this.score,
    required this.maxScore,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'criterionName': criterionName,
    'score': score,
    'maxScore': maxScore,
    'notes': notes,
  };

  factory AssessmentCriterionResult.fromJson(Map<String, dynamic> json) =>
      AssessmentCriterionResult(
        criterionName: json['criterionName'] as String,
        score: (json['score'] as num).toDouble(),
        maxScore: (json['maxScore'] as num).toDouble(),
        notes: json['notes'] as String?,
      );
}

class AssessmentModel {
  final String id;
  final String studentId;
  final String studentName;
  final String specialistId;
  final String specialistName;
  final String specialistRole;
  final DateTime assessmentDate;
  final String type; // Standart balli (Rubrikali), Savollar kutubxonasi asosida, Sifatli pedagogik kuzatuv
  final String category; // Kognitiv va intellekt, Diqqat va xotira, Emotsional va xavotir, Ijtimoiy moslashuv, Kompleks
  final String title;
  final String notes;
  final String recommendations;
  final double totalScore;
  final double maxScore;
  final double? previousScore;
  final List<AssessmentCriterionResult> criteria;
  final List<AssessmentResponseModel> responses;
  final List<String> questionIds;
  final String status; // 'completed', 'draft'
  final String? generalConclusion;
  final Map<String, double>? domainScores;
  final String? followUpAction;
  final DateTime? reviewDate;
  final bool isDraft;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  AssessmentModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.specialistId,
    required this.specialistName,
    required this.specialistRole,
    required this.assessmentDate,
    required this.type,
    required this.category,
    required this.title,
    required this.notes,
    required this.recommendations,
    required this.totalScore,
    required this.maxScore,
    this.previousScore,
    this.criteria = const [],
    this.responses = const [],
    this.questionIds = const [],
    this.status = 'completed',
    this.generalConclusion,
    this.domainScores,
    this.followUpAction,
    this.reviewDate,
    this.isDraft = false,
    this.updatedAt,
    this.createdAt,
  });

  double get percentage => maxScore > 0 ? (totalScore / maxScore) * 100 : 0;

  bool get isCompleted => status == 'completed' && !isDraft;

  String get trend {
    if (previousScore == null) return 'Boshlang‘ich (Baseline)';
    final diff = totalScore - previousScore!;
    if (diff > 5) return 'O‘sish';
    if (diff < -5) return 'Pasayish';
    return 'Barqarorlik';
  }

  AssessmentModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? specialistId,
    String? specialistName,
    String? specialistRole,
    DateTime? assessmentDate,
    String? type,
    String? category,
    String? title,
    String? notes,
    String? recommendations,
    double? totalScore,
    double? maxScore,
    double? previousScore,
    List<AssessmentCriterionResult>? criteria,
    List<AssessmentResponseModel>? responses,
    List<String>? questionIds,
    String? status,
    String? generalConclusion,
    Map<String, double>? domainScores,
    String? followUpAction,
    DateTime? reviewDate,
    bool? isDraft,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return AssessmentModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      specialistId: specialistId ?? this.specialistId,
      specialistName: specialistName ?? this.specialistName,
      specialistRole: specialistRole ?? this.specialistRole,
      assessmentDate: assessmentDate ?? this.assessmentDate,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      recommendations: recommendations ?? this.recommendations,
      totalScore: totalScore ?? this.totalScore,
      maxScore: maxScore ?? this.maxScore,
      previousScore: previousScore ?? this.previousScore,
      criteria: criteria ?? this.criteria,
      responses: responses ?? this.responses,
      questionIds: questionIds ?? this.questionIds,
      status: status ?? this.status,
      generalConclusion: generalConclusion ?? this.generalConclusion,
      domainScores: domainScores ?? this.domainScores,
      followUpAction: followUpAction ?? this.followUpAction,
      reviewDate: reviewDate ?? this.reviewDate,
      isDraft: isDraft ?? this.isDraft,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'specialistId': specialistId,
    'specialistName': specialistName,
    'specialistRole': specialistRole,
    'assessmentDate': assessmentDate.toIso8601String(),
    'type': type,
    'category': category,
    'title': title,
    'notes': notes,
    'recommendations': recommendations,
    'totalScore': totalScore,
    'maxScore': maxScore,
    'previousScore': previousScore,
    'criteria': criteria.map((c) => c.toJson()).toList(),
    'responses': responses.map((r) => r.toJson()).toList(),
    'questionIds': questionIds,
    'status': status,
    'generalConclusion': generalConclusion,
    'domainScores': domainScores,
    'followUpAction': followUpAction,
    'reviewDate': reviewDate?.toIso8601String(),
    'isDraft': isDraft,
    'updatedAt': updatedAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
  };

  factory AssessmentModel.fromJson(Map<String, dynamic> json) =>
      AssessmentModel(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String? ?? '',
        specialistId: json['specialistId'] as String,
        specialistName: json['specialistName'] as String? ?? '',
        specialistRole: json['specialistRole'] as String? ?? '',
        assessmentDate: DateTime.parse(json['assessmentDate'] as String),
        type: json['type'] as String? ?? 'Standart balli (Rubrikali)',
        category: json['category'] as String? ?? 'Kognitiv va intellekt',
        title: json['title'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        recommendations: json['recommendations'] as String? ?? '',
        totalScore: (json['totalScore'] as num?)?.toDouble() ?? 0.0,
        maxScore: (json['maxScore'] as num?)?.toDouble() ?? 100.0,
        previousScore: (json['previousScore'] as num?)?.toDouble(),
        criteria:
            (json['criteria'] as List<dynamic>?)
                ?.map(
                  (c) => AssessmentCriterionResult.fromJson(
                    c as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            [],
        responses:
            (json['responses'] as List<dynamic>?)
                ?.map(
                  (r) => AssessmentResponseModel.fromJson(
                    r as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            [],
        questionIds:
            (json['questionIds'] as List<dynamic>?)
                ?.map((q) => q.toString())
                .toList() ??
            [],
        status: json['status'] as String? ??
            ((json['isDraft'] as bool? ?? false) ? 'draft' : 'completed'),
        generalConclusion: json['generalConclusion'] as String?,
        domainScores: (json['domainScores'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
        followUpAction: json['followUpAction'] as String?,
        reviewDate: json['reviewDate'] != null
            ? DateTime.parse(json['reviewDate'] as String)
            : null,
        isDraft: json['isDraft'] as bool? ?? false,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}
