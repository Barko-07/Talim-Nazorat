import '../models/student_model.dart';
import '../models/assessment_model.dart';
import '../models/session_model.dart';
import '../models/iep_model.dart';
import '../models/monitoring_alert_model.dart';
import '../models/referral_model.dart';

class ReportExportService {
  static final ReportExportService _instance = ReportExportService._internal();
  factory ReportExportService() => _instance;
  ReportExportService._internal();

  /// UTF-8 BOM Excel dasturida o'zbekcha harflar (o‘, g‘, sh, ch) buzilmasligi uchun
  static const String utf8Bom = '\uFEFF';

  String _sanitizeCsv(String? value) {
    if (value == null) return '""';
    final escaped = value.replaceAll('"', '""');
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
      final dobStr = '${s.dateOfBirth.year}-${s.dateOfBirth.month.toString().padLeft(2, '0')}-${s.dateOfBirth.day.toString().padLeft(2, '0')}';
      buffer.writeln([
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
      ].join(','));
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
      final dateStr = '${a.assessmentDate.year}-${a.assessmentDate.month.toString().padLeft(2, '0')}-${a.assessmentDate.day.toString().padLeft(2, '0')}';
      buffer.writeln([
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
      ].join(','));
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
      final dateStr = '${s.scheduledAt.year}-${s.scheduledAt.month.toString().padLeft(2, '0')}-${s.scheduledAt.day.toString().padLeft(2, '0')} ${s.scheduledAt.hour.toString().padLeft(2, '0')}:${s.scheduledAt.minute.toString().padLeft(2, '0')}';
      buffer.writeln([
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
      ].join(','));
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
      buffer.writeln([
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
      ].join(','));
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
      final dateStr = '${a.createdAt.year}-${a.createdAt.month.toString().padLeft(2, '0')}-${a.createdAt.day.toString().padLeft(2, '0')}';
      buffer.writeln([
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
      ].join(','));
    }

    return buffer.toString();
  }

  // ==================== YO'NALTIRISHLAR CSV ====================
  String generateReferralsCsv(List<ReferralModel> referrals) {
    final buffer = StringBuffer();
    buffer.write(utf8Bom);
    buffer.writeln(
      'ID,Sana,O‘quvchi,Yuborgan mutaxassis,Yo‘naltirilgan xizmat,Sababi,Muhimlik,Holati,Xulosa',
    );

    for (final r in referrals) {
      final dateStr = '${r.createdAt.year}-${r.createdAt.month.toString().padLeft(2, '0')}-${r.createdAt.day.toString().padLeft(2, '0')}';
      buffer.writeln([
        _sanitizeCsv(r.id),
        _sanitizeCsv(dateStr),
        _sanitizeCsv(r.studentName),
        _sanitizeCsv(r.fromSpecialistName),
        _sanitizeCsv(r.toSpecialistType),
        _sanitizeCsv(r.reason),
        _sanitizeCsv(r.priority),
        _sanitizeCsv(r.status),
        _sanitizeCsv(r.outcomeNotes ?? ''),
      ].join(','));
    }

    return buffer.toString();
  }
}
