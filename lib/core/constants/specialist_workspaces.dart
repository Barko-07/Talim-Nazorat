import '../../models/user_model.dart';
import '../../models/workspace_model.dart';
import 'progress_metrics.dart';

/// Yo'naltirish manzillari (ReferralModel.toSpecialistType qiymatlari).
/// Mutaxassis rollari uchun rol nomi bilan bir xil — yo'naltirish shu nom bo'yicha topiladi.
class ReferralTargets {
  static final psychologist = UserRole.psychologist.label;
  static final speechTherapist = UserRole.speechTherapist.label;
  static final defectologist = UserRole.specialEducation.label;
  static final specialEdTeacher = UserRole.specialEdTeacher.label;
  static final subjectTeacher = UserRole.teacher.label;
  static const medical = 'Tibbiy PMPK komissiyasi';
}

/// Psixologik baholash yo'nalishlari
class AssessmentDomains {
  static const cognitive = 'Kognitiv va intellekt';
  static const attentionMemory = 'Diqqat va xotira';
  static const emotional = 'Emotsional va xavotir';
  static const social = 'Ijtimoiy moslashuv va motivatsiya';
  static const behaviour = 'Xulq-atvor va iroda';
  static const speech = 'Nutq va muloqot';
  static const sensorMotor = 'Sensor-motor rivojlanish';
  static const learningSkills = 'O‘quv ko‘nikmalari';

  static const psychological = [cognitive, attentionMemory, emotional, social, behaviour];
}

/// Har bir rol uchun kabinet ta'rifi
class SpecialistWorkspaces {
  static const _e = ModuleAccess.edit;
  static const _v = ModuleAccess.view;

