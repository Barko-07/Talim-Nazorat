class AssessmentResponseModel {
  final String questionId;
  final String? questionTitle;
  final String questionText;
  final String domain;
  final String questionType;
  dynamic answer;
  String answerDisplay;
  double? score;
  final double? maxScore;
  final String? scoringSchema;
  bool isEvaluated;
  String? psychologistNotes;

  AssessmentResponseModel({
    required this.questionId,
    this.questionTitle,
    required this.questionText,
    required this.domain,
    required this.questionType,
    this.answer,
    this.answerDisplay = '',
    this.score,
    this.maxScore,
    this.scoringSchema,
    this.isEvaluated = true,
    this.psychologistNotes,
  });

  AssessmentResponseModel copyWith({
    String? questionId,
    String? questionTitle,
    String? questionText,
    String? domain,
    String? questionType,
    dynamic answer,
    String? answerDisplay,
    double? score,
    double? maxScore,
    String? scoringSchema,
    bool? isEvaluated,
    String? psychologistNotes,
  }) {
    return AssessmentResponseModel(
      questionId: questionId ?? this.questionId,
      questionTitle: questionTitle ?? this.questionTitle,
      questionText: questionText ?? this.questionText,
      domain: domain ?? this.domain,
      questionType: questionType ?? this.questionType,
      answer: answer ?? this.answer,
      answerDisplay: answerDisplay ?? this.answerDisplay,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      scoringSchema: scoringSchema ?? this.scoringSchema,
      isEvaluated: isEvaluated ?? this.isEvaluated,
      psychologistNotes: psychologistNotes ?? this.psychologistNotes,
    );
  }

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'questionTitle': questionTitle,
    'questionText': questionText,
    'domain': domain,
    'questionType': questionType,
    'answer': answer,
    'answerDisplay': answerDisplay,
    'score': score,
    'maxScore': maxScore,
    'scoringSchema': scoringSchema,
    'isEvaluated': isEvaluated,
    'psychologistNotes': psychologistNotes,
  };

  factory AssessmentResponseModel.fromJson(Map<String, dynamic> json) =>
      AssessmentResponseModel(
        questionId: json['questionId'] as String? ?? '',
        questionTitle: json['questionTitle'] as String?,
        questionText: json['questionText'] as String? ?? '',
        domain: json['domain'] as String? ?? 'Kognitiv va intellekt',
        questionType: json['questionType'] as String? ?? 'yes_no',
        answer: json['answer'],
        answerDisplay: json['answerDisplay'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble(),
        maxScore: (json['maxScore'] as num?)?.toDouble(),
        scoringSchema: json['scoringSchema'] as String?,
        isEvaluated: json['isEvaluated'] as bool? ?? true,
        psychologistNotes: json['psychologistNotes'] as String?,
      );
}
