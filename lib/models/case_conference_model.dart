/// Konsilium: bir bola bo'yicha bir nechta mutaxassisning qo'shma ko'rib chiqishi,
/// umumiy xulosa va mas'uli belgilangan qarorlar.
enum ConferenceStatus {
  planned('Rejalashtirilgan'),
  held('O‘tkazildi'),
  cancelled('Bekor qilindi');

  final String label;
  const ConferenceStatus(this.label);

  static ConferenceStatus fromName(String? name) =>
      ConferenceStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => ConferenceStatus.planned,
      );
}

/// Mutaxassisning konsiliumdagi xulosasi
class ConferenceContribution {
  final String userId;
  final String userName;
  final String role;
  final String summary;
  final String? recommendations;
  final DateTime at;

  const ConferenceContribution({
    required this.userId,
    required this.userName,
    required this.role,
    required this.summary,
    this.recommendations,
    required this.at,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'role': role,
    'summary': summary,
    'recommendations': recommendations,
    'at': at.toIso8601String(),
  };

  factory ConferenceContribution.fromJson(Map<String, dynamic> json) =>
      ConferenceContribution(
        userId: json['userId'] as String,
        userName: json['userName'] as String? ?? '',
        role: json['role'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        recommendations: json['recommendations'] as String?,
        at: DateTime.parse(json['at'] as String),
      );
}

/// Konsilium qarori: nima qilinadi, kim mas'ul, qachongacha
class ConferenceDecision {
  final String id;
  final String text;
  final String responsibleId;
  final String responsibleName;
  final DateTime? dueDate;
  final bool isDone;
  final DateTime? doneAt;

  const ConferenceDecision({
    required this.id,
    required this.text,
    required this.responsibleId,
    required this.responsibleName,
    this.dueDate,
    this.isDone = false,
    this.doneAt,
  });

  bool isOverdue(DateTime now) =>
      !isDone && dueDate != null && now.isAfter(dueDate!);

  ConferenceDecision markDone(DateTime at) => ConferenceDecision(
    id: id,
    text: text,
    responsibleId: responsibleId,
    responsibleName: responsibleName,
    dueDate: dueDate,
    isDone: true,
    doneAt: at,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'responsibleId': responsibleId,
    'responsibleName': responsibleName,
    'dueDate': dueDate?.toIso8601String(),
    'isDone': isDone,
    'doneAt': doneAt?.toIso8601String(),
  };

  factory ConferenceDecision.fromJson(Map<String, dynamic> json) =>
      ConferenceDecision(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        responsibleId: json['responsibleId'] as String? ?? '',
        responsibleName: json['responsibleName'] as String? ?? '',
        dueDate:
            json['dueDate'] != null
                ? DateTime.parse(json['dueDate'] as String)
                : null,
        isDone: json['isDone'] as bool? ?? false,
        doneAt:
            json['doneAt'] != null
                ? DateTime.parse(json['doneAt'] as String)
                : null,
      );
}

class CaseConference {
  final String id;
  final String studentId;
  final String studentName;
  final String agenda;
  final DateTime scheduledAt;
  final String convenedById;
  final String convenedByName;
  final List<String> participantIds;
  final ConferenceStatus status;
  final List<ConferenceContribution> contributions;
  final String? conclusion;
  final List<ConferenceDecision> decisions;
  final DateTime? heldAt;

  const CaseConference({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.agenda,
    required this.scheduledAt,
    required this.convenedById,
    required this.convenedByName,
    required this.participantIds,
    this.status = ConferenceStatus.planned,
    this.contributions = const [],
    this.conclusion,
    this.decisions = const [],
    this.heldAt,
  });

  bool isParticipant(String userId) =>
      participantIds.contains(userId) || convenedById == userId;

  /// Xulosasini hali kiritmagan ishtirokchilar
  List<String> get pendingParticipantIds =>
      participantIds
          .where((id) => !contributions.any((c) => c.userId == id))
          .toList();

  CaseConference copyWith({
    ConferenceStatus? status,
    List<ConferenceContribution>? contributions,
    String? conclusion,
    List<ConferenceDecision>? decisions,
    DateTime? heldAt,
  }) {
    return CaseConference(
      id: id,
      studentId: studentId,
      studentName: studentName,
      agenda: agenda,
      scheduledAt: scheduledAt,
      convenedById: convenedById,
      convenedByName: convenedByName,
      participantIds: participantIds,
      status: status ?? this.status,
      contributions: contributions ?? this.contributions,
      conclusion: conclusion ?? this.conclusion,
      decisions: decisions ?? this.decisions,
      heldAt: heldAt ?? this.heldAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'agenda': agenda,
    'scheduledAt': scheduledAt.toIso8601String(),
    'convenedById': convenedById,
    'convenedByName': convenedByName,
    'participantIds': participantIds,
    'status': status.name,
    'contributions': contributions.map((c) => c.toJson()).toList(),
    'conclusion': conclusion,
    'decisions': decisions.map((d) => d.toJson()).toList(),
    'heldAt': heldAt?.toIso8601String(),
  };

  factory CaseConference.fromJson(Map<String, dynamic> json) => CaseConference(
    id: json['id'] as String,
    studentId: json['studentId'] as String,
    studentName: json['studentName'] as String? ?? '',
    agenda: json['agenda'] as String? ?? '',
    scheduledAt: DateTime.parse(json['scheduledAt'] as String),
    convenedById: json['convenedById'] as String? ?? '',
    convenedByName: json['convenedByName'] as String? ?? '',
    participantIds:
        (json['participantIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    status: ConferenceStatus.fromName(json['status'] as String?),
    contributions:
        (json['contributions'] as List<dynamic>?)
            ?.map(
              (e) => ConferenceContribution.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        const [],
    conclusion: json['conclusion'] as String?,
    decisions:
        (json['decisions'] as List<dynamic>?)
            ?.map((e) => ConferenceDecision.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    heldAt:
        json['heldAt'] != null
            ? DateTime.parse(json['heldAt'] as String)
            : null,
  );
}
