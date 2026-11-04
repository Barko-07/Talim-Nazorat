// Bolaning rivojlanish profili: imkoniyatlar (qanday qabul qiladi va javob beradi)
// va har bir yo'nalish bo'yicha ishchi sinf darajasi.
// Odatiy holatda bola o'z sinfi savollarini oladi; psixolog kerak bo'lsa
// yo'nalish bo'yicha boshqa "ishchi sinf"ni belgilashi mumkin.

/// Sinflar guruhi. Yuqori sinflar guruhida savollar murakkabroq.
enum GradeBand {
  preparatory(0, 0),
  grades1to2(1, 2),
  grades3to4(3, 4),
  grades5to6(5, 6),
  grades7to8(7, 8),
  grades9to11(9, 11);

  final int minGrade;
  final int maxGrade;
  const GradeBand(this.minGrade, this.maxGrade);

  static const int lowestGrade = 0;
  static const int highestGrade = 11;

  String get label =>
      this == GradeBand.preparatory
          ? 'Tayyorlov guruhi'
          : '$minGrade–$maxGrade-sinflar';

  static GradeBand forGrade(int grade) {
    for (final b in values) {
      if (grade <= b.maxGrade) return b;
    }
    return values.last;
  }

  /// Guruhni [steps] qadam pastga/yuqoriga surish (chegaradan chiqmaydi)
  GradeBand shift(int steps) {
    final i = (index + steps).clamp(0, values.length - 1);
    return values[i];
  }

  /// O'quvchining sinf matnidan sinf raqami: '3-A' -> 3, '10-B sinf' -> 10,
  /// 'Tayyorlov' -> 0. Aniqlab bo'lmasa — null.
  static int? parseGrade(String grade) {
    final text = grade.trim().toLowerCase();
    if (text.contains('tayyorlov')) return 0;
    final m = RegExp(r'\d+').firstMatch(text);
    if (m == null) return null;
    return int.parse(m.group(0)!).clamp(lowestGrade, highestGrade);
  }

  static String gradeLabel(int grade) =>
      grade == 0 ? 'Tayyorlov guruhi' : '$grade-sinf';
}

/// Imkoniyat darajasi
enum AbilityLevel {
  full,
  partial,
  none;

  String get label => switch (this) {
    AbilityLevel.full => 'To‘liq',
    AbilityLevel.partial => 'Qisman',
    AbilityLevel.none => 'Yo‘q',
  };

  static AbilityLevel fromName(String? name) => AbilityLevel.values.firstWhere(
    (a) => a.name == name,
    orElse: () => AbilityLevel.full,
  );
}

/// Bolaning asosiy muloqot usuli
enum CommunicationMode {
  verbal,
  limitedSpeech,
  gestureOrPointing,
  signLanguage,
  pictureCards; // AAC: rasmli kartochkalar, planshet

  String get label => switch (this) {
    CommunicationMode.verbal => 'Og‘zaki nutq',
    CommunicationMode.limitedSpeech => 'Cheklangan nutq',
    CommunicationMode.gestureOrPointing => 'Imo-ishora / ko‘rsatish',
    CommunicationMode.signLanguage => 'Surdo (imo-ishora) tili',
    CommunicationMode.pictureCards => 'Rasmli kartochkalar (AAC)',
  };

  /// Og'zaki javob berish imkoniyati
  AbilityLevel get speech => switch (this) {
    CommunicationMode.verbal => AbilityLevel.full,
    CommunicationMode.limitedSpeech => AbilityLevel.partial,
    _ => AbilityLevel.none,
  };

  static CommunicationMode fromName(String? name) =>
      CommunicationMode.values.firstWhere(
        (m) => m.name == name,
        orElse: () => CommunicationMode.verbal,
      );
}

/// Savolni bajarish uchun boladan talab qilinadigan imkoniyat
enum QuestionRequirement {
  speech, // og'zaki javob
  hearing, // og'zaki ko'rsatmani eshitish
  vision, // rasm/material ko'rish
  handMotor, // chizish, joylashtirish, ko'chirish
  reading,
  writing;

  String get label => switch (this) {
    QuestionRequirement.speech => 'Og‘zaki javob',
    QuestionRequirement.hearing => 'Eshitish',
    QuestionRequirement.vision => 'Ko‘rish',
    QuestionRequirement.handMotor => 'Qo‘l motorikasi',
    QuestionRequirement.reading => 'O‘qish',
    QuestionRequirement.writing => 'Yozish',
  };

  static QuestionRequirement? fromName(String? name) {
    for (final r in values) {
      if (r.name == name) return r;
    }
    return null;
  }
}

