class AuditLogModel {
  final String id;
  final String userFullName;
  final String userRole;
  final String action; // CREATE, UPDATE, DELETE, VIEW, LOGIN
  final String entity; // Student, Assessment, Session, IEP
  final String details;
  final DateTime timestamp;

  AuditLogModel({
    required this.id,
    required this.userFullName,
    required this.userRole,
    required this.action,
    required this.entity,
    required this.details,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userFullName': userFullName,
    'userRole': userRole,
    'action': action,
    'entity': entity,
    'details': details,
    'timestamp': timestamp.toIso8601String(),
  };

  factory AuditLogModel.fromJson(Map<String, dynamic> json) => AuditLogModel(
    id: json['id'] as String,
    userFullName: json['userFullName'] as String,
    userRole: json['userRole'] as String,
    action: json['action'] as String,
    entity: json['entity'] as String,
    details: json['details'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}
