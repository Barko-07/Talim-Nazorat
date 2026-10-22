class NotificationModel {
  final String id;
  final String recipientUserId;
  final String title;
  final String body;
  final String type; // 'ASSESSMENT', 'SESSION', 'IEP', 'REFERRAL', 'ALERT', 'ASSIGNMENT'
  final String? relatedRecordId;
  final String? relatedStudentId;
  final String? relatedStudentName;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.recipientUserId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedRecordId,
    this.relatedStudentId,
    this.relatedStudentName,
    this.isRead = false,
    required this.createdAt,
  });

  NotificationModel copyWith({
    bool? isRead,
  }) {
    return NotificationModel(
      id: id,
      recipientUserId: recipientUserId,
      title: title,
      body: body,
      type: type,
      relatedRecordId: relatedRecordId,
      relatedStudentId: relatedStudentId,
      relatedStudentName: relatedStudentName,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipientUserId': recipientUserId,
        'title': title,
        'body': body,
        'type': type,
        'relatedRecordId': relatedRecordId,
        'relatedStudentId': relatedStudentId,
        'relatedStudentName': relatedStudentName,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        recipientUserId: json['recipientUserId'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: json['type'] as String,
        relatedRecordId: json['relatedRecordId'] as String?,
        relatedStudentId: json['relatedStudentId'] as String?,
        relatedStudentName: json['relatedStudentName'] as String?,
        isRead: json['isRead'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
