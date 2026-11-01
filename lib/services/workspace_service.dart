import '../core/constants/specialist_workspaces.dart';
import '../models/curriculum_model.dart';
import '../models/referral_model.dart';
import '../models/session_model.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';
import '../models/workspace_model.dart';
import '../models/work_record_model.dart';
import 'dynamics_service.dart';
import 'local_db_service.dart';
import 'sound_tracker_service.dart';

/// E'tibor talab qiladigan holat turi
enum AttentionKind {
  notWorkedWith('Hali ishlanmagan'),
  reassessmentDue('Qayta baholash vaqti keldi'),
  decline('Pasayish'),
  ineffective('Samarasiz natija'),
  openAlert('Ochiq monitoring signali'),
  missingProfile('Imkoniyatlar profili to‘ldirilmagan'),
  subjectLevelMissing('Bilim darajasi tekshirilmagan'),
  largeGap('Sinf va bilim darajasi orasida katta farq'),
  overdueTasks('Topshiriq natijasi kiritilmagan'),
  soundStuck('Tovush rivojlanmayapti');

  final String label;
  const AttentionKind(this.label);
}

class AttentionItem {
  final StudentModel student;
  final AttentionKind kind;
  final String reason;
  const AttentionItem(this.student, this.kind, this.reason);
}

/// Mutaxassis kabinetining bosh sahifasi uchun ma'lumotlar
class WorkspaceDashboard {
  final SpecialistWorkspace workspace;

  /// Mutaxassisga biriktirilgan (yoki rahbariyat uchun — ko'rinadigan barcha) bolalar
  final List<StudentModel> caseload;

  /// Shu mutaxassis hali hech qanday ish qayd etmagan bolalar
  final List<StudentModel> notWorkedWith;
  final List<AttentionItem> attention;
  final List<ReferralModel> incomingReferrals;
  final List<SessionModel> upcomingSessions;

  const WorkspaceDashboard({
    required this.workspace,
    required this.caseload,
    required this.notWorkedWith,
    required this.attention,
    required this.incomingReferrals,
    required this.upcomingSessions,
  });
}

class WorkspaceService {
  static final WorkspaceService _instance = WorkspaceService._internal();
  factory WorkspaceService() => _instance;
  WorkspaceService._internal();

  final _db = LocalDbService();
  final _dynamics = DynamicsService();
  final _sounds = SoundTrackerService();

  /// O'z baholashi shuncha kundan eski bo'lsa — qayta baholash tavsiya qilinadi
  static const int reassessmentDays = 90;

  /// Sinf va bilim darajasi orasidagi shu va undan katta farq e'tiborga olinadi
  static const int largeGapGrades = 2;

  static const _openReferralStatuses = {'Yuborildi', 'Qabul qilindi', 'Jarayonda'};

  /// Bevosita bolalar bilan ishlaydigan va o'quvchilar biriktiriladigan rollar
  static const _caseloadRoles = {
    UserRole.psychologist,
    UserRole.speechTherapist,
    UserRole.specialEducation,
    UserRole.specialEdTeacher,
  };

  SpecialistWorkspace workspaceFor(UserModel user) =>
      SpecialistWorkspaces.forRole(user.role);

  bool canUse(UserModel user, WorkspaceModule module, {bool edit = false}) {
    if (!user.isActive) return false;
    final ws = workspaceFor(user);
    return edit ? ws.canEdit(module) : ws.has(module);
  }

  /// Mutaxassisning o'quvchilari: biriktirilganlar. O'qituvchiga hech kim biriktirilmagan
  /// bo'lsa — o'z maktabi o'quvchilari; rahbariyat uchun — ko'rinadigan barcha o'quvchilar.
  List<StudentModel> caseloadFor(UserModel user) {
    final visible = _db.getStudents(forUser: user);
    if (!_caseloadRoles.contains(user.role) && user.role != UserRole.teacher) {
      return visible;
    }
    final assigned = visible
        .where((s) =>
            s.assignedSpecialistIds.contains(user.id) ||
            user.assignedStudentIds.contains(s.id))
        .toList();
    if (assigned.isEmpty && user.role == UserRole.teacher) return visible;
    return assigned;
  }

  /// Shu mutaxassis bola bilan oxirgi marta qachon ish qayd etgan (null = hech qachon)
  DateTime? lastWorkBy(UserModel user, StudentModel student) {
    final mine = _db.getWorkRecords(student.id).where((r) => r.userId == user.id);
    return mine.isEmpty ? null : mine.last.at;
  }

  /// Shu mutaxassisning oxirgi baholashi (test yoki bilim darajasi)
  DateTime? _lastAssessmentBy(UserModel user, StudentModel student) {
    final mine = _db.getWorkRecords(student.id).where((r) =>
        r.userId == user.id &&
        (r.kind == WorkKind.assessment || r.kind == WorkKind.subjectLevel));
    return mine.isEmpty ? null : mine.last.at;
  }

