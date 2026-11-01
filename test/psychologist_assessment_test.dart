import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talim_nazorat/core/constants/psychological_questions_seed.dart';
import 'package:talim_nazorat/models/assessment_model.dart';
import 'package:talim_nazorat/models/assessment_question_model.dart';
import 'package:talim_nazorat/models/assessment_response_model.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/providers/app_provider.dart';
import 'package:talim_nazorat/services/local_db_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Psychologist Assessment Question Model & Bank Tests', () {
    test('Seed question bank provides valid questions across 5 domains and 5 types', () {
      final seeds = PsychologicalQuestionsSeed.standardQuestions;
      expect(seeds.length, greaterThanOrEqualTo(10));

      final domains = seeds.map((q) => q.domain).toSet();
      expect(domains.length, greaterThanOrEqualTo(4));

      final types = seeds.map((q) => q.questionType).toSet();
      expect(types.contains('yes_no'), isTrue);
      expect(types.contains('single_choice'), isTrue);
      expect(types.contains('multiple_choice'), isTrue);
      expect(types.contains('scale_1_5'), isTrue);
      expect(types.contains('open_text'), isTrue);
    });

    test('AssessmentQuestionModel serializes to JSON and deserializes correctly', () {
      final q = AssessmentQuestionModel(
        id: 'q_test_1',
        title: 'Mantiqiy qatorlarni davom ettirish',
        text: 'Predmetlarning qonuniyatli ketma-ketligini toping',
        domain: 'Kognitiv va intellektual rivojlanish',
        targetAgeRange: '1-4 sinf (7-10 yosh)',
        questionType: 'single_choice',
        options: const [
          AssessmentQuestionOption(id: 'opt_1', text: 'To‘g‘ri ketma-ketlik', score: 5.0),
          AssessmentQuestionOption(id: 'opt_2', text: 'Xato ketma-ketlik', score: 1.0),
        ],
        scoringCriteria: '5 ball mustaqil yechim uchun',
        psychologistNotes: 'Ikkilanish vaqtini qayd eting',
        authorId: 'user_psy',
        authorName: 'Usmonova Dilnoza',
        isStandard: false,
        status: 'ready',
        createdAt: DateTime(2025, 1, 15),
      );

      final json = q.toJson();
      final reconstructed = AssessmentQuestionModel.fromJson(json);

      expect(reconstructed.id, equals('q_test_1'));
      expect(reconstructed.title, equals('Mantiqiy qatorlarni davom ettirish'));
      expect(reconstructed.domain, equals('Kognitiv va intellektual rivojlanish'));
      expect(reconstructed.options.length, equals(2));
      expect(reconstructed.options.first.score, equals(5.0));
      expect(reconstructed.status, equals('ready'));
      expect(reconstructed.isStandard, isFalse);
    });

    test('AssessmentResponseModel distinguishes between evaluated and unassessed questions', () {
      final evaluated = AssessmentResponseModel(
        questionId: 'q_1',
        questionTitle: 'Diqqat barqarorligi',
        questionText: 'Shulte jadvalini bajarish',
        domain: 'Ixtiyoriy diqqat',
        questionType: 'scale_1_5',
        answer: '4 ball',
        answerDisplay: '4 ball',
        score: 4.0,
        maxScore: 5.0,
        isEvaluated: true,
        psychologistNotes: 'Qiziqish bilan bajardi',
      );

      final skipped = AssessmentResponseModel(
        questionId: 'q_2',
        questionTitle: 'Nutqiy leksika',
        questionText: 'Erkin hikoya qilish',
        domain: 'Nutq va muloqot',
        questionType: 'open_text',
        isEvaluated: false,
      );

      expect(evaluated.isEvaluated, isTrue);
      expect(evaluated.score, equals(4.0));
      expect(skipped.isEvaluated, isFalse);
      expect(skipped.score, isNull);
      expect(skipped.answer, isNull);
    });
  });

  group('LocalDbService & AppProvider Assessment Lifecycle Tests', () {
    late LocalDbService db;
    late AppProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = LocalDbService();
      await db.init();
      provider = AppProvider();

      provider.setCurrentUser(
        UserModel(
          id: 'user_psy_test',
          email: 'psy@talim.uz',
          fullName: 'Usmonova Dilnoza',
          role: UserRole.superAdmin,
        ),
      );
    });

    test('Initializes with seed questions in the database', () {
      final questions = db.getQuestions();
      expect(questions.length, greaterThanOrEqualTo(10));
      expect(provider.questions.length, equals(questions.length));
    });

    test('Psychologist can create a new custom question in library', () async {
      final customQ = AssessmentQuestionModel(
        id: 'q_custom_99',
        title: 'Shaxsiy ijtimoiy moslashuv testi',
        text: 'Jamoaviy topshiriqda tashabbus ko‘rsatish darajasi',
        domain: 'Ijtimoiy moslashuv va motivatsiya',
        targetAgeRange: '5-9 sinf',
        questionType: 'scale_1_5',
        options: const [
          AssessmentQuestionOption(id: 'o1', text: '1 - Chetlashadi', score: 1.0),
          AssessmentQuestionOption(id: 'o5', text: '5 - Yetakchilik qiladi', score: 5.0),
        ],
        scoringCriteria: 'Me’yoriy moslashuv 3-5 ball',
        psychologistNotes: 'Tengdoshlar bilan o‘zaro harakatini kuzating',
        authorId: 'user_psy_test',
        authorName: 'Usmonova Dilnoza',
        isStandard: false,
        status: 'ready',
        createdAt: DateTime.now(),
      );

      await provider.addQuestion(customQ);

      expect(provider.questions.any((q) => q.id == 'q_custom_99'), isTrue);
      expect(provider.myQuestions.any((q) => q.id == 'q_custom_99'), isTrue);

      // Filtered lookup
      final filtered = provider.getQuestionsFiltered(
        domain: 'Ijtimoiy moslashuv va motivatsiya',
        query: 'tashabbus',
      );
      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('q_custom_99'));
    });

    test('Psychologist can edit and delete custom question', () async {
      final q = AssessmentQuestionModel(
        id: 'q_to_delete',
        title: 'Vaqtinchalik sinov savoli',
        text: 'Sinov matni',
        domain: 'Kognitiv va intellektual rivojlanish',
        targetAgeRange: '1-4 sinf',
        questionType: 'open_text',
        options: const [],
        scoringCriteria: '',
        psychologistNotes: '',
        authorId: 'user_psy_test',
        authorName: 'Usmonova Dilnoza',
        isStandard: false,
        status: 'draft',
        createdAt: DateTime.now(),
      );

      await provider.addQuestion(q);
      expect(provider.getQuestionById('q_to_delete'), isNotNull);

      // Edit
      final updatedQ = q.copyWith(title: 'Yangilangan savol nomi', status: 'ready');
      await provider.updateQuestion(updatedQ);
      expect(provider.getQuestionById('q_to_delete')!.title, equals('Yangilangan savol nomi'));
      expect(provider.getQuestionById('q_to_delete')!.status, equals('ready'));

      // Delete
      await provider.deleteQuestion('q_to_delete');
      expect(provider.getQuestionById('q_to_delete'), isNull);
    });

    test('Assessment creation as draft, updating responses, and completing assessment', () async {
      final student = provider.students.first;

      final draftAssessment = AssessmentModel(
        id: 'ass_test_101',
        studentId: student.id,
        studentName: student.fullName,
        specialistId: 'user_psy_test',
        specialistName: 'Usmonova Dilnoza',
        specialistRole: 'Amaliyotchi psixolog',
        assessmentDate: DateTime.now(),
        type: 'Psixologik diagnostika (Kutubxona asosida)',
        category: 'Kognitiv va intellektual rivojlanish',
        title: 'Diagnostik test seansi',
        notes: '',
        recommendations: '',
        totalScore: 0.0,
        maxScore: 10.0,
        previousScore: null,
        reviewDate: DateTime.now().add(const Duration(days: 60)),
        questionIds: const ['q_cog_1', 'q_cog_2'],
        responses: [
          AssessmentResponseModel(
            questionId: 'q_cog_1',
            questionTitle: 'Mantiqiy qatorlar',
            questionText: 'Ketma-ketlikni topish',
            domain: 'Kognitiv',
            questionType: 'scale_1_5',
            maxScore: 5.0,
            isEvaluated: false,
          ),
          AssessmentResponseModel(
            questionId: 'q_cog_2',
            questionTitle: 'Analogiyalar',
            questionText: 'Mantiqiy o‘xshashlik',
            domain: 'Kognitiv',
            questionType: 'scale_1_5',
            maxScore: 5.0,
            isEvaluated: false,
          ),
        ],
        status: 'draft',
      );

      await provider.addAssessment(draftAssessment);
      expect(provider.assessments.any((a) => a.id == 'ass_test_101'), isTrue);
      expect(provider.assessments.firstWhere((a) => a.id == 'ass_test_101').status, equals('draft'));

      // Complete the assessment with actual responses
      final completedResponses = <AssessmentResponseModel>[
        AssessmentResponseModel(
          questionId: 'q_cog_1',
          questionTitle: 'Mantiqiy qatorlar',
          questionText: 'Ketma-ketlikni topish',
          domain: 'Kognitiv',
          questionType: 'scale_1_5',
          answer: '4 ball',
          answerDisplay: '4 ball',
          score: 4.0,
          maxScore: 5.0,
          isEvaluated: true,
          psychologistNotes: 'Topshiriqni mustaqil bajardi',
        ),
        AssessmentResponseModel(
          questionId: 'q_cog_2',
          questionTitle: 'Analogiyalar',
          questionText: 'Mantiqiy o‘xshashlik',
          domain: 'Kognitiv',
          questionType: 'scale_1_5',
          answer: '5 ball',
          answerDisplay: '5 ball',
          score: 5.0,
          maxScore: 5.0,
          isEvaluated: true,
          psychologistNotes: 'Tezkor va aniq javob berdi',
        ),
      ];

      final completedAssessment = draftAssessment.copyWith(
        responses: completedResponses,
        totalScore: 9.0,
        maxScore: 10.0,
        generalConclusion: 'Mantiqiy tafakkur yuqori darajada rivojlangan.',
        recommendations: 'Murakkablashtirilgan ijodiy topshiriqlar berish maqsadga muvofiq.',
        domainScores: {'Kognitiv': 90.0},
        status: 'completed',
        updatedAt: DateTime.now(),
      );

      await provider.updateAssessment(completedAssessment);

      final saved = provider.assessments.firstWhere((a) => a.id == 'ass_test_101');
      expect(saved.status, equals('completed'));
      expect(saved.totalScore, equals(9.0));
      expect(saved.percentage, equals(90.0));
      expect(saved.domainScores?['Kognitiv'], equals(90.0));
      expect(saved.responses.every((r) => r.isEvaluated), isTrue);
    });

    test('Deleting an assessment removes it safely from the database with audit', () async {
      final a = AssessmentModel(
        id: 'ass_to_remove',
        studentId: 'student_01',
        studentName: 'Aliyev Behruz',
        specialistId: 'user_psy_test',
        specialistName: 'Usmonova Dilnoza',
        specialistRole: 'Amaliyotchi psixolog',
        assessmentDate: DateTime.now(),
        type: 'Test',
        category: 'Kognitiv',
        title: 'O‘chiriladigan baholash',
        notes: '',
        recommendations: '',
        totalScore: 50.0,
        maxScore: 100.0,
        status: 'draft',
      );

      await provider.addAssessment(a);
      expect(provider.assessments.any((x) => x.id == 'ass_to_remove'), isTrue);

      await provider.deleteAssessment('ass_to_remove');
      expect(provider.assessments.any((x) => x.id == 'ass_to_remove'), isFalse);
    });
  });
}
