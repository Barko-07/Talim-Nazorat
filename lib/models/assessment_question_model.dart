class AssessmentQuestionOption {
  final String id;
  final String text;
  final double score;

  const AssessmentQuestionOption({
    required this.id,
    required this.text,
    this.score = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'score': score,
      };

  factory AssessmentQuestionOption.fromJson(Map<String, dynamic> json) =>
      AssessmentQuestionOption(
        id: json['id'] as String? ?? '',
        text: json['text'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
      );

  AssessmentQuestionOption copyWith({
    String? id,
    String? text,
    double? score,
  }) {
    return AssessmentQuestionOption(
      id: id ?? this.id,
      text: text ?? this.text,
      score: score ?? this.score,
    );
  }
}

class AssessmentQuestionModel {
  final String id;
  final String? title;
  final String text;
  final String domain; // 'Kognitiv va intellekt', 'Diqqat va xotira', 'Emotsional va xavotir', 'Ijtimoiy moslashuv va motivatsiya', 'Xulq-atvor va iroda'
  final String? targetAgeRange; // '7–10 yosh (1-4 sinf)', '11–15 yosh (5-9 sinf)', 'Barcha yoshlar'
  final String questionType; // 'yes_no', 'single_choice', 'multiple_choice', 'scale_1_5', 'open_text'
  final List<AssessmentQuestionOption> options;
  final String? scoringCriteria;
  final String? psychologistNotes;
  final String authorId;
  final String authorName;
  final bool isStandard;
  final String status; // 'ready', 'draft'
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AssessmentQuestionModel({
    required this.id,
    this.title,
    String? text,
    String? questionText,
    required this.domain,
    this.targetAgeRange,
    required this.questionType,
    this.options = const [],
    this.scoringCriteria,
    this.psychologistNotes,
    required this.authorId,
    required this.authorName,
    this.isStandard = false,
    this.status = 'ready',
    required this.createdAt,
    this.updatedAt,
  }) : text = text ?? questionText ?? '';

  bool get isReady => status == 'ready';
  bool get isDraft => status == 'draft';

  String get questionTitle => (title != null && title!.isNotEmpty) ? title! : text;
  String get questionText => text;
  String get safeAgeRange => targetAgeRange ?? 'Barcha yoshlar';
  String get safeCriteria => scoringCriteria ?? '';
  String get safeNotes => psychologistNotes ?? '';

  double get maxScore {
    if (questionType == 'open_text') return 0.0;
    if (questionType == 'scale_1_5') return 5.0;
    if (options.isEmpty) return 5.0;
    if (questionType == 'multiple_choice') {
      return options.fold(0.0, (sum, o) => sum + (o.score > 0 ? o.score : 0));
    }
    return options.fold(0.0, (max, o) => o.score > max ? o.score : max);
  }

  String get typeLabel {
    switch (questionType) {
      case 'yes_no':
        return 'Ha / Yo‘q';
      case 'single_choice':
        return 'Bir variantni tanlash';
      case 'multiple_choice':
        return 'Bir nechta variant';
      case 'scale_1_5':
        return '1–5 shkala';
      case 'open_text':
        return 'Erkin javob / kuzatuv';
      default:
        return 'Noma’lum tur';
    }
  }

  AssessmentQuestionModel copyWith({
    String? id,
    String? title,
    String? text,
    String? domain,
    String? targetAgeRange,
    String? questionType,
    List<AssessmentQuestionOption>? options,
    String? scoringCriteria,
    String? psychologistNotes,
    String? authorId,
    String? authorName,
    bool? isStandard,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssessmentQuestionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      text: text ?? this.text,
      domain: domain ?? this.domain,
      targetAgeRange: targetAgeRange ?? this.targetAgeRange,
      questionType: questionType ?? this.questionType,
      options: options ?? this.options,
      scoringCriteria: scoringCriteria ?? this.scoringCriteria,
      psychologistNotes: psychologistNotes ?? this.psychologistNotes,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      isStandard: isStandard ?? this.isStandard,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'text': text,
        'domain': domain,
        'targetAgeRange': targetAgeRange,
        'questionType': questionType,
        'options': options.map((o) => o.toJson()).toList(),
        'scoringCriteria': scoringCriteria,
        'psychologistNotes': psychologistNotes,
        'authorId': authorId,
        'authorName': authorName,
        'isStandard': isStandard,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory AssessmentQuestionModel.fromJson(Map<String, dynamic> json) =>
      AssessmentQuestionModel(
        id: json['id'] as String,
        title: json['title'] as String?,
        text: json['text'] as String? ?? '',
        domain: json['domain'] as String? ?? 'Kognitiv va intellekt',
        targetAgeRange: json['targetAgeRange'] as String?,
        questionType: json['questionType'] as String? ?? 'yes_no',
        options: (json['options'] as List<dynamic>?)
                ?.map((e) =>
                    AssessmentQuestionOption.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        scoringCriteria: json['scoringCriteria'] as String?,
        psychologistNotes: json['psychologistNotes'] as String?,
        authorId: json['authorId'] as String? ?? 'user_psychologist',
        authorName: json['authorName'] as String? ?? 'Dilnoza Usmonova',
        isStandard: json['isStandard'] as bool? ?? false,
        status: json['status'] as String? ?? 'ready',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );
}
