import '../models/monitoring_alert_model.dart';
import '../models/student_model.dart';
import '../models/assessment_model.dart';
import '../models/session_model.dart';
import '../models/iep_model.dart';

class MonitoringRuleEngine {
  static final MonitoringRuleEngine _instance = MonitoringRuleEngine._internal();
  factory MonitoringRuleEngine() => _instance;
  MonitoringRuleEngine._internal();

  /// Berilgan bazadagi barcha ma'lumotlar asosida 6 ta rasmiy qoida bo'yicha tahlil o'tkazish
  List<MonitoringAlertModel> evaluateRules({
    required List<StudentModel> students,
    required List<AssessmentModel> assessments,
    required List<SessionModel> sessions,
    required List<IndividualEducationPlanModel> iepPlans,
    required List<MonitoringAlertModel> existingAlerts,
  }) {
    final List<MonitoringAlertModel> generatedAlerts = [];
    final now = DateTime.now();

    // Mavjud hal qilingan ogohlantirishlarni qayta bezovta qilmaslik
    final resolvedRuleKeys = <String>{};
    for (final a in existingAlerts) {
      if (a.isResolved) {
        resolvedRuleKeys.add('${a.studentId}_${a.ruleCode}');
      }
    }

    for (final student in students) {
      if (student.status == 'Arxivlangan') continue;

      final studentSessions = sessions.where((s) => s.studentId == student.id).toList();
      final studentAssessments = assessments.where((a) => a.studentId == student.id).toList();
      final studentPlans = iepPlans.where((p) => p.studentId == student.id).toList();

      // ==================== QOIDA 1: QATNASHILMAGAN MASHG'ULOTLAR ====================
      // 2 yoki undan ortiq o'tkazib yuborilgan mashg'ulotlar
      final missedSessions = studentSessions.where((s) => s.isMissed).toList();
      final rule1Key = '${student.id}_MISSED_SESSIONS';
      if (missedSessions.length >= 2 && !resolvedRuleKeys.contains(rule1Key)) {
        generatedAlerts.add(
          MonitoringAlertModel(
            id: 'alert_missed_${student.id}',
            ruleCode: 'MISSED_SESSIONS',
            ruleTitle: 'Muntazam qatnashmaslik holati',
            studentId: student.id,
            studentName: student.fullName,
            studentGrade: student.grade,
            severity: missedSessions.length >= 3 ? 'XAVF' : 'DIQQAT',
            message: '${student.fullName} rejalashtirilgan ${missedSessions.length} ta korreksion mashg‘ulotga kelmadi.',
            suggestedAction: 'Ota-ona bilan bog‘lanib qatnashmaslik sababini aniqlash va dars jadvalini qayta ko‘rib chiqish.',
            responsiblePersonName: missedSessions.first.specialistName,
            responsiblePersonId: missedSessions.first.specialistId,
            status: 'Ochiq',
            createdAt: now,
          ),
        );
      }

      // ==================== QOIDA 2: MUDDATI O'TGAN BAHOLASHLAR ====================
      // Rejalashtirilgan takroriy baholash muddati o'tib ketgan
      final overdueAssessments = studentAssessments.where((a) {
        return a.reviewDate != null && a.reviewDate!.isBefore(now);
      }).toList();
      final rule2Key = '${student.id}_OVERDUE_ASSESSMENT';
      if (overdueAssessments.isNotEmpty && !resolvedRuleKeys.contains(rule2Key)) {
        final lastDue = overdueAssessments.first;
        generatedAlerts.add(
          MonitoringAlertModel(
            id: 'alert_overdue_ass_${student.id}',
            ruleCode: 'OVERDUE_ASSESSMENT',
            ruleTitle: 'Kechikkan oraliq baholash',
            studentId: student.id,
            studentName: student.fullName,
            studentGrade: student.grade,
            severity: 'DIQQAT',
            message: '${lastDue.title} bo‘yicha oraliq monitoring tekshiruv muddati yetib kelgan.',
            suggestedAction: 'Mutaxassis tomonidan bolaning dolzarb ko‘nikmalari qayta baholanib, reja yangilanishi lozim.',
            responsiblePersonName: lastDue.specialistName,
            responsiblePersonId: lastDue.specialistId,
            status: 'Ochiq',
            createdAt: now,
          ),
        );
      }

      // ==================== QOIDA 3: SAMARASIZLIK / O'SIShNING YO'QLIGI ====================
      // Oxirgi 2 ta taqqoslanadigan baholashda ball umuman o'zgarmagan (diff == 0)
      if (studentAssessments.length >= 2) {
        final sortedAss = List<AssessmentModel>.from(studentAssessments)
          ..sort((a, b) => b.assessmentDate.compareTo(a.assessmentDate));
        final latest = sortedAss[0];
        final previous = sortedAss[1];

        if (latest.category == previous.category && latest.maxScore == previous.maxScore) {
          final diff = latest.totalScore - previous.totalScore;
          final rule3Key = '${student.id}_NO_PROGRESS_ASSESSMENT';
          if (diff == 0 && !resolvedRuleKeys.contains(rule3Key)) {
            generatedAlerts.add(
              MonitoringAlertModel(
                id: 'alert_no_progress_${student.id}',
                ruleCode: 'NO_PROGRESS_ASSESSMENT',
                ruleTitle: 'Dinamikada o‘sish kuzatilmadi',
                studentId: student.id,
                studentName: student.fullName,
                studentGrade: student.grade,
                severity: 'DIQQAT',
                message: '${latest.category} yo‘nalishida ketma-ket 2 ta baholashda ko‘rsatkich o‘zgarmay qoldi (${latest.totalScore} ball).',
                suggestedAction: 'Qo‘llanilayotgan pedagogik metodika va mashqlar murakkabligini konsiliumda qayta ko‘rib chiqish.',
                responsiblePersonName: latest.specialistName,
                responsiblePersonId: latest.specialistId,
                status: 'Ochiq',
                createdAt: now,
              ),
            );
          }

          // ==================== QOIDA 4: KO'RSATKICHLARNING PASAYISHI (REGRESSIYA) ====================
          final rule4Key = '${student.id}_REGRESSION_ALERT';
          if (diff < -5.0 && !resolvedRuleKeys.contains(rule4Key)) {
            generatedAlerts.add(
              MonitoringAlertModel(
                id: 'alert_regress_${student.id}',
                ruleCode: 'REGRESSION_ALERT',
                ruleTitle: 'Ko‘rsatkichlarning sezilarli pasayishi',
                studentId: student.id,
                studentName: student.fullName,
                studentGrade: student.grade,
                severity: 'XAVF',
                message: '${latest.category} bo‘yicha oldingi baholashga nisbatan natija pasaygan (${diff.toStringAsFixed(1)} ball).',
                suggestedAction: 'Shifokor-pediatr va psixolog ishtirokida bolaning umumiy holatini zudlik bilan o‘rganish.',
                responsiblePersonName: latest.specialistName,
                responsiblePersonId: latest.specialistId,
                status: 'Ochiq',
                createdAt: now,
              ),
            );
          }
        }
      }

      // ==================== QOIDA 5: ITR MAQSAD MUDDATI O'TGANI ====================
      for (final plan in studentPlans) {
        if (plan.status != 'Faol') continue;
        final overdueObjectives = plan.objectives.where((obj) {
          return obj.targetDate.isBefore(now) && !obj.isCompleted;
        }).toList();

        final rule5Key = '${student.id}_OVERDUE_IEP_OBJECTIVE';
        if (overdueObjectives.isNotEmpty && !resolvedRuleKeys.contains(rule5Key)) {
          final firstObj = overdueObjectives.first;
          generatedAlerts.add(
            MonitoringAlertModel(
              id: 'alert_iep_due_${student.id}',
              ruleCode: 'OVERDUE_IEP_OBJECTIVE',
              ruleTitle: 'ITR maqsad muddati kechikkan',
              studentId: student.id,
              studentName: student.fullName,
              studentGrade: student.grade,
              severity: 'DIQQAT',
              message: 'ITR dagi "${firstObj.title}" vazifasi muddati o‘tgan bo‘lsa-da, hali yakunlanmagan (${firstObj.progressPercent}%).',
              suggestedAction: 'Koordinator boshchiligida maqsadni kichikroq bosqichlarga ajratish yoki muddatni rasmiylashtirish.',
              responsiblePersonName: plan.responsibleTeacherName,
              responsiblePersonId: plan.responsibleTeacherId,
              status: 'Ochiq',
              createdAt: now,
            ),
          );
        }
      }

      // ==================== QOIDA 6: IZOHSIZ MASHG'ULOTLAR ====================
      final completedWithoutNotes = studentSessions.where((s) {
        return s.isCompleted && (s.observations == null || s.observations!.trim().isEmpty);
      }).toList();
      final rule6Key = '${student.id}_MISSING_OBSERVATION';
      if (completedWithoutNotes.isNotEmpty && !resolvedRuleKeys.contains(rule6Key)) {
        final sample = completedWithoutNotes.first;
        generatedAlerts.add(
          MonitoringAlertModel(
            id: 'alert_no_notes_${student.id}',
            ruleCode: 'MISSING_OBSERVATION',
            ruleTitle: 'Mashg‘ulot kuzatuv xulosasi kiritilmagan',
            studentId: student.id,
            studentName: student.fullName,
            studentGrade: student.grade,
            severity: 'MA’LUMOT',
            message: '${sample.topic} mashg‘uloti yakunlangan, biroq mutaxassis kuzatuv izohi yozilmagan.',
            suggestedAction: 'O‘tkazilgan korreksion ish natijalari va tavsiyalarni mashg‘ulot profiliga qayd etish.',
            responsiblePersonName: sample.specialistName,
            responsiblePersonId: sample.specialistId,
            status: 'Ochiq',
            createdAt: now,
          ),
        );
      }
    }

    // Mavjud ogohlantirishlar bilan birlashtirish (takrorlanmasligi uchun ID bo'yicha)
    final existingMap = {for (var a in existingAlerts) a.id: a};
    for (final generated in generatedAlerts) {
      if (!existingMap.containsKey(generated.id)) {
        existingMap[generated.id] = generated;
      }
    }

    return existingMap.values.toList();
  }
}
