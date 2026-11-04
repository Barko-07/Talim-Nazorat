/// Bolaning shaxsiy baholash to'plami: bir yo'nalish bo'yicha tanlangan savollar.
/// Qayta baholashda aynan shu to'plam ishlatiladi — natijalar shu sababli solishtiriladi.
/// Daraja o'zgarganda yangi to'plam yaratiladi, eskisi faolsizlantiriladi (tarix saqlanadi).
class AssessmentPlanModel {
  final String id;
  final String studentId;
  final String domain;
  final int workingGrade; // to'plam qaysi sinf darajasi uchun tuzilgan
  final List<String> questionIds; // tartib muhim
  final String createdById;
  final String createdByName;
  final DateTime createdAt;
  final bool isActive;
  final String? replacedByPlanId;
  final String? note;

  const AssessmentPlanModel({
    required this.id,
    required this.studentId,
    required this.domain,
    required this.workingGrade,
    required this.questionIds,
    required this.createdById,
    required this.createdByName,
    required this.createdAt,
    this.isActive = true,
    this.replacedByPlanId,
    this.note,
  });

  AssessmentPlanModel copyWith({
    bool? isActive,
    String? replacedByPlanId,
    String? note,
  }) {
    return AssessmentPlanModel(
      id: id,
      studentId: studentId,
      domain: domain,
      workingGrade: workingGrade,
      questionIds: questionIds,
      createdById: createdById,
      createdByName: createdByName,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      replacedByPlanId: replacedByPlanId ?? this.replacedByPlanId,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'domain': domain,
    'workingGrade': workingGrade,
    'questionIds': questionIds,
    'createdById': createdById,
    'createdByName': createdByName,
    'createdAt': createdAt.toIso8601String(),
    'isActive': isActive,
    'replacedByPlanId': replacedByPlanId,
    'note': note,
  };

  factory AssessmentPlanModel.fromJson(Map<String, dynamic> json) =>
      AssessmentPlanModel(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        domain: json['domain'] as String,
        workingGrade: (json['workingGrade'] as num?)?.toInt() ?? 1,
        questionIds:
            (json['questionIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        createdById: json['createdById'] as String? ?? '',
        createdByName: json['createdByName'] as String? ?? '',
        createdAt:
            json['createdAt'] != null
                ? DateTime.parse(json['createdAt'] as String)
                : DateTime.now(),
        isActive: json['isActive'] as bool? ?? true,
        replacedByPlanId: json['replacedByPlanId'] as String?,
        note: json['note'] as String?,
      );
}