  WorkspaceDashboard dashboardFor(UserModel user, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final ws = workspaceFor(user);
    final caseload = ws.worksWithChildren ? caseloadFor(user) : <StudentModel>[];
    final notWorked = <StudentModel>[];
    final attention = <AttentionItem>[];

    for (final s in caseload) {
      final last = lastWorkBy(user, s);
      if (last == null) {
        notWorked.add(s);
        attention.add(AttentionItem(
          s,
          AttentionKind.notWorkedWith,
          'Siz bu bola bilan hali hech qanday ish (baholash, mashg‘ulot, kuzatuv, o‘lchov) qayd etmagansiz.',
        ));
      } else {
        final lastAssessment = _lastAssessmentBy(user, s);
        if (lastAssessment != null &&
            today.difference(lastAssessment).inDays > reassessmentDays) {
          attention.add(AttentionItem(
            s,
            AttentionKind.reassessmentDue,
            'Oxirgi baholashingizdan ${today.difference(lastAssessment).inDays} kun o‘tdi.',
          ));
        }
      }

      // Mutaxassisning o'z ko'rsatkichlari bo'yicha dinamika
      for (final metricId in ws.metricIds) {
        final metric = _db.getProgressMetric(metricId);
        final points = _db
            .getMeasurements(forUser: user, studentId: s.id, metricId: metricId)
            .map((m) => DataPoint(m.measuredAt, m.value))
            .toList();
        if (metric == null || points.length < 2) continue;
        final r = _dynamics.evaluate(
          points,
          higherIsBetter: metric.higherIsBetter,
          unit: metric.unit,
        );
        if (r.status == DynamicsStatus.decline) {
          attention.add(AttentionItem(s, AttentionKind.decline, '${metric.name}: ${r.reason}'));
        } else if (r.status == DynamicsStatus.ineffective) {
          attention.add(AttentionItem(s, AttentionKind.ineffective, '${metric.name}: ${r.reason}'));
        }
      }

      if (ws.canEdit(WorkspaceModule.accessProfile) && s.accessProfile == null) {
        attention.add(AttentionItem(
          s,
          AttentionKind.missingProfile,
          'Savollarni bolaga moslab tanlash uchun imkoniyatlar profilini to‘ldiring.',
        ));
      }

      if (ws.canEdit(WorkspaceModule.soundTracker)) {
        final profile = _sounds.buildProfile(
          s.id,
          _db.getSoundEntries(forUser: user, studentId: s.id),
        );
        for (final p in profile.stuck) {
          attention.add(AttentionItem(
            s,
            AttentionKind.soundStuck,
            '"${p.sound.display}" tovushi (${p.stage.label}): ${p.dynamics.reason}',
          ));
        }
      }

      if (ws.canEdit(WorkspaceModule.subjectTasks)) {
        final overdue = _db
            .getSubjectTasks(forUser: user, studentId: s.id, onlyOpen: true)
            .where((t) => t.assignedById == user.id && t.isOverdue(today))
            .toList();
        if (overdue.isNotEmpty) {
          attention.add(AttentionItem(
            s,
            AttentionKind.overdueTasks,
            'Muddati o‘tgan topshiriqlar natijasi kiritilmagan: ${overdue.map((t) => t.title).join(', ')}.',
          ));
        }
      }

      if (ws.canEdit(WorkspaceModule.subjectLevel)) {
        final missing = <String>[];
        for (final subject in SchoolSubjects.core) {
          if (_db.getCurriculumStandards(subject: subject).isEmpty) continue;
          final level = _db.latestSubjectLevel(forUser: user, studentId: s.id, subject: subject);
          if (level == null) {
            missing.add(subject);
          } else if (level.gap >= largeGapGrades) {
            attention.add(AttentionItem(
              s,
              AttentionKind.largeGap,
              '$subject: ${level.classGrade}-sinf o‘quvchisi, ${level.confirmedGrade}-sinf darajasida (${level.gap} sinf farq).',
            ));
          }
        }
        if (missing.isNotEmpty) {
          attention.add(AttentionItem(
            s,
            AttentionKind.subjectLevelMissing,
            'Bilim darajasi tekshirilmagan: ${missing.join(', ')}.',
          ));
        }
      }
    }

    final caseloadIds = caseload.map((s) => s.id).toSet();
    for (final a in _db.getAlerts(forUser: user, onlyUnresolved: true)) {
      if (!caseloadIds.contains(a.studentId)) continue;
      final student = caseload.firstWhere((s) => s.id == a.studentId);
      attention.add(AttentionItem(student, AttentionKind.openAlert, '${a.ruleTitle}: ${a.message}'));
    }

    final incoming = _db.getReferrals(forUser: user).where((r) {
      if (!_openReferralStatuses.contains(r.status)) return false;
      final toMe = r.toSpecialistId == user.id;
      final toMyRole = (r.toSpecialistId == null || r.toSpecialistId!.isEmpty) &&
          r.toSpecialistType == user.role.label;
      return toMe || toMyRole;
    }).toList();

    final weekAhead = today.add(const Duration(days: 7));
    final upcoming = _db
        .getSessions(forUser: user, specialistId: user.id)
        .where((s) =>
            s.isScheduled &&
            !s.scheduledAt.isBefore(DateTime(today.year, today.month, today.day)) &&
            s.scheduledAt.isBefore(weekAhead))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return WorkspaceDashboard(
      workspace: ws,
      caseload: caseload,
      notWorkedWith: notWorked,
      attention: attention,
      incomingReferrals: incoming,
      upcomingSessions: upcoming,
    );
  }
}
