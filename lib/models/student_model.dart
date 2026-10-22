class GuardianModel {
  final String id;
  final String fullName;
  final String relationship; // Ota, Ona, Vasiy
  final String phone;
  final String? email;
  final String? address;

  GuardianModel({
    required this.id,
    required this.fullName,
    required this.relationship,
    required this.phone,
    this.email,
    this.address,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'relationship': relationship,
        'phone': phone,
        'email': email,
        'address': address,
      };

  factory GuardianModel.fromJson(Map<String, dynamic> json) => GuardianModel(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        relationship: json['relationship'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        address: json['address'] as String?,
      );
}

class StudentModel {
  final String id;
  final String institutionId;
  final String institutionName;
  final String firstName;
  final String lastName;
  final String? middleName;
  final DateTime dateOfBirth;
  final String gender; // Erkak, Ayol
  final String grade; // 1-A sinf, 2-B sinf
  final String status; // Faol, Ta'tilda, Bitirgan
  final String primaryNeed; // Ta'limiy ehtiyoj toifasi
  final String supportLevel; // 1-daraja (Yengil), 2-daraja (O'rta), 3-daraja (Intensiv)
  final String? medicalNotes;
  final String? psychologicalNotes;
  final List<GuardianModel> guardians;
  final List<String> assignedSpecialistIds;
  final DateTime createdAt;

  StudentModel({
    required this.id,
    required this.institutionId,
    required this.institutionName,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.dateOfBirth,
    required this.gender,
    required this.grade,
    required this.status,
    required this.primaryNeed,
    required this.supportLevel,
    this.medicalNotes,
    this.psychologicalNotes,
    this.guardians = const [],
    this.assignedSpecialistIds = const [],
    required this.createdAt,
  });

  String get fullName => '$lastName $firstName ${middleName ?? ''}'.trim();

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'institutionId': institutionId,
        'institutionName': institutionName,
        'firstName': firstName,
        'lastName': lastName,
        'middleName': middleName,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'gender': gender,
        'grade': grade,
        'status': status,
        'primaryNeed': primaryNeed,
        'supportLevel': supportLevel,
        'medicalNotes': medicalNotes,
        'psychologicalNotes': psychologicalNotes,
        'guardians': guardians.map((g) => g.toJson()).toList(),
        'assignedSpecialistIds': assignedSpecialistIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
        id: json['id'] as String,
        institutionId: json['institutionId'] as String,
        institutionName: json['institutionName'] as String? ?? '14-Inklyuziv maktab',
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        middleName: json['middleName'] as String?,
        dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
        gender: json['gender'] as String,
        grade: json['grade'] as String,
        status: json['status'] as String,
        primaryNeed: json['primaryNeed'] as String,
        supportLevel: json['supportLevel'] as String,
        medicalNotes: json['medicalNotes'] as String?,
        psychologicalNotes: json['psychologicalNotes'] as String?,
        guardians: (json['guardians'] as List<dynamic>?)
                ?.map((g) => GuardianModel.fromJson(g as Map<String, dynamic>))
                .toList() ??
            [],
        assignedSpecialistIds: (json['assignedSpecialistIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
