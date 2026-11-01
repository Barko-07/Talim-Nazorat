class PsychologicalObservationModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentGrade;
  final String psychologistId;
  final String psychologistName;
  final DateTime date;
  final String category; // 'Darsdagi xulq-atvor', 'Hissiy holat (Affektiv)', 'Tengdoshlar bilan muloqot', 'Kognitiv faollik va diqqat', 'Sensor yoki xavotir belgilari'
  final String observationText;
  final String emotionalState; // 'Barqaror / Ijobiy', 'Xavotirli', 'Tirishqoq / Chalg‘uvchan', 'Agressiv / Qo‘zg‘aluvchan', 'Passiv / Tortinchoq'
  final String? triggerOrContext; // 'Mustaqil ishlaganda', 'Tanaffus vaqtida', 'Yangi mavzu tushuntirilganda', 'Boshqa bolalar bilan ziddiyatda'
  final String? recommendationOrAction;
  final bool isConfidential;
  final DateTime createdAt;

  const PsychologicalObservationModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentGrade,
    required this.psychologistId,
    required this.psychologistName,
    required this.date,
    required this.category,
    required this.observationText,
    this.emotionalState = 'Barqaror / Ijobiy',
    this.triggerOrContext,
    this.recommendationOrAction,
    this.isConfidential = true,
    required this.createdAt,
  });

  PsychologicalObservationModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentGrade,
    String? psychologistId,
    String? psychologistName,
    DateTime? date,
    String? category,
    String? observationText,
    String? emotionalState,
    String? triggerOrContext,
    String? recommendationOrAction,
    bool? isConfidential,
    DateTime? createdAt,
  }) {
    return PsychologicalObservationModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentGrade: studentGrade ?? this.studentGrade,
      psychologistId: psychologistId ?? this.psychologistId,
      psychologistName: psychologistName ?? this.psychologistName,
      date: date ?? this.date,
      category: category ?? this.category,
      observationText: observationText ?? this.observationText,
      emotionalState: emotionalState ?? this.emotionalState,
      triggerOrContext: triggerOrContext ?? this.triggerOrContext,
      recommendationOrAction:
          recommendationOrAction ?? this.recommendationOrAction,
      isConfidential: isConfidential ?? this.isConfidential,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'studentGrade': studentGrade,
    'psychologistId': psychologistId,
    'psychologistName': psychologistName,
    'date': date.toIso8601String(),
    'category': category,
    'observationText': observationText,
    'emotionalState': emotionalState,
    'triggerOrContext': triggerOrContext,
    'recommendationOrAction': recommendationOrAction,
    'isConfidential': isConfidential,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PsychologicalObservationModel.fromJson(Map<String, dynamic> json) =>
      PsychologicalObservationModel(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String,
        studentGrade: json['studentGrade'] as String? ?? '1-A',
        psychologistId: json['psychologistId'] as String,
        psychologistName: json['psychologistName'] as String,
        date: DateTime.parse(json['date'] as String),
        category: json['category'] as String,
        observationText: json['observationText'] as String,
        emotionalState:
            json['emotionalState'] as String? ?? 'Barqaror / Ijobiy',
        triggerOrContext: json['triggerOrContext'] as String?,
        recommendationOrAction: json['recommendationOrAction'] as String?,
        isConfidential: json['isConfidential'] as bool? ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );
}
