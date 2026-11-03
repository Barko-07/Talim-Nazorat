import 'package:intl/intl.dart';

import '../models/student_model.dart';
import '../models/assessment_model.dart';
import '../models/session_model.dart';
import '../models/iep_model.dart';
import '../models/monitoring_alert_model.dart';
import '../models/referral_model.dart';
import '../models/audit_log_model.dart';
import '../models/work_record_model.dart';
import 'child_status_service.dart';
import 'dynamics_service.dart';
import 'report_service.dart';

class ReportExportService {
  static final ReportExportService _instance = ReportExportService._internal();
  factory ReportExportService() => _instance;
  ReportExportService._internal();

  /// UTF-8 BOM Excel dasturida o'zbekcha harflar (o‘, g‘, sh, ch) buzilmasligi uchun
  static const String utf8Bom = '\uFEFF';

  /// RFC 4180 bo'yicha qiymatni qo'shtirnoqqa olish. "=", "+", "-", "@" bilan boshlanadigan
  /// qiymat Excel'da formula sifatida bajarilmasligi uchun oldiga apostrof qo'yiladi
  /// (CSV formula injection himoyasi).
  String _sanitizeCsv(String? value) {
    if (value == null) return '""';
    var v = value;
    if (v.isNotEmpty && '=+-@\t\r'.contains(v[0])) v = "'$v";
    final escaped = v.replaceAll('"', '""');
    return '"$escaped"';
  }

  // ==================== O'QUVCHILAR BAZASI CSV ====================
  String generateStudentsCsv(List<StudentModel> students) {
    final buffer = StringBuffer();
    buffer.write(utf8Bom);
    buffer.writeln(
      'ID,F.I.SH,Tug‘ilgan sana,Yoshi,Jinsi,Maktab,Sinf,Holati,Ehtiyoj toifasi,Yordam darajasi,Biriktirilgan mutaxassislar soni',
    );

    for (final s in students) {
      final dobStr =
          '${s.dateOfBirth.year}-${s.dateOfBirth.month.toString().padLeft(2, '0')}-${s.dateOfBirth.day.toString().padLeft(2, '0')}';
      buffer.writeln(
        [
          _sanitizeCsv(s.id),
          _sanitizeCsv(s.fullName),
          _sanitizeCsv(dobStr),
          _sanitizeCsv(s.age.toString()),
          _sanitizeCsv(s.gender),
          _sanitizeCsv(s.institutionName),
          _sanitizeCsv(s.grade),
          _sanitizeCsv(s.status),
          _sanitizeCsv(s.primaryNeed),
          _sanitizeCsv(s.supportLevel),
          _sanitizeCsv(s.assignedSpecialistIds.length.toString()),
        ].join(','),
      );
    }

    return buffer.toString();
  }

  // ==================== BAHOLASHLAR CSV ====================
  String generateAssessmentsCsv(List<AssessmentModel> assessments) {
    final buffer = StringBuffer();
    buffer.write(utf8Bom);
    buffer.writeln(
      'ID,Sana,O‘quvchi,Mutaxassis,Mutaxassis roli,Kategoriya,Mavzu,To‘plangan ball,Maksimal ball,Foiz,Dinamika,Tavsiyalar',
    );

    for (final a in assessments) {
      final dateStr =
          '${a.assessmentDate.year}-${a.assessmentDate.month.toString().padLeft(2, '0')}-${a.assessmentDate.day.toString().padLeft(2, '0')}';
      buffer.writeln(
        [
          _sanitizeCsv(a.id),
          _sanitizeCsv(dateStr),
          _sanitizeCsv(a.studentName),
          _sanitizeCsv(a.specialistName),
          _sanitizeCsv(a.specialistRole),
          _sanitizeCsv(a.category),
          _sanitizeCsv(a.title),
          _sanitizeCsv(a.totalScore.toStringAsFixed(1)),
          _sanitizeCsv(a.maxScore.toStringAsFixed(1)),
          _sanitizeCsv('${a.percentage.toStringAsFixed(1)}%'),
          _sanitizeCsv(a.trend),
          _sanitizeCsv(a.recommendations),
        ].join(','),
      );
    }

    return buffer.toString();
  }

