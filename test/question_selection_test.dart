import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talim_nazorat/core/constants/psychological_questions_seed.dart';
import 'package:talim_nazorat/models/assessment_model.dart';
import 'package:talim_nazorat/models/assessment_plan_model.dart';
import 'package:talim_nazorat/models/assessment_question_model.dart';
import 'package:talim_nazorat/models/development_profile_model.dart';
import 'package:talim_nazorat/models/student_model.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/services/local_db_service.dart';
import 'package:talim_nazorat/services/question_selection_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = QuestionSelectionService();
  final bank = PsychologicalQuestionsSeed.initialQuestions;
  AssessmentQuestionModel q(String id) => bank.firstWhere((x) => x.id == id);

  StudentModel child({
    required String grade,
    int age = 10,
    StudentAccessProfile? profile,
    Map<String, DomainLevel> levels = const {},
  }) {
    final now = DateTime.now();
    return StudentModel(
      id: 'child_$grade',
      institutionId: 'inst_chortoq_5',
      institutionName: '5-sonli umumiy o‘rta ta’lim maktabi',
      firstName: 'Test',
      lastName: 'Bola',
      dateOfBirth: DateTime(now.year - age, 1, 1),
      gender: 'Erkak',
      grade: grade,
      status: 'Faol',
      primaryNeed: 'Test',
      supportLevel: '1-daraja',
      createdAt: now,
      accessProfile: profile,
      domainLevels: levels,
    );
  }

  StudentAccessProfile profile({
    CommunicationMode mode = CommunicationMode.verbal,
    AbilityLevel hearing = AbilityLevel.full,
    AbilityLevel vision = AbilityLevel.full,
    AbilityLevel handMotor = AbilityLevel.full,
    AbilityLevel reading = AbilityLevel.full,
  }) => StudentAccessProfile(
    communicationMode: mode,
    hearing: hearing,
    vision: vision,
    handMotor: handMotor,
    reading: reading,
    updatedAt: DateTime.now(),
  );

  Set<String> ids(List<QuestionFit> fits) => fits.map((f) => f.question.id).toSet();

  group('Grade is the default', () {
    test('grade text is parsed into a grade number', () {
      expect(GradeBand.parseGrade('3-A'), 3);
      expect(GradeBand.parseGrade('10-B sinf'), 10);
      expect(GradeBand.parseGrade('Tayyorlov guruhi'), 0);
      expect(GradeBand.parseGrade('?'), isNull);
    });

    test('unknown grade falls back to age (7 years ≈ grade 1)', () {
      expect(service.studentGrade(child(grade: '?', age: 9)), 3);
    });

    test('question grade ranges: explicit, from "(1-4 sinf)" text, or from age', () {
      expect(q('q_kog_01').gradeRange, (min: 1, max: 4));
      expect(q('q_kog_911_01').gradeRange, (min: 9, max: 11));
      expect(q('q_emo_02').gradeRange, isNull); // barcha sinflar
      final fromAge = q('q_kog_01').copyWith(targetAgeRange: '8–10 yosh');
      expect(
        AssessmentQuestionModel(
          id: 'x', text: 'x', domain: 'd', questionType: 'yes_no',
          authorId: 'a', authorName: 'a', createdAt: DateTime.now(),
          targetAgeRange: fromAge.targetAgeRange,
        ).gradeRange,
        (min: 2, max: 4),
      );
    });

    test('every grade gets a default set in every domain', () {
      const domains = [
        'Kognitiv va intellekt',
        'Diqqat va xotira',
        'Emotsional va xavotir',
        'Ijtimoiy moslashuv va motivatsiya',
        'Xulq-atvor va iroda',
      ];
      for (final g in ['1-A', '3-A', '5-A', '7-A', '9-A', '10-A', '11-A']) {
        for (final d in domains) {
          final set = service.defaultSet(bank, child(grade: g, profile: profile()), domain: d);
          expect(set, isNotEmpty, reason: '$g sinf, $d');
        }
      }
    });

    test('grade 3 gets primary questions, not upper-grade ones', () {
      final set = ids(service.defaultSet(bank, child(grade: '3-A', profile: profile())));
      expect(set, contains('q_kog_01'));
      expect(set, isNot(contains('q_kog_911_01')));
      expect(set, isNot(contains('q_kog_58_01')));
    });

    test('grade 10 gets the harder upper-grade questions, not primary ones', () {
      final set = ids(service.defaultSet(bank, child(grade: '10-A', age: 16, profile: profile())));
      expect(set, containsAll(['q_kog_911_01', 'q_kog_911_02', 'q_diq_911_01']));
      expect(set, isNot(contains('q_kog_01')));
      expect(set, isNot(contains('q_kog_58_01')));
    });

    test('"all grades" questions are in everyone\'s default set', () {
      for (final g in ['1-A', '6-A', '10-A']) {
        expect(ids(service.defaultSet(bank, child(grade: g, profile: profile()))),
            contains('q_emo_02'));
      }
    });
  });

  group('Psychologist can adjust the working grade', () {
    const d = 'Kognitiv va intellekt';

    test('working grade defaults to the child\'s own grade', () {
      final c = child(grade: '5-A');
      expect(service.workingGrade(c, d), 5);
      expect(service.hasCustomLevel(c, d), false);
    });

    test('grade 5 child working at grade 2 level gets primary questions in that domain only', () {
      final c = child(grade: '5-A', profile: profile(), levels: {
        d: DomainLevel(domain: d, workingGrade: 2, setAt: DateTime.now()),
      });
      final cognitive = ids(service.defaultSet(bank, c, domain: d));
      expect(cognitive, contains('q_kog_01'));
      expect(cognitive, isNot(contains('q_kog_58_01')));
      // Boshqa yo'nalishlarda o'z sinfi (5) savollari
      final behaviour = ids(service.defaultSet(bank, c, domain: 'Xulq-atvor va iroda'));
      expect(behaviour, contains('q_xul_58_01'));
    });

    test('a question for another grade is not recommended, with the reason', () {
      final fit = service.evaluate(q('q_kog_911_01'), child(grade: '3-A', profile: profile()));
      expect(fit.gradeMatches, false);
      expect(fit.isRecommended, false);
      expect(fit.reasons.join(), contains('Sinf mos emas'));
    });
  });

  group('Accessibility by what the child can do', () {
    test('deaf child: auditory memory test is not suitable', () {
      final c = child(grade: '2-A', profile: profile(hearing: AbilityLevel.none,
          mode: CommunicationMode.signLanguage));
      expect(service.evaluate(q('q_diq_02'), c).suitability,
          QuestionSuitability.unsuitable);
    });

    test('deaf child: verbal-instruction item can be adapted', () {
      final c = child(grade: '2-A', profile: profile(hearing: AbilityLevel.none,
          mode: CommunicationMode.signLanguage));
      final fit = service.evaluate(q('q_xul_01'), c);
      expect(fit.suitability, QuestionSuitability.needsAdaptation);
      expect(fit.reasons.join(), contains('Moslashtirish'));
    });

    test('deaf grade 10 student: backwards-digits task is left out of the default set', () {
      final c = child(grade: '10-A', age: 16, profile: profile(
          hearing: AbilityLevel.none, mode: CommunicationMode.signLanguage));
      final set = ids(service.defaultSet(bank, c));
      expect(set, isNot(contains('q_diq_911_01')));
      expect(set, contains('q_diq_911_02')); // kuzatuv savoli qoladi
    });

    test('cerebral palsy: hand-motor task needs adaptation', () {
      final c = child(grade: '2-A', profile: profile(handMotor: AbilityLevel.none));
      expect(service.evaluate(q('q_kog_02'), c).suitability,
          QuestionSuitability.needsAdaptation);
    });

    test('blind child: visual memory test is not suitable', () {
      final c = child(grade: '2-A', profile: profile(vision: AbilityLevel.none));
      expect(service.evaluate(q('q_diq_03'), c).suitability,
          QuestionSuitability.unsuitable);
    });

    test('partial ability means adaptation, not exclusion', () {
      final c = child(grade: '2-A', profile: profile(hearing: AbilityLevel.partial,
          mode: CommunicationMode.limitedSpeech));
      expect(service.evaluate(q('q_diq_02'), c).suitability,
          QuestionSuitability.needsAdaptation);
    });

    test('missing profile gives a warning instead of guessing', () {
      final fit = service.evaluate(q('q_diq_02'), child(grade: '2-A'));
      expect(fit.suitability, QuestionSuitability.suitable);
      expect(fit.warnings, isNotEmpty);
    });

    test('ranking puts suitable first and unsuitable last', () {
      final c = child(grade: '2-A', profile: profile(hearing: AbilityLevel.none,
          mode: CommunicationMode.signLanguage));
      final ranked = service.rankForStudent(bank, c);
      expect(ranked.length, bank.length);
      final order = ranked.map((f) => f.suitability.index).toList();
      for (var i = 1; i < order.length; i++) {
        expect(order[i] >= order[i - 1], true);
      }
      expect(ranked.last.suitability, QuestionSuitability.unsuitable);
    });
  });

  group('Re-assessment and level changes', () {
    test('level advice moves one grade group down or up', () {
      expect(service.adviseLevelChange(0.2, 5).suggestion, LevelSuggestion.lower);
      expect(service.adviseLevelChange(0.2, 5).suggestedGrade, 4);
      expect(service.adviseLevelChange(0.6, 5).suggestion, LevelSuggestion.keep);
      expect(service.adviseLevelChange(0.95, 5).suggestion, LevelSuggestion.higher);
      expect(service.adviseLevelChange(0.95, 5).suggestedGrade, 7);
      expect(service.adviseLevelChange(0.1, 0).suggestion, LevelSuggestion.keep);
      expect(service.adviseLevelChange(0.99, 11).suggestion, LevelSuggestion.keep);
    });

    test('only assessments with the same question set are comparable', () {
      AssessmentModel a(List<String> qids, {String student = 's1'}) =>
          AssessmentModel.fromJson({
            'id': 'a_${qids.join()}_$student',
            'studentId': student,
            'studentName': 'Bola',
            'specialistId': 'psy',
            'category': 'Diqqat va xotira',
            'title': 't',
            'totalScore': 1.0,
            'maxScore': 2.0,
            'questionIds': qids,
            'status': 'completed',
            'assessmentDate': DateTime.now().toIso8601String(),
            'createdAt': DateTime.now().toIso8601String(),
          });
      expect(service.areComparable(a(['q1', 'q2']), a(['q2', 'q1'])), true);
      expect(service.areComparable(a(['q1', 'q2']), a(['q1', 'q3'])), false);
      expect(service.areComparable(a(['q1']), a(['q1'], student: 's2')), false);
    });
  });

  group('Storage and permissions', () {
    final db = LocalDbService();
    const domain = 'Diqqat va xotira';

    final psychologist = UserModel(
      id: 'psy_sel',
      email: 'psy.sel@talim.uz',
      fullName: 'Psixolog',
      role: UserRole.psychologist,
      institutionId: 'inst_chortoq_5',
      institutionName: '5-sonli umumiy o‘rta ta’lim maktabi',
      assignedStudentIds: const ['student_01'],
    );
    final teacher = UserModel(
      id: 'teacher_sel',
      email: 'teacher.sel@talim.uz',
      fullName: 'O‘qituvchi',
      role: UserRole.teacher,
      institutionId: 'inst_chortoq_5',
      institutionName: '5-sonli umumiy o‘rta ta’lim maktabi',
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db.resetForTest();
      await db.init();
    });

    test('psychologist saves access profile and working grade; they persist', () async {
      await db.updateAccessProfile('student_01',
          profile(hearing: AbilityLevel.none), byUser: psychologist);
      await db.setDomainLevel('student_01', domain, 2, byUser: psychologist);

      db.resetForTest();
      await db.init();
      final s = db.getStudentById('student_01')!;
      expect(s.accessProfile?.hearing, AbilityLevel.none);
      expect(s.accessProfile?.updatedById, psychologist.id);
      expect(s.domainLevels[domain]?.workingGrade, 2);
    });

    test('clearing the working grade returns the child to their own grade', () async {
      await db.setDomainLevel('student_01', domain, 2, byUser: psychologist);
      await db.setDomainLevel('student_01', domain, null, byUser: psychologist);
      expect(db.getStudentById('student_01')!.domainLevels.containsKey(domain), false);
    });

    test('teacher cannot change the access profile or working grade', () async {
      expect(
        () => db.updateAccessProfile('student_01', profile(), byUser: teacher),
        throwsException,
      );
      expect(
        () => db.setDomainLevel('student_01', domain, 2, byUser: teacher),
        throwsException,
      );
    });

    test('new plan replaces the active one, old plan is kept as history', () async {
      AssessmentPlanModel plan(String id, List<String> qids) => AssessmentPlanModel(
            id: id,
            studentId: 'student_01',
            domain: domain,
            workingGrade: 3,
            questionIds: qids,
            createdById: '',
            createdByName: '',
            createdAt: DateTime.now(),
          );
      await db.saveAssessmentPlan(plan('p1', ['q_diq_01']), byUser: psychologist);
      await db.saveAssessmentPlan(plan('p2', ['q_diq_01', 'q_diq_03']),
          byUser: psychologist);

      final active = db.getActivePlan(
          forUser: psychologist, studentId: 'student_01', domain: domain);
      expect(active?.id, 'p2');
      final all = db.getAssessmentPlans(forUser: psychologist, studentId: 'student_01');
      expect(all.length, 2);
      final old = all.firstWhere((p) => p.id == 'p1');
      expect(old.isActive, false);
      expect(old.replacedByPlanId, 'p2');
    });

    test('empty plan is refused', () async {
      expect(
        () => db.saveAssessmentPlan(
          AssessmentPlanModel(
            id: 'p_empty',
            studentId: 'student_01',
            domain: domain,
            workingGrade: 3,
            questionIds: const [],
            createdById: '',
            createdByName: '',
            createdAt: DateTime.now(),
          ),
          byUser: psychologist,
        ),
        throwsException,
      );
    });

    test('old saved data loads, and new standard questions are added on update', () async {
      final oldStudent = {
        'id': 'old_s',
        'institutionId': 'inst_chortoq_5',
        'institutionName': '5-sonli umumiy o‘rta ta’lim maktabi',
        'firstName': 'Eski',
        'lastName': 'Yozuv',
        'dateOfBirth': '2015-01-01T00:00:00.000',
        'gender': 'Erkak',
        'grade': '3-A',
        'status': 'Faol',
        'primaryNeed': 'Test',
        'supportLevel': '1-daraja',
        'createdAt': '2024-01-01T00:00:00.000',
      };
      // Eski versiyada saqlangan standart savol (sinf va talablarsiz)
      final oldStandard = q('q_kog_01').toJson()
        ..remove('requirements')
        ..remove('adaptationHint')
        ..remove('minGrade')
        ..remove('maxGrade');
      final ownQuestion = {
        'id': 'own_q',
        'text': 'Psixolog savoli',
        'domain': domain,
        'targetAgeRange': '7–10 yosh',
        'questionType': 'yes_no',
        'authorId': 'x',
        'authorName': 'x',
        'createdAt': '2024-01-01T00:00:00.000',
      };
      SharedPreferences.setMockInitialValues({
        'app_db_seeded_v2': true,
        'db_students': jsonEncode([oldStudent]),
        'db_questions': jsonEncode([oldStandard, ownQuestion]),
      });
      db.resetForTest();
      await db.init();
      expect(db.loadErrors, isEmpty);

      final s = db.getStudentById('old_s')!;
      expect(s.accessProfile, isNull);
      expect(s.domainLevels, isEmpty);

      // Yangi standart savollar qo'shildi
      expect(db.getQuestionById('q_kog_911_01'), isNotNull);
      // Eski standart savolga sinf va talablar to'ldirildi
      final upgraded = db.getQuestionById('q_kog_01')!;
      expect(upgraded.minGrade, 1);
      expect(upgraded.requirements, isNotNull);
      // Psixolog savoliga tegilmadi
      final own = db.getQuestionById('own_q')!;
      expect(own.requirements, isNull);
      expect(own.gradeRange, (min: 1, max: 4));
    });
  });
}