/// Bolaning imkoniyatlar profili. Psixolog to'ldiradi (bola o'zi to'ldira olmaydi).
class StudentAccessProfile {
  final CommunicationMode communicationMode;
  final AbilityLevel hearing;
  final AbilityLevel vision;
  final AbilityLevel handMotor;
  final AbilityLevel reading;
  final AbilityLevel writing;
  final String? notes;
  final DateTime updatedAt;
  final String? updatedById;

  const StudentAccessProfile({
    this.communicationMode = CommunicationMode.verbal,
    this.hearing = AbilityLevel.full,
    this.vision = AbilityLevel.full,
    this.handMotor = AbilityLevel.full,
    this.reading = AbilityLevel.full,
    this.writing = AbilityLevel.full,
    this.notes,
    required this.updatedAt,
    this.updatedById,
  });

  AbilityLevel abilityFor(QuestionRequirement r) => switch (r) {
    QuestionRequirement.speech => communicationMode.speech,
    QuestionRequirement.hearing => hearing,
    QuestionRequirement.vision => vision,
    QuestionRequirement.handMotor => handMotor,
    QuestionRequirement.reading => reading,
    QuestionRequirement.writing => writing,
  };

  StudentAccessProfile copyWith({
    CommunicationMode? communicationMode,
    AbilityLevel? hearing,
    AbilityLevel? vision,
    AbilityLevel? handMotor,
    AbilityLevel? reading,
    AbilityLevel? writing,
    String? notes,
    DateTime? updatedAt,
    String? updatedById,
  }) {
    return StudentAccessProfile(
      communicationMode: communicationMode ?? this.communicationMode,
      hearing: hearing ?? this.hearing,
      vision: vision ?? this.vision,
      handMotor: handMotor ?? this.handMotor,
      reading: reading ?? this.reading,
      writing: writing ?? this.writing,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedById: updatedById ?? this.updatedById,
    );
  }

  Map<String, dynamic> toJson() => {
    'communicationMode': communicationMode.name,
    'hearing': hearing.name,
    'vision': vision.name,
    'handMotor': handMotor.name,
    'reading': reading.name,
    'writing': writing.name,
    'notes': notes,
    'updatedAt': updatedAt.toIso8601String(),
    'updatedById': updatedById,
  };

  factory StudentAccessProfile.fromJson(Map<String, dynamic> json) =>
      StudentAccessProfile(
        communicationMode: CommunicationMode.fromName(
          json['communicationMode'] as String?,
        ),
        hearing: AbilityLevel.fromName(json['hearing'] as String?),
        vision: AbilityLevel.fromName(json['vision'] as String?),
        handMotor: AbilityLevel.fromName(json['handMotor'] as String?),
        reading: AbilityLevel.fromName(json['reading'] as String?),
        writing: AbilityLevel.fromName(json['writing'] as String?),
        notes: json['notes'] as String?,
        updatedAt:
            json['updatedAt'] != null
                ? DateTime.parse(json['updatedAt'] as String)
                : DateTime.now(),
        updatedById: json['updatedById'] as String?,
      );
}

/// Bir yo'nalish (masalan, 'Diqqat va xotira') bo'yicha bolaning ishchi sinfi.
/// Faqat bola o'z sinfidan farqli darajada ishlaganda psixolog belgilaydi
/// (masalan, 5-sinf o'quvchisi xotira bo'yicha 2-sinf darajasida).
class DomainLevel {
  final String domain;
  final int workingGrade;
  final DateTime setAt;
  final String? setById;
  final String? note;

  const DomainLevel({
    required this.domain,
    required this.workingGrade,
    required this.setAt,
    this.setById,
    this.note,
  });

  GradeBand get band => GradeBand.forGrade(workingGrade);

  Map<String, dynamic> toJson() => {
    'domain': domain,
    'workingGrade': workingGrade,
    'setAt': setAt.toIso8601String(),
    'setById': setById,
    'note': note,
  };

  static DomainLevel? fromJson(Map<String, dynamic> json) {
    final grade = (json['workingGrade'] as num?)?.toInt();
    final domain = json['domain'] as String?;
    if (grade == null || domain == null) return null;
    return DomainLevel(
      domain: domain,
      workingGrade: grade.clamp(GradeBand.lowestGrade, GradeBand.highestGrade),
      setAt:
          json['setAt'] != null
              ? DateTime.parse(json['setAt'] as String)
              : DateTime.now(),
      setById: json['setById'] as String?,
      note: json['note'] as String?,
    );
  }
}