  // ==================== MASHG'ULOTLAR CSV ====================
  String generateSessionsCsv(List<SessionModel> sessions) {
    final buffer = StringBuffer();
    buffer.write(utf8Bom);
    buffer.writeln(
      'ID,Sana,O‘quvchi,Mutaxassis,Soha,Mavzu,Turi,Davomiyligi (daq.),Holati,Kuzatuv izohi,Keyingi tavsiya',
    );

    for (final s in sessions) {
      final dateStr =
          '${s.scheduledAt.year}-${s.scheduledAt.month.toString().padLeft(2, '0')}-${s.scheduledAt.day.toString().padLeft(2, '0')} ${s.scheduledAt.hour.toString().padLeft(2, '0')}:${s.scheduledAt.minute.toString().padLeft(2, '0')}';
      buffer.writeln(
        [
          _sanitizeCsv(s.id),
          _sanitizeCsv(dateStr),
          _sanitizeCsv(s.studentName),
          _sanitizeCsv(s.specialistName),
          _sanitizeCsv(s.specialistRole),
          _sanitizeCsv(s.topic),
          _sanitizeCsv(s.sessionType),
          _sanitizeCsv(s.durationMinutes.toString()),
          _sanitizeCsv(s.status),
          _sanitizeCsv(s.observations ?? ''),
          _sanitizeCsv(s.nextSteps ?? ''),
        ].join(','),
      );
    }

    return buffer.toString();
  }

  // ==================== ITR REJALARI CSV ====================
  String generateIepCsv(List<IndividualEducationPlanModel> plans) {
    final buffer = StringBuffer();
    buffer.write(utf8Bom);
    buffer.writeln(
      'ID,O‘quvchi,Sinf,Muassasa,Reja nomi,O‘quv yili,Mas’ul o‘qituvchi,Koordinator,Holati,Maqsadlar soni,Bajarilgan maqsadlar,O‘rtacha progress',
    );

    for (final p in plans) {
      buffer.writeln(
        [
          _sanitizeCsv(p.id),
          _sanitizeCsv(p.studentName),
          _sanitizeCsv(p.studentGrade),
          _sanitizeCsv(p.institutionName),
          _sanitizeCsv(p.title),
          _sanitizeCsv(p.academicYear),
          _sanitizeCsv(p.responsibleTeacherName),
          _sanitizeCsv(p.coordinatorName ?? 'Belgilanmagan'),
          _sanitizeCsv(p.status),
          _sanitizeCsv(p.totalObjectivesCount.toString()),
          _sanitizeCsv(p.completedObjectivesCount.toString()),
          _sanitizeCsv('${p.averageProgress.toStringAsFixed(1)}%'),
        ].join(','),
      );
    }

    return buffer.toString();
  }

  // ==================== MONITORING OGOHLANTIRISHLARI CSV ====================
  String generateAlertsCsv(List<MonitoringAlertModel> alerts) {
    final buffer = StringBuffer();
    buffer.write(utf8Bom);
    buffer.writeln(
      'ID,Sana,Qoida kodi,Qoida nomi,O‘quvchi,Sinf,Darajasi,Xabar,Tavsiya etilgan harakat,Mas’ul shaxs,Holati',
    );

    for (final a in alerts) {
      final dateStr =
          '${a.createdAt.year}-${a.createdAt.month.toString().padLeft(2, '0')}-${a.createdAt.day.toString().padLeft(2, '0')}';
      buffer.writeln(
        [
          _sanitizeCsv(a.id),
          _sanitizeCsv(dateStr),
          _sanitizeCsv(a.ruleCode),
          _sanitizeCsv(a.ruleTitle),
          _sanitizeCsv(a.studentName),
          _sanitizeCsv(a.studentGrade),
          _sanitizeCsv(a.severity),
          _sanitizeCsv(a.message),
          _sanitizeCsv(a.suggestedAction),
          _sanitizeCsv(a.responsiblePersonName ?? ''),
          _sanitizeCsv(a.status),
        ].join(','),
      );
    }

    return buffer.toString();
  }

  // ==================== YO'NALTIRISHLAR CSV ====================
  String generateReferralsCsv(List<ReferralModel> referrals) {
    final buffer = StringBuffer();
    buffer.write(utf8Bom);
    buffer.writeln(
      'ID,Bog‘langan baholash ID,Sana,O‘quvchi,Yuborgan mutaxassis,Yo‘naltirilgan xizmat,Sababi,Muhimlik,Holati,Xulosa',
    );

    for (final r in referrals) {
      final dateStr =
          '${r.createdAt.year}-${r.createdAt.month.toString().padLeft(2, '0')}-${r.createdAt.day.toString().padLeft(2, '0')}';
      buffer.writeln(
        [
          _sanitizeCsv(r.id),
          _sanitizeCsv(r.sourceAssessmentId ?? ''),
          _sanitizeCsv(dateStr),
          _sanitizeCsv(r.studentName),
          _sanitizeCsv(r.fromSpecialistName),
          _sanitizeCsv(r.toSpecialistType),
          _sanitizeCsv(r.reason),
          _sanitizeCsv(r.priority),
          _sanitizeCsv(r.status),
          _sanitizeCsv(r.outcomeNotes ?? ''),
        ].join(','),
      );
    }

    return buffer.toString();
  }

