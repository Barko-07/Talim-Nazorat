import 'curriculum_model.dart';

/// Fan topshirig'i: maxsus ta'lim o'qituvchisi bolaning haqiqiy darajasiga mos
/// (sinfiga emas) topshiriq beradi va natijasini qayd etadi.
class SubjectTask {
  final String id;
  final String studentId;
  final String subject;

  /// Topshiriq qaysi sinf darajasi uchun (bolaning haqiqiy darajasi)
  final int levelGrade;

  /// Bog'liq DTS talabi (ixtiyoriy)
  final String? standardId;
  final String title;
  final String? description;
  final String assignedById;
  final String assignedByName;
  final DateTime assignedAt;
  final DateTime? dueDate;

  /// Natija: null = hali bajarilmagan
  final Mastery? result;
  final String? resultNote;
  final DateTime? completedAt;

  const SubjectTask({
    required this.id,
    required this.studentId,
    required this.subject,
    required this.levelGrade,
    this.standardId,
    required this.title,
    this.description,
    required this.assignedById,
    required this.assignedByName,
    required this.assignedAt,
    this.dueDate,
    this.result,
    this.resultNote,
    this.completedAt,
  });

  bool get isCompleted => result != null;

  bool isOverdue(DateTime now) =>
      !isCompleted && dueDate != null && now.isAfter(dueDate!);

  SubjectTask complete(Mastery result, {String? note, DateTime? at}) =>
      SubjectTask(
        id: id,
        studentId: studentId,
        subject: subject,
        levelGrade: levelGrade,
        standardId: standardId,
        title: title,
        description: description,
        assignedById: assignedById,
        assignedByName: assignedByName,
        assignedAt: assignedAt,
        dueDate: dueDate,
        result: result,
        resultNote: note,
        completedAt: at ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'subject': subject,
    'levelGrade': levelGrade,
    'standardId': standardId,
    'title': title,
    'description': description,
    'assignedById': assignedById,
    'assignedByName': assignedByName,
    'assignedAt': assignedAt.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'result': result?.name,
    'resultNote': resultNote,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory SubjectTask.fromJson(Map<String, dynamic> json) => SubjectTask(
    id: json['id'] as String,
    studentId: json['studentId'] as String,
    subject: json['subject'] as String,
    levelGrade: (json['levelGrade'] as num?)?.toInt() ?? 1,
    standardId: json['standardId'] as String?,
    title: json['title'] as String,
    description: json['description'] as String?,
    assignedById: json['assignedById'] as String? ?? '',
    assignedByName: json['assignedByName'] as String? ?? '',
    assignedAt: DateTime.parse(json['assignedAt'] as String),
    dueDate:
        json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
    result: Mastery.fromName(json['result'] as String?),
    resultNote: json['resultNote'] as String?,
    completedAt:
        json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
  );
}
