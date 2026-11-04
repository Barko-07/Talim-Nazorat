// Davlat ta'lim standartlari (DTS) bo'yicha fanlar, sinf talablari va bolaning
// haqiqiy bilim darajasini baholash. Bolaning sinfi va haqiqiy darajasi alohida saqlanadi
// (masalan: 7-sinf o'quvchisi, matematika bo'yicha 3-sinf darajasi).

class SchoolSubjects {
  static const onaTili = 'Ona tili';
  static const oqish = 'O‘qish va adabiyot';
  static const matematika = 'Matematika';

  static const core = [onaTili, oqish, matematika];
}

/// Bitta talab (o'quv natijasi): "shu sinf oxirida bola nimani bilishi/bajara olishi kerak".
class CurriculumStandard {
  final String id;
  final String subject;
  final int grade;
  final String description;

  /// Manba: rasmiy DTS hujjati yoki namuna. Namunalar rasmiy matn bilan almashtirilishi kerak.
  final String source;
  final bool isOfficial;

  const CurriculumStandard({
    required this.id,
    required this.subject,
    required this.grade,
    required this.description,
    this.source = 'Namuna',
    this.isOfficial = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject,
    'grade': grade,
    'description': description,
    'source': source,
    'isOfficial': isOfficial,
  };

  factory CurriculumStandard.fromJson(Map<String, dynamic> json) =>
      CurriculumStandard(
        id: json['id'] as String,
        subject: json['subject'] as String,
        grade: (json['grade'] as num).toInt(),
        description: json['description'] as String,
        source: json['source'] as String? ?? 'Namuna',
        isOfficial: json['isOfficial'] as bool? ?? false,
      );
}

/// Talabning o'zlashtirilganlik darajasi
enum Mastery {
  mastered,
  partial,
  notYet;

  String get label => switch (this) {
    Mastery.mastered => 'O‘zlashtirilgan',
    Mastery.partial => 'Qisman',
    Mastery.notYet => 'Hali o‘zlashtirilmagan',
  };

  double get weight => switch (this) {
    Mastery.mastered => 1.0,
    Mastery.partial => 0.5,
    Mastery.notYet => 0.0,
  };

  static Mastery? fromName(String? name) {
    for (final m in values) {
      if (m.name == name) return m;
    }
    return null;
  }
}

/// Bolaning bir fan bo'yicha bilim darajasini baholash natijasi.
/// O'qituvchi talablarni belgilaydi, tizim darajani tavsiya qiladi,
/// o'qituvchi tasdiqlaydi (yoki boshqa darajani belgilaydi).
class SubjectLevelAssessment {
  final String id;
  final String studentId;
  final String subject;

  /// Baholash vaqtidagi bolaning haqiqiy sinfi
  final int classGrade;

  /// Talab id -> o'zlashtirilganlik
  final Map<String, Mastery> results;

  /// Natijalardan hisoblangan daraja (0 = 1-sinf talablariga hali yetmagan)
  final int? suggestedGrade;

  /// O'qituvchi tasdiqlagan daraja (yakuniy)
  final int confirmedGrade;

  final String assessedById;
  final String assessedByName;
  final DateTime assessedAt;
  final String? notes;

  const SubjectLevelAssessment({
    required this.id,
    required this.studentId,
    required this.subject,
    required this.classGrade,
    required this.results,
    this.suggestedGrade,
    required this.confirmedGrade,
    required this.assessedById,
    required this.assessedByName,
    required this.assessedAt,
    this.notes,
  });

  /// Sinf va haqiqiy daraja o'rtasidagi farq (musbat = sinfidan past)
  int get gap => classGrade - confirmedGrade;

  SubjectLevelAssessment copyWith({
    int? suggestedGrade,
    int? confirmedGrade,
    String? assessedById,
    String? assessedByName,
    DateTime? assessedAt,
  }) {
    return SubjectLevelAssessment(
      id: id,
      studentId: studentId,
      subject: subject,
      classGrade: classGrade,
      results: results,
      suggestedGrade: suggestedGrade ?? this.suggestedGrade,
      confirmedGrade: confirmedGrade ?? this.confirmedGrade,
      assessedById: assessedById ?? this.assessedById,
      assessedByName: assessedByName ?? this.assessedByName,
      assessedAt: assessedAt ?? this.assessedAt,
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'subject': subject,
    'classGrade': classGrade,
    'results': results.map((k, v) => MapEntry(k, v.name)),
    'suggestedGrade': suggestedGrade,
    'confirmedGrade': confirmedGrade,
    'assessedById': assessedById,
    'assessedByName': assessedByName,
    'assessedAt': assessedAt.toIso8601String(),
    'notes': notes,
  };

  factory SubjectLevelAssessment.fromJson(Map<String, dynamic> json) {
    final raw = (json['results'] as Map<String, dynamic>?) ?? const {};
    return SubjectLevelAssessment(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      subject: json['subject'] as String,
      classGrade: (json['classGrade'] as num?)?.toInt() ?? 1,
      results: {
        for (final e in raw.entries)
          if (Mastery.fromName(e.value as String?) != null)
            e.key: Mastery.fromName(e.value as String?)!,
      },
      suggestedGrade: (json['suggestedGrade'] as num?)?.toInt(),
      confirmedGrade: (json['confirmedGrade'] as num?)?.toInt() ?? 0,
      assessedById: json['assessedById'] as String? ?? '',
      assessedByName: json['assessedByName'] as String? ?? '',
      assessedAt:
          json['assessedAt'] != null
              ? DateTime.parse(json['assessedAt'] as String)
              : DateTime.now(),
      notes: json['notes'] as String?,
    );
  }
}
