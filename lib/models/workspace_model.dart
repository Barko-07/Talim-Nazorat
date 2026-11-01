import 'user_model.dart';

// Mutaxassis kabineti: har bir rol o'z vazifasiga mos bo'limlar bilan ishlaydi.
// UI bu ta'rifga qarab menyu va ekranlarni ko'rsatadi; backend esa ruxsatlarni tekshiradi.

/// Kabinet bo'limlari
enum WorkspaceModule {
  caseload('Mening o‘quvchilarim'),
  accessProfile('Imkoniyatlar profili va ishchi sinf'),
  psychAssessment('Psixologik testlar va metodikalar'),
  observationJournal('Emotsional holat va xulq-atvor kuzatuvlari'),
  speechAssessment('Nutq tekshiruvi'),
  soundTracker('Logopedik tovushlar kartasi'),
  developmentAssessment('Sensor-motor va amaliy rivojlanish tekshiruvi'),
  subjectLevel('Fanlar bo‘yicha bilim darajasi (DTS)'),
  subjectTasks('Fan topshiriqlari'),
  learningResults('O‘quv natijalari'),
  sessions('Mashg‘ulotlar jurnali'),
  measurements('O‘lchovlar va rivojlanish dinamikasi'),
  iep('Individual ta’lim va rivojlanish rejasi'),
  referrals('Yo‘naltirishlar'),
  caseConference('Konsilium'),
  reports('Hisobotlar'),
  schoolMonitoring('Maktab monitoringi'),
  specialistAssignment('Mutaxassislarni biriktirish'),
  userManagement('Foydalanuvchilar va rollar'),
  auditLog('Audit jurnali'),
  curriculumAdmin('DTS talablarini yuklash');

  final String title;
  const WorkspaceModule(this.title);
}

enum ModuleAccess {
  view,
  edit;

  String get label => this == ModuleAccess.edit ? 'Kiritish va tahrirlash' : 'Faqat ko‘rish';
}

/// Mashg'ulot shabloni (mutaxassisga mos mavzular)
class SessionTemplate {
  final String topic;
  final String sessionType; // 'Individual', 'Kichik guruhda'
  final int durationMinutes;
  const SessionTemplate(this.topic, this.sessionType, this.durationMinutes);
}

class SpecialistWorkspace {
  final UserRole role;
  final String title;
  final String mission;

  /// Bo'lim -> ruxsat darajasi. Tartib — UI menyusidagi tartib.
  final Map<WorkspaceModule, ModuleAccess> modules;

  /// Mutaxassis ishlatadigan baholash yo'nalishlari (savollar banki shu bo'yicha filtrlanadi)
  final List<String> assessmentDomains;

  /// Mutaxassis odatda qayd etadigan o'lchov ko'rsatkichlari
  final List<String> metricIds;

  final List<SessionTemplate> sessionTemplates;

  /// Kimga yo'naltira oladi (ReferralModel.toSpecialistType qiymatlari)
  final List<String> referralTargets;

  const SpecialistWorkspace({
    required this.role,
    required this.title,
    required this.mission,
    required this.modules,
    this.assessmentDomains = const [],
    this.metricIds = const [],
    this.sessionTemplates = const [],
    this.referralTargets = const [],
  });

  bool has(WorkspaceModule m) => modules.containsKey(m);
  bool canEdit(WorkspaceModule m) => modules[m] == ModuleAccess.edit;

  /// Rol bolalar bilan bevosita ishlaydimi (biriktirilgan o'quvchilar ro'yxati bor)
  bool get worksWithChildren => has(WorkspaceModule.caseload);
}
