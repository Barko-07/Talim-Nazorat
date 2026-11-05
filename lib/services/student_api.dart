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
      return StudentModel(
        id: map['id'] as String? ?? '',
        firstName: (map['full_name'] as String? ?? '').split(' ').first,
        lastName: (map['full_name'] as String? ?? '').split(' ').skip(1).join(' '),
        grade: map['grade'] as String? ?? '',
        dateOfBirth: DateTime.tryParse(map['birth_date'] as String? ?? '') ?? DateTime(2015, 1, 1),
        institutionName: map['institution_id'] as String? ?? '',
        primaryNeed: map['diagnosis'] as String? ?? 'Umumiy ta’limiy ehtiyoj',
        supportLevel: 'O‘rta',
        assignedSpecialistIds: (map['specialist_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        guardians: [
          Guardian(
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
        specialistId: map['specialist_id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        category: map['category'] as String? ?? '',
        assessmentDate: DateTime.tryParse(map['assessment_date'] as String? ?? '') ?? DateTime.now(),
        totalScore: (map['total_score'] as num?)?.toDouble() ?? 0.0,
        maxScore: (map['max_score'] as num?)?.toDouble() ?? 100.0,
        status: map['status'] as String? ?? 'completed',
        notes: map['notes'] as String?,
      );
    }).toList();
  }

  Future<void> createAssessment(String studentId, Map<String, dynamic> body) async {
    await _api.post('/api/students/$studentId/assessments', body);
  }
}