  // ==================== AUDIT JURNALI CSV ====================
  String generateAuditLogsCsv(List<AuditLogModel> auditLogs) {
    final buffer = StringBuffer();
    buffer.write(utf8Bom);
    buffer.writeln(
      'ID,Sana va vaqt,Foydalanuvchi,Roli,Amal turi,Ob’ekt,Tafsilotlar',
    );

    for (final log in auditLogs) {
      final timeStr =
          '${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')} ${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';
      buffer.writeln(
        [
          _sanitizeCsv(log.id),
          _sanitizeCsv(timeStr),
          _sanitizeCsv(log.userFullName),
          _sanitizeCsv(log.userRole),
          _sanitizeCsv(log.action),
          _sanitizeCsv(log.entity),
          _sanitizeCsv(log.details),
        ].join(','),
      );
    }

    return buffer.toString();
  }

  // ==================== PSIXOLOGIK KUZATUVLAR JURNALI CSV ====================
  String generateObservationsCsv(List<dynamic> observations) {
    final buffer = StringBuffer();
    buffer.write(utf8Bom);
    buffer.writeln(
      'ID,Sana,O‘quvchi,Sinf,Kategoriya,Emotsional holat,Kontekst,Kuzatuv xulosasi,Tavsiyalar,Maxfiylik',
    );

    for (final o in observations) {
      final dateStr =
          '${o.date.year}-${o.date.month.toString().padLeft(2, '0')}-${o.date.day.toString().padLeft(2, '0')}';
      buffer.writeln(
        [
          _sanitizeCsv(o.id),
          _sanitizeCsv(dateStr),
          _sanitizeCsv(o.studentName),
          _sanitizeCsv(o.studentGrade),
          _sanitizeCsv(o.category),
          _sanitizeCsv(o.emotionalState),
          _sanitizeCsv(o.triggerOrContext ?? ''),
          _sanitizeCsv(o.observationText),
          _sanitizeCsv(o.recommendationOrAction ?? ''),
          _sanitizeCsv(o.isConfidential ? 'Maxfiy' : 'Standart'),
        ].join(','),
      );
    }

    return buffer.toString();
  }

  // ==================== UMUMIY MONITORING HISOBOTI CSV ====================
  String generateMonitoringReportCsv(MonitoringReport r) {
    final df = DateFormat('dd.MM.yyyy');
    final b = StringBuffer()..write(utf8Bom);
    void row(String label, Object value) =>
        b.writeln('${_sanitizeCsv(label)},${_sanitizeCsv(value.toString())}');

    row('Hisobot davri', '${df.format(r.from)} — ${df.format(r.to)}');
    row('Jami bolalar', r.totalChildren);
    row('Mutaxassislar bilan ishlangan', r.childrenWorkedWith);
    row('Hali ishlanmagan', r.childrenNotWorkedWith);
    for (final c in StatusColor.values) {
      row('Holat: ${c.label}', r.statusCounts[c] ?? 0);
    }
    for (final k in WorkKind.values) {
      row('${k.label}lar soni', r.workCounts[k] ?? 0);
    }
    for (final d in DynamicsStatus.values) {
      row('Dinamika: ${d.label}', r.dynamicsCounts[d] ?? 0);
    }
    row('ITR maqsadlari (jami)', r.iepObjectivesTotal);
    row('ITR maqsadlari (bajarilgan)', r.iepObjectivesCompleted);
    for (final e in r.referralsByStatus.entries) {
      row('Yo‘naltirishlar: ${e.key}', e.value);
    }
    if (r.notWorkedWithNames.isNotEmpty) {
      row('Hali ishlanmagan bolalar', r.notWorkedWithNames.join('; '));
    }
    return b.toString();
  }

  String generateSpecialistActivityCsv(MonitoringReport r) {
    final df = DateFormat('dd.MM.yyyy');
    final b = StringBuffer()..write(utf8Bom);
    b.writeln(
      'F.I.SH,Lavozim,Biriktirilgan bolalar,Ishlangan bolalar,Qamrov (%),'
      '${WorkKind.values.map((k) => k.label).join(',')},Jami yozuvlar,Oxirgi faollik',
    );
    for (final s in r.specialists) {
      b.writeln(
        [
          _sanitizeCsv(s.fullName),
          _sanitizeCsv(s.role),
          s.childrenAssigned,
          s.childrenWorkedWith,
          (s.coverage * 100).round(),
          ...WorkKind.values.map((k) => s.recordsByKind[k] ?? 0),
          s.totalRecords,
          _sanitizeCsv(
            s.lastActivity == null ? '—' : df.format(s.lastActivity!),
          ),
        ].join(','),
      );
    }
    return b.toString();
  }
}
