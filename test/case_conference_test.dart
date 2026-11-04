import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talim_nazorat/models/case_conference_model.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/models/work_record_model.dart';
import 'package:talim_nazorat/services/app_exceptions.dart';
import 'package:talim_nazorat/services/local_db_service.dart';

/// Konsilium: rejalashtirish -> ishtirokchilar xulosasi -> umumiy xulosa va qarorlar -> ijro.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final db = LocalDbService();
  const school = '5-sonli umumiy o‘rta ta’lim maktabi';
  final coordinator = UserModel(
    id: 'cc_coord',
    email: 'cc.coord@talim.uz',
    fullName: 'Koordinator',
    role: UserRole.coordinator,
    institutionId: 'inst_chortoq_5',
    institutionName: school,
  );

  late UserModel psy;
  late UserModel speech;
  late UserModel teacher;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db.resetForTest();
    await db.init();
    psy = db.getUserById('user_psychologist')!;
    speech = db.getUserById('user_speech')!;
    teacher = db.getUserById('user_teacher')!;
  });

  CaseConference draft({
    List<String>? participants,
    String agenda = 'Nutq va xavotir',
  }) => CaseConference(
    id: 'conf_1',
    studentId: 'student_02',
    studentName: '',
    agenda: agenda,
    scheduledAt: DateTime.now().add(const Duration(days: 2)),
    convenedById: '',
    convenedByName: '',
    participantIds: participants ?? [psy.id, speech.id],
  );

  test(
    'full flow: schedule, contributions, conclusion, decisions, completion',
    () async {
      final conf = await db.scheduleConference(draft(), byUser: coordinator);
      expect(conf.convenedById, coordinator.id);
      expect(conf.pendingParticipantIds, [psy.id, speech.id]);
      expect(
        db.getNotifications(psy.id).any((n) => n.type == 'CONFERENCE'),
        true,
      );

      await db.addConferenceContribution(
        conf.id,
        summary: 'Xavotir darajasi baland, ayniqsa nazorat ishlarida.',
        byUser: psy,
      );
      final afterSpeech = await db.addConferenceContribution(
        conf.id,
        summary: 'R tovushi qo‘yilgan, avtomatlashtirish kerak.',
        byUser: speech,
      );
      expect(afterSpeech.pendingParticipantIds, isEmpty);

      // Ishtirokchining konsilium xulosasi ham bola bilan qilingan ish hisoblanadi
      expect(
        db
            .getWorkRecords('student_02')
            .where((r) => r.kind == WorkKind.conference)
            .length,
        2,
      );

      final held = await db.finalizeConference(
        conf.id,
        conclusion:
            'Psixologik qo‘llab-quvvatlash va logopedik mashg‘ulotlarni davom ettirish.',
        decisions: [
          ConferenceDecision(
            id: 'd1',
            text: 'Haftasiga 2 marta xavotirni kamaytirish mashg‘uloti',
            responsibleId: psy.id,
            responsibleName: '',
            dueDate: DateTime.now().add(const Duration(days: 30)),
          ),
        ],
        byUser: coordinator,
      );
      expect(held.status, ConferenceStatus.held);
      expect(held.decisions.single.responsibleName, psy.fullName);
      expect(
        db.getNotifications(psy.id).any((n) => n.type == 'CONFERENCE_DECISION'),
        true,
      );

      final done = await db.completeConferenceDecision(
        conf.id,
        'd1',
        byUser: psy,
      );
      expect(done.decisions.single.isDone, true);

      // Saqlanadi
      db.resetForTest();
      await db.init();
      final reloaded =
          db
              .getConferences(forUser: coordinator, studentId: 'student_02')
              .single;
      expect(reloaded.contributions.length, 2);
      expect(reloaded.decisions.single.isDone, true);
    },
  );

  test(
    'only coordinator or director can schedule; at least 2 valid specialists',
    () async {
      await expectLater(
        db.scheduleConference(draft(), byUser: psy),
        throwsA(isA<PermissionDeniedException>()),
      );
      await expectLater(
        db.scheduleConference(
          draft(participants: [psy.id]),
          byUser: coordinator,
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        db.scheduleConference(
          draft(participants: [psy.id, 'user_admin']),
          byUser: coordinator,
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        db.scheduleConference(draft(agenda: ' '), byUser: coordinator),
        throwsA(isA<ValidationException>()),
      );
    },
  );

  test('only participants contribute; only the organiser finalizes', () async {
    final conf = await db.scheduleConference(draft(), byUser: coordinator);
    await expectLater(
      db.addConferenceContribution(conf.id, summary: 'x', byUser: teacher),
      throwsA(isA<PermissionDeniedException>()),
    );
    await expectLater(
      db.finalizeConference(
        conf.id,
        conclusion: 'x',
        decisions: const [],
        byUser: psy,
      ),
      throwsA(isA<PermissionDeniedException>()),
    );
  });

  test(
    'decision owner must be a participant; finalized conference is closed',
    () async {
      final conf = await db.scheduleConference(draft(), byUser: coordinator);
      await expectLater(
        db.finalizeConference(
          conf.id,
          conclusion: 'Xulosa',
          decisions: [
            ConferenceDecision(
              id: 'd',
              text: 'x',
              responsibleId: teacher.id,
              responsibleName: '',
            ),
          ],
          byUser: coordinator,
        ),
        throwsA(isA<ValidationException>()),
      );
      await db.finalizeConference(
        conf.id,
        conclusion: 'Xulosa',
        decisions: const [],
        byUser: coordinator,
      );
      await expectLater(
        db.addConferenceContribution(conf.id, summary: 'kech', byUser: psy),
        throwsA(isA<ValidationException>()),
      );
    },
  );

  test(
    'visible to participants and school leadership, not to other staff',
    () async {
      await db.scheduleConference(draft(), byUser: coordinator);
      expect(db.getConferences(forUser: psy), hasLength(1));
      expect(db.getConferences(forUser: coordinator), hasLength(1));
      expect(db.getConferences(forUser: teacher), isEmpty);
    },
  );
}
