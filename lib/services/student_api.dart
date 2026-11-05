import 'api_client.dart';
import '../models/student_model.dart';
import '../models/assessment_model.dart';

class StudentApi {
  StudentApi([ApiClient? client]) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  Future<List<StudentModel>> listStudents({String query = ''}) async {
    final path = query.isEmpty ? '/api/students' : '/api/students?q=${Uri.encodeComponent(query)}';
    final res = await _api.getList(path);
    return res.map((json) {
      final map = json as Map<String, dynamic>;
      final fullName = map['full_name'] as String? ?? '';
      final parts = fullName.split(' ');
      return StudentModel(
        id: map['id'] as String? ?? '',
        institutionId: map['institution_id'] as String? ?? '',
        institutionName: map['institution_name'] as String? ?? map['institution_id'] as String? ?? '',
        firstName: parts.isNotEmpty ? parts.first : '',
        lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
        gender: map['gender'] as String? ?? 'Erkak',
        grade: map['grade'] as String? ?? '',
        status: map['status'] as String? ?? 'Faol',
        dateOfBirth: DateTime.tryParse(map['birth_date'] as String? ?? '') ?? DateTime(2015, 1, 1),
        primaryNeed: map['diagnosis'] as String? ?? 'Umumiy ta’limiy ehtiyoj',
        supportLevel: 'O‘rta',
        assignedSpecialistIds: (map['specialist_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
        guardians: [
          GuardianModel(
            id: 'g_${map['id'] ?? ''}',
            relationship: 'Ota-onasi',
            fullName: map['guardian_name'] as String? ?? '',
            phone: map['guardian_phone'] as String? ?? '',
          ),
        ],
      );
    }).toList();
  }

  Future<void> createStudent(Map<String, dynamic> body) async {
    await _api.post('/api/students', body);
  }

  Future<void> updateStudent(String id, Map<String, dynamic> body) async {
    await _api.put('/api/students/$id', body);
  }

  Future<List<AssessmentModel>> listAssessments(String studentId) async {
    final res = await _api.getList('/api/students/$studentId/assessments');
    return res.map((json) {
      final map = json as Map<String, dynamic>;
      return AssessmentModel(
        id: map['id'] as String? ?? '',
        studentId: map['student_id'] as String? ?? studentId,
        studentName: map['student_name'] as String? ?? '',
        specialistId: map['specialist_id'] as String? ?? '',
        specialistName: map['specialist_name'] as String? ?? 'Mutaxassis',
        specialistRole: map['specialist_role'] as String? ?? 'Maxsus pedagog',
        title: map['title'] as String? ?? '',
        type: map['type'] as String? ?? 'Standart balli (Rubrikali)',
        category: map['category'] as String? ?? '',
        assessmentDate: DateTime.tryParse(map['assessment_date'] as String? ?? '') ?? DateTime.now(),
        totalScore: (map['total_score'] as num?)?.toDouble() ?? 0.0,
        maxScore: (map['max_score'] as num?)?.toDouble() ?? 100.0,
        status: map['status'] as String? ?? 'completed',
        notes: map['notes'] as String? ?? '',
        recommendations: map['recommendations'] as String? ?? '',
      );
    }).toList();
  }

  Future<void> createAssessment(String studentId, Map<String, dynamic> body) async {
    await _api.post('/api/students/$studentId/assessments', body);
  }
}

