import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talim_nazorat/core/constants/uzbek_speech_sounds.dart';
import 'package:talim_nazorat/models/achievement_model.dart';
import 'package:talim_nazorat/models/speech_sound_model.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/models/work_record_model.dart';
import 'package:talim_nazorat/services/achievement_service.dart';
import 'package:talim_nazorat/services/app_exceptions.dart';
import 'package:talim_nazorat/services/child_status_service.dart';
import 'package:talim_nazorat/services/dynamics_service.dart';
import 'package:talim_nazorat/services/local_db_service.dart';
import 'package:talim_nazorat/services/sound_tracker_service.dart';
import 'package:talim_nazorat/services/workspace_service.dart';

/// Logopedik tovushlar kartasi
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final db = LocalDbService();
  final tracker = SoundTrackerService();
  // Bazada logoped va psixolog ikkalasi ham biriktirilgan bola (setUp'da aniqlanadi)
  late String child;

  late UserModel speech;
  late UserModel psy;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db.resetForTest();
    await db.init();
    speech = db.getUserById('user_speech')!;
    psy = db.getUserById('user_psychologist')!;
    final psyChildren = db.getStudents(forUser: psy).map((s) => s.id).toSet();
    child = db
        .getStudents(forUser: speech)
        .map((s) => s.id)
        .firstWhere(psyChildren.contains);
  });

  var seq = 0;
  SoundEntry entry(
    String sound,
    SoundStage stage,
    DateTime at, {
    SoundDisorder disorder = SoundDisorder.none,
    String? substitutedWith,
    String? differentiatedFrom,
  }) => SoundEntry(
    id: 'se_${seq++}',
    studentId: child,
    soundId: sound,
    stage: stage,
    disorder: disorder,
    substitutedWith: substitutedWith,
    differentiatedFrom: differentiatedFrom,
    recordedById: '',
    recordedByName: '',
    recordedAt: at,
  );

  group('Sound inventory', () {
    test('ids are unique and every confusion pair points to a real sound', () {
      final ids = UzbekSpeechSounds.all.map((s) => s.id).toList();
      expect(ids.length, ids.toSet().length);
      for (final s in UzbekSpeechSounds.all) {
        for (final c in s.confusedWith) {
          expect(UzbekSpeechSounds.byId(c), isNotNull, reason: '${s.id} -> $c');
        }
      }
      for (final g in SoundGroup.values) {
        expect(UzbekSpeechSounds.inGroup(g), isNotEmpty, reason: g.label);
      }
    });

    test('the most often corrected sounds are present', () {
      for (final id in [
        'r',
        'l',
        's',
        'sh',
        'z',
        'j',
        'ch',
        'k',
        'g',
        'q',
        'g‘',
        'x',
        'h',
      ]) {
        expect(UzbekSpeechSounds.byId(id), isNotNull, reason: id);
      }
    });
  });

  group('Full correction journey of "r"', () {
    test(
      'substituted with "l" → set → automated → differentiated → free speech',
      () async {
        final start = DateTime(2026, 3, 1);
        final journey = [
          entry(
            'r',
            SoundStage.preparation,
            start,
            disorder: SoundDisorder.substitution,
            substitutedWith: 'l',
          ),
          entry(
            'r',
            SoundStage.staging,
            start.add(const Duration(days: 14)),
            disorder: SoundDisorder.substitution,
            substitutedWith: 'l',
          ),
          entry('r', SoundStage.syllables, start.add(const Duration(days: 28))),
          entry('r', SoundStage.words, start.add(const Duration(days: 45))),
          entry('r', SoundStage.phrases, start.add(const Duration(days: 60))),
          entry(
            'r',
            SoundStage.connectedSpeech,
            start.add(const Duration(days: 80)),
          ),
          entry(
            'r',
            SoundStage.differentiation,
            start.add(const Duration(days: 100)),
            differentiatedFrom: 'l',
          ),
          entry(
            'r',
            SoundStage.spontaneous,
            start.add(const Duration(days: 130)),
          ),
        ];
        for (final e in journey) {
          await db.recordSoundEntry(e, byUser: speech);
        }

        final profile = tracker.buildProfile(
          child,
          db.getSoundEntries(forUser: speech, studentId: child),
        );
        final r = profile.sounds.single;
        expect(r.history, hasLength(8));
        expect(r.first.substitutedWith, 'l');
        expect(r.isMastered, true);
        expect(r.completion, 1.0);
        expect(profile.mastered, hasLength(1));
        expect(r.dynamics.status, DynamicsStatus.growth);
        expect(r.current.recordedById, speech.id);

        // Yutuqlar pasporti: "qo'yildi" va "erkin nutqda"
        final titles =
            AchievementService()
                .passportFor(child, speech)
                .entries
                .where(
                  (a) =>
                      a.isAutomatic && a.category == AchievementCategory.skill,
                )
                .map((a) => a.title)
                .toList();
        expect(titles, contains('"r" tovushi qo‘yildi'));
        expect(titles, contains('"r" tovushi erkin nutqda to‘g‘ri'));

        // Ish yozuvi sifatida hisobga olinadi
        expect(
          db
              .getWorkRecords(child)
              .where((w) => w.kind == WorkKind.soundTracking)
              .length,
          8,
        );

        // Saqlanadi
        db.resetForTest();
        await db.init();
        expect(
          db.getSoundEntries(forUser: speech, studentId: child),
          hasLength(8),
        );
      },
    );

    test('next step suggests the right differentiation pairs', () async {
      await db.recordSoundEntry(
        entry('r', SoundStage.connectedSpeech, DateTime(2026, 5, 1)),
        byUser: speech,
      );
      final p =
          tracker
              .buildProfile(
                child,
                db.getSoundEntries(forUser: speech, studentId: child),
              )
              .sounds
              .single;
      final step = tracker.nextStep(p);
      expect(step, contains(SoundStage.differentiation.label));
      expect(step, contains('l'));
    });
  });

  group('Stuck sounds', () {
    test(
      '"sh" stuck at automation in words for 40+ days is ineffective and flagged',
      () async {
        final now = DateTime.now();
        for (final d in [45, 25, 2]) {
          await db.recordSoundEntry(
            entry('sh', SoundStage.words, now.subtract(Duration(days: d))),
            byUser: speech,
          );
        }
        final p =
            tracker
                .buildProfile(
                  child,
                  db.getSoundEntries(forUser: speech, studentId: child),
                )
                .sounds
                .single;
        expect(p.dynamics.status, DynamicsStatus.ineffective);
        expect(p.daysAtCurrentStage(now), greaterThanOrEqualTo(45));

        // Logoped kabinetida ogohlantirish
        final kinds = WorkspaceService()
            .dashboardFor(speech)
            .attention
            .where((a) => a.student.id == child)
            .map((a) => a.kind);
        expect(kinds, contains(AttentionKind.soundStuck));

        // Bola holatida sariq sabab
        final coordinator = UserModel(
          id: 'st_coord',
          email: 'st.c@talim.uz',
          fullName: 'K',
          role: UserRole.coordinator,
          institutionId: 'inst_chortoq_5',
          institutionName: '5-sonli umumiy o‘rta ta’lim maktabi',
        );
        final status = ChildStatusService().statusFor(
          db.getStudentById(child)!,
          coordinator,
        );
        expect(status.reasons.join(), contains('"sh" tovushi'));
      },
    );

    test('a mastered sound that stays mastered is not "stuck"', () async {
      final now = DateTime.now();
      for (final d in [60, 30, 1]) {
        await db.recordSoundEntry(
          entry('s', SoundStage.spontaneous, now.subtract(Duration(days: d))),
          byUser: speech,
        );
      }
      final profile = tracker.buildProfile(
        child,
        db.getSoundEntries(forUser: speech, studentId: child),
      );
      expect(profile.stuck, isEmpty);
      expect(profile.sounds.single.dynamics.status, DynamicsStatus.stable);
    });

    test('going back a stage is shown as a decline', () async {
      final now = DateTime.now();
      await db.recordSoundEntry(
        entry('l', SoundStage.phrases, now.subtract(const Duration(days: 10))),
        byUser: speech,
      );
      await db.recordSoundEntry(
        entry('l', SoundStage.syllables, now),
        byUser: speech,
      );
      final p =
          tracker
              .buildProfile(
                child,
                db.getSoundEntries(forUser: speech, studentId: child),
              )
              .sounds
              .single;
      expect(p.dynamics.status, DynamicsStatus.decline);
    });
  });

  group('Validation and permissions', () {
    Future<void> expectInvalid(SoundEntry e) => expectLater(
      db.recordSoundEntry(e, byUser: speech),
      throwsA(isA<ValidationException>()),
    );

    test('invalid entries are rejected with a clear reason', () async {
      final now = DateTime.now();
      await expectInvalid(
        entry('w', SoundStage.preparation, now),
      ); // o'zbek tilida yo'q
      await expectInvalid(
        entry(
          'r',
          SoundStage.preparation,
          now,
          disorder: SoundDisorder.substitution,
        ),
      );
      await expectInvalid(
        entry(
          'r',
          SoundStage.preparation,
          now,
          disorder: SoundDisorder.substitution,
          substitutedWith: 'r',
        ),
      );
      await expectInvalid(
        entry(
          'r',
          SoundStage.spontaneous,
          now,
          disorder: SoundDisorder.distortion,
        ),
      );
      await expectInvalid(
        entry('r', SoundStage.differentiation, now, differentiatedFrom: 'r'),
      );
      await expectInvalid(
        entry('r', SoundStage.words, now.add(const Duration(days: 3))),
      );
    });

    test(
      'only the assigned speech therapist records; others can view',
      () async {
        await expectLater(
          db.recordSoundEntry(
            entry('r', SoundStage.preparation, DateTime.now()),
            byUser: psy,
          ),
          throwsA(isA<PermissionDeniedException>()),
        );
        await db.recordSoundEntry(
          entry('r', SoundStage.preparation, DateTime.now()),
          byUser: speech,
        );
        // Shu bolaga biriktirilgan psixolog kartani ko'radi
        expect(
          db.getSoundEntries(forUser: psy, studentId: child),
          hasLength(1),
        );
        // Biriktirilmagan foydalanuvchi ko'rmaydi
        final stranger = UserModel(
          id: 'st_x',
          email: 'x@talim.uz',
          fullName: 'x',
          role: UserRole.speechTherapist,
          institutionId: 'inst_chortoq_5',
          institutionName: '5-sonli umumiy o‘rta ta’lim maktabi',
        );
        expect(
          db.getSoundEntries(forUser: stranger, studentId: child),
          isEmpty,
        );
      },
    );

    test(
      'a non-substitution entry never keeps a stray "substituted with" value',
      () async {
        final saved = await db.recordSoundEntry(
          entry(
            'z',
            SoundStage.preparation,
            DateTime.now(),
            disorder: SoundDisorder.distortion,
            substitutedWith: 's',
          ),
          byUser: speech,
        );
        expect(saved.substitutedWith, isNull);
      },
    );
  });
}