  static SpecialistWorkspace forRole(UserRole role) => switch (role) {
    UserRole.psychologist => SpecialistWorkspace(
      role: role,
      title: 'Psixolog kabineti',
      mission:
          'Psixologik testlar va metodikalarni o‘tkazish, emotsional holat va xulq-atvorni kuzatish, '
          'muloqot va ijtimoiy ko‘nikmalarni baholash, xulosalarni qayd etish.',
      modules: const {
        WorkspaceModule.caseload: _e,
        WorkspaceModule.psychAssessment: _e,
        WorkspaceModule.observationJournal: _e,
        WorkspaceModule.accessProfile: _e,
        WorkspaceModule.measurements: _e,
        WorkspaceModule.sessions: _e,
        WorkspaceModule.iep: _e,
        WorkspaceModule.caseConference: _e,
        WorkspaceModule.referrals: _e,
        WorkspaceModule.subjectLevel: _v,
        WorkspaceModule.reports: _v,
      },
      assessmentDomains: AssessmentDomains.psychological,
      metricIds: [
        ProgressMetrics.attentionSpan.id,
        ProgressMetrics.wordsRecalled.id,
        ProgressMetrics.meltdownsPerWeek.id,
        ProgressMetrics.peerInitiations.id,
      ],
      sessionTemplates: const [
        SessionTemplate('Individual psixokorreksion mashg‘ulot', 'Individual', 30),
        SessionTemplate('Ijtimoiy ko‘nikmalar treningi', 'Kichik guruhda', 40),
        SessionTemplate('Emotsiyalarni boshqarish mashg‘uloti', 'Individual', 30),
        SessionTemplate('Ota-ona bilan konsultatsiya', 'Individual', 30),
      ],
      referralTargets: [
        ReferralTargets.speechTherapist,
        ReferralTargets.defectologist,
        ReferralTargets.specialEdTeacher,
        ReferralTargets.medical,
      ],
    ),
    UserRole.speechTherapist => SpecialistWorkspace(
      role: role,
      title: 'Logoped kabineti',
      mission:
          'Nutq rivojlanishini baholash, nutq mashg‘ulotlarini olib borish, natijalar va o‘zgarishlarni qayd etish.',
      modules: const {
        WorkspaceModule.caseload: _e,
        WorkspaceModule.speechAssessment: _e,
        WorkspaceModule.soundTracker: _e,
        WorkspaceModule.accessProfile: _e,
        WorkspaceModule.measurements: _e,
        WorkspaceModule.sessions: _e,
        WorkspaceModule.iep: _e,
        WorkspaceModule.caseConference: _e,
        WorkspaceModule.referrals: _e,
        WorkspaceModule.subjectLevel: _v,
        WorkspaceModule.reports: _v,
      },
      assessmentDomains: const [AssessmentDomains.speech],
      metricIds: [
        ProgressMetrics.soundsCorrect.id,
        ProgressMetrics.activeVocabulary.id,
        ProgressMetrics.readingSpeed.id,
      ],
      sessionTemplates: const [
        SessionTemplate('Artikulyatsion gimnastika va tovush qo‘yish', 'Individual', 25),
        SessionTemplate('Tovushni avtomatlashtirish', 'Individual', 25),
        SessionTemplate('Lug‘at va bog‘lanishli nutqni rivojlantirish', 'Kichik guruhda', 35),
        SessionTemplate('Fonematik eshitishni rivojlantirish', 'Individual', 25),
      ],
      referralTargets: [
        ReferralTargets.psychologist,
        ReferralTargets.defectologist,
        ReferralTargets.specialEdTeacher,
        ReferralTargets.medical,
      ],
    ),
    UserRole.specialEducation => SpecialistWorkspace(
      role: role,
      title: 'Defektolog kabineti',
      mission:
          'Sensor-motor, bilish va amaliy-hayotiy ko‘nikmalarni baholash, korreksion mashg‘ulotlar olib borish, natijalarni kiritish.',
      modules: const {
        WorkspaceModule.caseload: _e,
        WorkspaceModule.developmentAssessment: _e,
        WorkspaceModule.accessProfile: _e,
        WorkspaceModule.measurements: _e,
        WorkspaceModule.sessions: _e,
        WorkspaceModule.iep: _e,
        WorkspaceModule.caseConference: _e,
        WorkspaceModule.referrals: _e,
        WorkspaceModule.subjectLevel: _v,
        WorkspaceModule.reports: _v,
      },
      assessmentDomains: const [
        AssessmentDomains.sensorMotor,
        AssessmentDomains.cognitive,
      ],
      metricIds: [
        ProgressMetrics.fineMotorBeads.id,
        ProgressMetrics.selfCareActions.id,
        ProgressMetrics.independentTasks.id,
      ],
      sessionTemplates: const [
        SessionTemplate('Sensor integratsiya mashg‘uloti', 'Individual', 30),
        SessionTemplate('Mayda motorika va grafomotorika', 'Individual', 25),
        SessionTemplate('O‘z-o‘ziga xizmat ko‘nikmalari', 'Kichik guruhda', 35),
        SessionTemplate('Bilish jarayonlarini rivojlantirish', 'Individual', 30),
      ],
      referralTargets: [
        ReferralTargets.psychologist,
        ReferralTargets.speechTherapist,
        ReferralTargets.specialEdTeacher,
        ReferralTargets.medical,
      ],
    ),
    UserRole.specialEdTeacher => SpecialistWorkspace(
      role: role,
      title: 'Maxsus ta’lim o‘qituvchisi kabineti',
      mission:
          'Bilim darajasini DTS talablari asosida baholash, darajaga mos fan topshiriqlarini berish, '
          'o‘quv natijalarini qayd etish va individual ta’lim rejasini tuzish.',
      modules: const {
        WorkspaceModule.caseload: _e,
        WorkspaceModule.subjectLevel: _e,
        WorkspaceModule.subjectTasks: _e,
        WorkspaceModule.learningResults: _e,
        WorkspaceModule.iep: _e,
        WorkspaceModule.measurements: _e,
        WorkspaceModule.sessions: _e,
        WorkspaceModule.caseConference: _e,
        WorkspaceModule.referrals: _e,
        WorkspaceModule.soundTracker: _v,
        WorkspaceModule.reports: _v,
      },
      assessmentDomains: const [AssessmentDomains.learningSkills],
      metricIds: [
        ProgressMetrics.readingSpeed.id,
        ProgressMetrics.independentTasks.id,
      ],
      sessionTemplates: const [
        SessionTemplate('Individual dars (darajaga mos topshiriqlar)', 'Individual', 40),
        SessionTemplate('O‘qish va yozish ko‘nikmalari', 'Individual', 30),
        SessionTemplate('Hisoblash ko‘nikmalari', 'Individual', 30),
        SessionTemplate('Kichik guruhda dars', 'Kichik guruhda', 45),
      ],
      referralTargets: [
        ReferralTargets.psychologist,
        ReferralTargets.speechTherapist,
        ReferralTargets.defectologist,
        ReferralTargets.medical,
      ],
    ),
    UserRole.teacher => SpecialistWorkspace(
      role: role,
      title: 'Fan o‘qituvchisi / sinf rahbari kabineti',
      mission:
          'Sinfdagi bolalarning o‘quv natijalarini qayd etish, bilim darajasini kuzatish, kerak bo‘lsa mutaxassisga yo‘naltirish.',
      modules: const {
        WorkspaceModule.caseload: _v,
        WorkspaceModule.subjectLevel: _e,
        WorkspaceModule.learningResults: _e,
        WorkspaceModule.measurements: _e,
        WorkspaceModule.referrals: _e,
        WorkspaceModule.iep: _v,
        WorkspaceModule.sessions: _v,
      },
      assessmentDomains: const [AssessmentDomains.learningSkills],
      metricIds: [ProgressMetrics.independentTasks.id, ProgressMetrics.readingSpeed.id],
      referralTargets: [
        ReferralTargets.psychologist,
        ReferralTargets.speechTherapist,
        ReferralTargets.defectologist,
        ReferralTargets.specialEdTeacher,
      ],
    ),
    UserRole.coordinator => SpecialistWorkspace(
      role: role,
      title: 'Koordinator kabineti',
      mission:
          'Mutaxassislarni biriktirish, individual rejalarni muvofiqlashtirish, yo‘naltirishlarni boshqarish '
          'va bolalar bilan ishlash jarayonini kuzatish.',
      modules: const {
        WorkspaceModule.schoolMonitoring: _e,
        WorkspaceModule.specialistAssignment: _e,
        WorkspaceModule.iep: _e,
        WorkspaceModule.caseConference: _e,
        WorkspaceModule.referrals: _e,
        WorkspaceModule.subjectLevel: _e,
        WorkspaceModule.measurements: _v,
        WorkspaceModule.sessions: _v,
        WorkspaceModule.soundTracker: _v,
        WorkspaceModule.reports: _e,
      },
      referralTargets: [
        ReferralTargets.psychologist,
        ReferralTargets.speechTherapist,
        ReferralTargets.defectologist,
        ReferralTargets.specialEdTeacher,
        ReferralTargets.subjectTeacher,
        ReferralTargets.medical,
      ],
    ),
    UserRole.institutionAdmin => SpecialistWorkspace(
      role: role,
      title: 'Muassasa rahbari kabineti',
      mission:
          'Maktab foydalanuvchilari va rollarini boshqarish, bolalar bilan ishlash jarayonini nazorat qilish, hisobotlarni ko‘rish.',
      modules: const {
        WorkspaceModule.schoolMonitoring: _v,
        WorkspaceModule.userManagement: _e,
        WorkspaceModule.specialistAssignment: _e,
        WorkspaceModule.reports: _e,
        WorkspaceModule.iep: _v,
        WorkspaceModule.caseConference: _e,
        WorkspaceModule.referrals: _v,
        WorkspaceModule.auditLog: _v,
      },
    ),
    UserRole.superAdmin => SpecialistWorkspace(
      role: role,
      title: 'Tizim administratori kabineti',
      mission:
          'Barcha muassasalar, foydalanuvchilar va rollarni boshqarish, umumiy monitoring va hisobotlar, DTS talablarini yuklash.',
      modules: const {
        WorkspaceModule.schoolMonitoring: _v,
        WorkspaceModule.userManagement: _e,
        WorkspaceModule.specialistAssignment: _e,
        WorkspaceModule.reports: _e,
        WorkspaceModule.auditLog: _v,
        WorkspaceModule.curriculumAdmin: _e,
      },
    ),
    UserRole.reviewer => SpecialistWorkspace(
      role: role,
      title: 'Kuzatuvchi / metodist kabineti',
      mission: 'Umumiy monitoring va hisobotlarni faqat ko‘rish.',
      modules: const {
        WorkspaceModule.schoolMonitoring: _v,
        WorkspaceModule.reports: _v,
      },
    ),
    UserRole.parent => SpecialistWorkspace(
      role: role,
      title: 'Ota-ona kabineti',
      mission: 'Hozircha yopiq. Keyinchalik: farzandning yutuqlar pasporti va rivojlanishi.',
      modules: const {},
    ),
  };
}
