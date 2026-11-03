import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/assessment_model.dart';
import '../models/session_model.dart';
import '../models/iep_model.dart';
import '../models/monitoring_alert_model.dart';
import '../models/referral_model.dart';
import '../models/audit_log_model.dart';
import '../models/notification_model.dart';
import '../models/psychologist_observation_model.dart';
import '../models/curriculum_model.dart';
import '../models/subject_task_model.dart';
import '../models/progress_measurement_model.dart';
import '../models/speech_sound_model.dart';
import '../models/achievement_model.dart';
import '../models/case_conference_model.dart';

class SeedData {
  /// Namunaviy hisoblar paroli. Faqat debug yoki DEMO_MODE rejimida qabul qilinadi
  /// (LocalDbService.verifyPassword); haqiqiy foydalanuvchi hisobi uchun emas.
  static const demoPassword = 'Parol2026!';

  static List<UserModel> get users => [
    UserModel(
      id: 'user_admin',
      email: 'admin@talim.uz',
      fullName: 'Rahimov Sarvar Komilovich',
      role: UserRole.superAdmin,
      region: 'Namangan viloyati',
      district: 'Namangan shahri',
      institutionId: 'inst_namangan_admin',
      institutionName:
          'Namangan viloyat Maktabgacha va maktab ta’limi boshqarmasi',
      phone: '+998 90 123-45-67',
      specialization: 'Viloyat ta’lim koordinatori',
    ),
    UserModel(
      id: 'user_coordinator',
      email: 'koordinator@talim.uz',
      fullName: 'Hakimova Zebo Erkinovna',
      role: UserRole.coordinator,
      region: 'Namangan viloyati',
      district: 'Chortoq tumani',
      institutionId: 'inst_chortoq_5',
      institutionName: '5-sonli umumiy o‘rta ta’lim maktabi',
      phone: '+998 90 765-43-21',
      specialization: 'Ta’lim koordinatori va ITR eksperti',
    ),
    UserModel(
      id: 'user_psychologist',
      email: 'psixolog@talim.uz',
      fullName: 'Usmonova Dilnoza Anvarovna',
      role: UserRole.psychologist,
      region: 'Namangan viloyati',
      district: 'Chortoq tumani',
      institutionId: 'inst_chortoq_5',
      institutionName: '5-sonli umumiy o‘rta ta’lim maktabi',
      phone: '+998 93 345-67-89',
      specialization: 'Bolalar amaliyotchi psixologi',
    ),
    UserModel(
      id: 'user_speech',
      email: 'logoped@talim.uz',
      fullName: 'Sodiqov Bobur Mirzayevich',
      role: UserRole.speechTherapist,
      region: 'Namangan viloyati',
      district: 'Chortoq tumani',
      institutionId: 'inst_chortoq_5',
      institutionName: '5-sonli umumiy o‘rta ta’lim maktabi',
      phone: '+998 94 456-78-90',
      specialization: 'Logoped-defektolog',
    ),
    UserModel(
      id: 'user_special_ed',
      email: 'defektolog@talim.uz',
      fullName: 'Axmedova Madina Rustamovna',
      role: UserRole.specialEducation,
      region: 'Namangan viloyati',
      district: 'Chortoq tumani',
      institutionId: 'inst_chortoq_5',
      institutionName: '5-sonli umumiy o‘rta ta’lim maktabi',
      phone: '+998 95 567-89-01',
      specialization: 'Maxsus pedagog / Defektolog',
    ),
    UserModel(
      id: 'user_teacher',
      email: 'oqituvchi@talim.uz',
      fullName: 'Nazarov Farrux Odilovich',
      role: UserRole.teacher,
      region: 'Namangan viloyati',
      district: 'Chortoq tumani',
      institutionId: 'inst_chortoq_5',
      institutionName: '5-sonli umumiy o‘rta ta’lim maktabi',
      phone: '+998 97 678-90-12',
      specialization: 'Inklyuziv sinf rahbari va fan o‘qituvchisi',
    ),
    UserModel(
      id: 'user_reviewer',
      email: 'kuzatuvchi@talim.uz',
      fullName: 'Po‘latova Gulchehra Ziyodovna',
      role: UserRole.reviewer,
      region: 'Namangan viloyati',
      district: 'Namangan shahri',
      institutionId: 'inst_namangan_metodist',
      institutionName:
          'Namangan viloyat ta’lim sifatini monitoring qilish markazi',
      phone: '+998 98 789-01-23',
      specialization: 'Viloyat bosh metodisti',
    ),
  ];

  static List<StudentModel> get students => [
    StudentModel(
      id: 'student_01',
      institutionId: 'inst_chortoq_5',
      institutionName: '5-sonli umumiy o‘rta ta’lim maktabi',
      firstName: 'Jasur',
      lastName: 'Aliyev',
      middleName: 'Sherzodovich',
      dateOfBirth: DateTime(2016, 5, 14),
      gender: 'Erkak',
      grade: '3-A',
      status: 'Faol',
      primaryNeed: 'Nutqiy rivojlanishdan orqada qolish (Fonetik-fonematik)',
      supportLevel: '2-daraja (O‘rta yordam)',
      medicalNotes: 'Tug‘ruq asoratlari, eshitish a’zolari me’yorda',
      psychologicalNotes:
          'Diqqat barqaror, muloqotga moyil, yangi vazifalarga qiziqadi',
      guardians: [
        GuardianModel(
          id: 'g_01',
          fullName: 'Aliyev Sherzod Mahmudovich',
          relationship: 'Otasi',
          phone: '+998 90 999-88-77',
          email: 'sherzod.aliyev@mail.uz',
          address: 'Chortoq tumani, Mustaqillik MFY, 12-uy',
        ),
      ],
      assignedSpecialistIds: ['user_speech', 'user_psychologist'],
      coordinatorId: 'user_coordinator',
      coordinatorName: 'Hakimova Zebo Erkinovna',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    StudentModel(
      id: 'student_02',
      institutionId: 'inst_chortoq_5',
      institutionName: '5-sonli umumiy o‘rta ta’lim maktabi',
      firstName: 'Malika',
      lastName: 'Rustamova',
      middleName: 'Botirovna',
      dateOfBirth: DateTime(2017, 9, 21),
      gender: 'Ayol',
      grade: '2-B',
      status: 'Faol',
      primaryNeed: 'Diqqat yetishmasligi va giperaktivlik (ADHD)',
      supportLevel: '2-daraja (O‘rta yordam)',
      medicalNotes: 'Nerv tizimi qo‘zg‘aluvchanligi yuqori',
      psychologicalNotes:
          'Vizual signallarga yaxshi javob beradi, tez charchaydi',
      guardians: [
        GuardianModel(
          id: 'g_02',
          fullName: 'Rustamova Zuhra Azimovna',
          relationship: 'Onasi',
          phone: '+998 93 111-22-33',
          address: 'Chortoq tumani, Guliston MFY, 45-uy',
        ),
      ],
      assignedSpecialistIds: ['user_psychologist', 'user_teacher'],
      coordinatorId: 'user_coordinator',
      coordinatorName: 'Hakimova Zebo Erkinovna',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    StudentModel(
      id: 'student_03',
      institutionId: 'inst_chortoq_5',
      institutionName: '5-sonli umumiy o‘rta ta’lim maktabi',
      firstName: 'Bekzod',
      lastName: 'Qodirov',
      middleName: 'Mansurovich',
      dateOfBirth: DateTime(2015, 3, 10),
      gender: 'Erkak',
      grade: '4-A',
      status: 'Faol',
      primaryNeed: 'Bolalar serebral falaji (Yengil gemiparez)',
      supportLevel: '3-daraja (Intensiv yordam)',
      medicalNotes: 'O‘ng qo‘l nozik motorikasi chegaralangan',
      psychologicalNotes: 'Irodali, bilim olishga ishtiyoqi baland',
      guardians: [
        GuardianModel(
          id: 'g_03',
          fullName: 'Qodirov Mansur Hakimovich',
          relationship: 'Otasi',
          phone: '+998 94 222-33-44',
        ),
      ],
      assignedSpecialistIds: ['user_special_ed', 'user_psychologist'],
      coordinatorId: 'user_coordinator',
      coordinatorName: 'Hakimova Zebo Erkinovna',
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
    ),
    StudentModel(
      id: 'student_04',
      institutionId: 'inst_chortoq_5',
      institutionName: '5-sonli umumiy o‘rta ta’lim maktabi',
      firstName: 'Zarnigor',
      lastName: 'Sobirova',
      middleName: 'Alisherovna',
      dateOfBirth: DateTime(2018, 1, 15),
      gender: 'Ayol',
      grade: '1-A',
      status: 'Faol',
      primaryNeed: 'Umumiy nutq rivojlanmaganligi (3-daraja)',
      supportLevel: '2-daraja (O‘rta yordam)',
      medicalNotes: 'Somatik holati qoniqarli',
      psychologicalNotes:
          'Tengdoshlari bilan o‘yinda faol, so‘z boyligi chegaralangan',
      guardians: [
        GuardianModel(
          id: 'g_04',
          fullName: 'Sobirova Nodira Jamshidovna',
          relationship: 'Onasi',
          phone: '+998 97 333-44-55',
        ),
      ],
      assignedSpecialistIds: ['user_speech', 'user_special_ed'],
      coordinatorId: 'user_coordinator',
      coordinatorName: 'Hakimova Zebo Erkinovna',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    StudentModel(
      id: 'student_05',
      institutionId: 'inst_chortoq_5',
      institutionName: '5-sonli umumiy o‘rta ta’lim maktabi',
      firstName: 'Temur',
      lastName: 'Xolmatov',
      middleName: 'Olimovich',
      dateOfBirth: DateTime(2016, 11, 5),
      gender: 'Erkak',
      grade: '3-B',
      status: 'Faol',
      primaryNeed: 'Autizm spektri buzilishi (Yengil shakli)',
      supportLevel: '3-daraja (Intensiv yordam)',
      medicalNotes: 'Sensor disfunksiya mavjud (shovqinga sezgir)',
      psychologicalNotes:
          'Karta va piktogrammalar bilan muvaffaqiyatli ishlaydi',
      guardians: [
        GuardianModel(
          id: 'g_05',
          fullName: 'Xolmatov Olim Baxtiyorovich',
          relationship: 'Otasi',
          phone: '+998 99 444-55-66',
        ),
      ],
      assignedSpecialistIds: [
        'user_psychologist',
        'user_special_ed',
        'user_teacher',
      ],
      coordinatorId: 'user_coordinator',
      coordinatorName: 'Hakimova Zebo Erkinovna',
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
    ),
    StudentModel(
      id: 'student_06',
      institutionId: 'inst_chortoq_5',
      institutionName: '5-sonli umumiy o‘rta ta’lim maktabi',
      firstName: 'Rayhona',
      lastName: 'Ibrohimova',
      middleName: 'Umarovna',
      dateOfBirth: DateTime(2017, 4, 18),
      gender: 'Ayol',
      grade: '2-A',
      status: 'Faol',
      primaryNeed: 'Eshitish zaifligi (1-daraja, eshitish apparati bilan)',
      supportLevel: '2-daraja (O‘rta yordam)',
      medicalNotes: 'Surdolog nazoratida, koxlear apparat taqqan',
      psychologicalNotes: 'Lab harakatidan o‘qishni yaxshi o‘zlashtirgan',
      guardians: [
        GuardianModel(
          id: 'g_06',
          fullName: 'Ibrohimova Fotima Komilovna',
          relationship: 'Onasi',
          phone: '+998 90 555-66-77',
        ),
      ],
      assignedSpecialistIds: ['user_speech', 'user_teacher'],
      coordinatorId: 'user_coordinator',
      coordinatorName: 'Hakimova Zebo Erkinovna',
      createdAt: DateTime.now().subtract(const Duration(days: 80)),
    ),
  ];

  static List<AssessmentModel> get assessments => [
    AssessmentModel(
      id: 'ass_01',
      studentId: 'student_01',
      studentName: 'Aliyev Jasur',
      specialistId: 'user_speech',
      specialistName: 'Sodiqov Bobur Mirzayevich',
      specialistRole: 'Logoped-defektolog',
      assessmentDate: DateTime.now().subtract(const Duration(days: 14)),
      type: 'Standart balli (Rubrika)',
      category: 'Nutq va muloqot',
      title: 'Fonematik idrok va tovush talaffuzi diagnostikasi',
      notes: 'R va L tovushlari talaffuzida sezilarli ijobiy siljish bor.',
      recommendations:
          'Haftasiga 2 marta differensiyalash mashg‘ulotlarini davom ettirish.',
      totalScore: 78,
      maxScore: 100,
      previousScore: 68,
      reviewDate: DateTime.now().add(const Duration(days: 30)),
      criteria: [
        AssessmentCriterionResult(
          criterionName: 'Tovushlarni to‘g‘ri artikulyatsiya qilish',
          score: 24,
          maxScore: 30,
        ),
        AssessmentCriterionResult(
          criterionName: 'Fonematik tahlil va sintez ko‘nikmasi',
          score: 22,
          maxScore: 30,
        ),
        AssessmentCriterionResult(
          criterionName: 'Lug‘at boyligi va bog‘lanishli nutq',
          score: 32,
          maxScore: 40,
        ),
      ],
    ),
    AssessmentModel(
      id: 'ass_02',
      studentId: 'student_02',
      studentName: 'Rustamova Malika',
      specialistId: 'user_psychologist',
      specialistName: 'Usmonova Dilnoza Anvarovna',
      specialistRole: 'Amaliyotchi psixolog',
      assessmentDate: DateTime.now().subtract(const Duration(days: 8)),
      type: 'Sifatli pedagogik kuzatuv',
      category: 'Kognitiv va psixologik',
      title: 'Ixtiyoriy diqqat va o‘z-o‘zini boshqarish testi',
      notes:
          'Diqqat konsentratsiyasi 12 daqiqagacha cho‘zildi (ilgari 6-7 daqiqa edi).',
      recommendations:
          'Mashg‘ulotlar orasida qisqa tanaffus va vizual jadvaldan foydalanish.',
      totalScore: 65,
      maxScore: 100,
      previousScore: 65, // No change (Qoida 3)
      reviewDate: DateTime.now().add(const Duration(days: 15)),
      criteria: [
        AssessmentCriterionResult(
          criterionName: 'Diqqat barqarorligi',
          score: 18,
          maxScore: 30,
        ),
        AssessmentCriterionResult(
          criterionName: 'Ko‘rsatmalarga rioya qilish',
          score: 22,
          maxScore: 35,
        ),
        AssessmentCriterionResult(
          criterionName: 'Ixtiyoriy eslab qolish',
          score: 25,
          maxScore: 35,
        ),
      ],
    ),
  ];

  static List<SessionModel> get sessions => [
    SessionModel(
      id: 'ses_01',
      studentId: 'student_01',
      studentName: 'Aliyev Jasur',
      specialistId: 'user_speech',
      specialistName: 'Sodiqov Bobur Mirzayevich',
      specialistRole: 'Logoped-defektolog',
      scheduledAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      durationMinutes: 45,
      status: 'Bajarildi',
      topic: 'R tovushini bo‘g‘inlarda avtomatlashtirish',
      sessionType: 'Individual',
      goalDescription: 'R tovushini to‘g‘ri talaffuz qilish',
      activities:
          'Artikulyatsion gimnastika, piktogrammali kartalar bilan talaffuz mashqi.',
      observations: 'Bolada rag‘bat yuqori, topshiriqlarni mustaqil bajardi.',
      nextSteps: 'So‘zlar tarkibida qo‘llashga o‘tish.',
      attendanceConfirmed: true,
    ),
    SessionModel(
      id: 'ses_02',
      studentId: 'student_05',
      studentName: 'Xolmatov Temur',
      specialistId: 'user_speech',
      specialistName: 'Sodiqov Bobur Mirzayevich',
      specialistRole: 'Logoped-defektolog',
      scheduledAt: DateTime.now().subtract(const Duration(days: 3)),
      durationMinutes: 45,
      status: 'Qatnashmadi',
      topic: 'Sensor integratsiya va nutq nafasi',
      sessionType: 'Individual',
      observations: 'O‘quvchi mashg‘ulotga kelmadi. Sababi: oilaviy holat.',
      attendanceConfirmed: false,
    ),
    SessionModel(
      id: 'ses_03',
      studentId: 'student_05',
      studentName: 'Xolmatov Temur',
      specialistId: 'user_speech',
      specialistName: 'Sodiqov Bobur Mirzayevich',
      specialistRole: 'Logoped-defektolog',
      scheduledAt: DateTime.now().subtract(const Duration(days: 1)),
      durationMinutes: 45,
      status: 'Qatnashmadi',
      topic: 'Tovushlar talaffuzini mustahkamlash',
      sessionType: 'Individual',
      observations: 'O‘quvchi kelmadi (ketma-ket 2-marta).',
      attendanceConfirmed: false,
    ),
    SessionModel(
      id: 'ses_04',
      studentId: 'student_02',
      studentName: 'Rustamova Malika',
      specialistId: 'user_psychologist',
      specialistName: 'Usmonova Dilnoza Anvarovna',
      specialistRole: 'Amaliyotchi psixolog',
      scheduledAt: DateTime.now().add(const Duration(days: 1, hours: 2)),
      durationMinutes: 40,
      status: 'Rejalashtirilgan',
      topic: 'Diqqatni jamlash bo‘yicha korreksion o‘yinlar',
      sessionType: 'Individual',
      attendanceConfirmed: false,
    ),
  ];

  static List<IndividualEducationPlanModel> get iepPlans => [
    IndividualEducationPlanModel(
      id: 'iep_01',
      studentId: 'student_01',
      studentName: 'Aliyev Jasur',
      studentGrade: '3-A',
      institutionName: '5-sonli umumiy o‘rta ta’lim maktabi',
      title: 'Aliyev Jasur uchun 2026/2027 o‘quv yili ITR',
      academicYear: '2026-2027',
      startDate: DateTime(2026, 9, 2),
      reviewDate: DateTime(2026, 12, 25),
      responsibleTeacherId: 'user_teacher',
      responsibleTeacherName: 'Nazarov Farrux Odilovich',
      coordinatorId: 'user_coordinator',
      coordinatorName: 'Hakimova Zebo Erkinovna',
      status: 'Faol',
      baselineSummary:
          'Nutq tovushlari talaffuzida fonetik nuqsonlar bor, lug‘at boyligi yoshiga nisbatan chegaralangan.',
      longTermGoals:
          'Yil oxiriga qadar barcha tovushlarni to‘g‘ri artikulyatsiya qilish va o‘quv matnlarini tushunib o‘qish.',
      supportStrategies:
          'Haftasiga 2 marta individual logopedik mashg‘ulot, sinfda vizual jadvaldan foydalanish.',
      objectives: [
        PlanObjectiveModel(
          id: 'obj_01',
          title: 'R va L tovushlarini so‘z boshida to‘g‘ri talaffuz qilish',
          domain: 'Nutq va muloqot',
          targetDate: DateTime(2026, 10, 30),
          status: 'Jarayonda',
          progressPercent: 75,
          successCriteria: '10 ta so‘zdan 8 tasida to‘g‘ri talaffuz',
        ),
        PlanObjectiveModel(
          id: 'obj_02',
          title:
              'Qisqa ertak mazmunini 4-5 ta to‘liq gap bilan qayta so‘zlab berish',
          domain: 'Nutq va muloqot',
          targetDate: DateTime(2026, 11, 20),
          status: 'Jarayonda',
          progressPercent: 60,
          successCriteria: 'Ketma-ketlikni buzmasdan voqealar zanjirini aytish',
        ),
        PlanObjectiveModel(
          id: 'obj_03',
          title: 'Doskadagi qisqa matnni daftarga xatosiz ko‘chirib yozish',
          domain: 'O‘quv va dars faoliyati',
          targetDate: DateTime(2026, 12, 10),
          status: 'Rejalashtirilgan',
          progressPercent: 40,
          successCriteria: 'Harf tushirib qoldirmasdan 25 ta so‘zni yozish',
        ),
      ],
    ),
  ];

  static List<MonitoringAlertModel> get monitoringAlerts => [
    MonitoringAlertModel(
      id: 'alt_01',
      ruleCode: 'MISSED_SESSIONS',
      ruleTitle: 'Muntazam qatnashmaslik holati',
      studentId: 'student_05',
      studentName: 'Xolmatov Temur',
      studentGrade: '3-B',
      severity: 'DIQQAT',
      message: 'O‘quvchi ketma-ket 2 ta rejalashtirilgan mashg‘ulotga kelmadi.',
      suggestedAction:
          'Oila bilan bog‘lanish va dars qoldirish sabablarini aniqlash.',
      responsiblePersonName: 'Sodiqov Bobur Mirzayevich',
      responsiblePersonId: 'user_speech',
      status: 'Ochiq',
      isResolved: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static List<ReferralModel> get referrals => [
    ReferralModel(
      id: 'ref_01',
      studentId: 'student_02',
      studentName: 'Rustamova Malika',
      fromSpecialistId: 'user_teacher',
      fromSpecialistName: 'Nazarov Farrux Odilovich',
      fromSpecialistRole: 'Sinf rahbari',
      toSpecialistType: 'Amaliyotchi psixolog',
      toSpecialistId: 'user_psychologist',
      toSpecialistName: 'Usmonova Dilnoza Anvarovna',
      reason:
          'Dars paytida giperaktivlik oshishi va e’tiborning tez chalg‘ishi kuzatildi.',
      priority: 'Rejali',
      status: 'Ko‘rib chiqilmoqda',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ReferralModel(
      id: 'ref_02',
      studentId: 'student_04',
      studentName: 'Sobirova Zarnigor',
      fromSpecialistId: 'user_psychologist',
      fromSpecialistName: 'Usmonova Dilnoza Anvarovna',
      fromSpecialistRole: 'Amaliyotchi psixolog',
      toSpecialistType: 'Logoped-defektolog',
      toSpecialistId: 'user_speech',
      toSpecialistName: 'Sodiqov Bobur Mirzayevich',
      reason:
          'Nutq tovushlarini talaffuz qilishda artikulyatsion apparat tekshiruvi zarur.',
      priority: 'Shoshilinch',
      status: 'Qabul qilindi',
      createdAt: DateTime.now().subtract(const Duration(days: 9)),
    ),
  ];

  static List<AuditLogModel> get auditLogs => [
    AuditLogModel(
      id: 'aud_01',
      userFullName: 'Rahimov Sarvar (Super Admin)',
      userRole: 'Tizim administratori',
      action: 'LOGIN',
      entity: 'Auth',
      details: 'Tizimga muvaffaqiyatli kirildi',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AuditLogModel(
      id: 'aud_02',
      userFullName: 'Sodiqov Bobur (Logoped)',
      userRole: 'Logoped-defektolog',
      action: 'CREATE',
      entity: 'Assessment',
      details: 'Aliyev Jasur uchun fonematik diagnostika saqlandi',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  static List<NotificationModel> get notifications => [
    NotificationModel(
      id: 'notif_01',
      recipientUserId: 'user_speech',
      title: 'Yangi yo‘naltirish (Referral)',
      body:
          'Sobirova Zarnigor sizning logopedik tekshiruvingizga yo‘naltirildi.',
      type: 'REFERRAL',
      relatedRecordId: 'ref_02',
      relatedStudentId: 'student_04',
      relatedStudentName: 'Sobirova Zarnigor',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    NotificationModel(
      id: 'notif_02',
      recipientUserId: 'user_psychologist',
      title: 'ITR ko‘rib chiqish muddati',
      body:
          'Aliyev Jasurning ITR rejasi oraliq baholash sanasi yaqinlashmoqda.',
      type: 'IEP',
      relatedRecordId: 'iep_01',
      relatedStudentId: 'student_01',
      relatedStudentName: 'Aliyev Jasur',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static List<PsychologicalObservationModel> get observations => [
    PsychologicalObservationModel(
      id: 'obs_01',
      studentId: 'student_01',
      studentName: 'Aliyev Jasur',
      studentGrade: '3-A',
      psychologistId: 'user_psychologist',
      psychologistName: 'Usmonova Dilnoza (Psixolog)',
      date: DateTime.now().subtract(const Duration(days: 2)),
      category: 'Darsdagi xulq-atvor',
      emotionalState: 'Barqaror / Ijobiy',
      triggerOrContext: 'Yangi mavzu tushuntirilganda',
      observationText:
          'Dars boshida diqqati barqaror bo‘ldi. Rangli kartochkalar bilan ishlashda qiziqish ko‘rsatdi. O‘qituvchining ko‘rsatmalariga ijobiy javob berdi.',
      recommendationOrAction:
          'Vizual qo‘llanmalar orqali rag‘batlantirishni davom ettirish.',
      isConfidential: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    PsychologicalObservationModel(
      id: 'obs_02',
      studentId: 'student_02',
      studentName: 'Karimova Madina',
      studentGrade: '2-B',
      psychologistId: 'user_psychologist',
      psychologistName: 'Usmonova Dilnoza (Psixolog)',
      date: DateTime.now().subtract(const Duration(days: 3)),
      category: 'Hissiy holat (Affektiv)',
      emotionalState: 'Xavotirli',
      triggerOrContext: 'Yozma mustaqil ish topshirilganda',
      observationText:
          'Vazifani bajarishda xato qilishdan qo‘rqish belgilari kuzatildi. Barmoqlarini asabiy qisirlatish holati bo‘ldi.',
      recommendationOrAction:
          'Xavotirni kamaytiruvchi nafas mashqlari o‘rgatildi, o‘qituvchiga kichik hajmli topshiriqlar berish tavsiya qilindi.',
      isConfidential: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    PsychologicalObservationModel(
      id: 'obs_03',
      studentId: 'student_03',
      studentName: 'Usmonov Botir',
      studentGrade: '1-A',
      psychologistId: 'user_psychologist',
      psychologistName: 'Usmonova Dilnoza (Psixolog)',
      date: DateTime.now().subtract(const Duration(days: 5)),
      category: 'Tengdoshlar bilan muloqot',
      emotionalState: 'Tirishqoq / Chalg‘uvchan',
      triggerOrContext: 'Tanaffus paytida jamoaviy o‘yinda',
      observationText:
          'Tengdoshlari bilan muloqotga kirishishga harakat qildi, biroq o‘yin qoidalarini oxirigacha kutishda sabrsizlik qildi.',
      recommendationOrAction:
          'Rolli ijtimoiy moslashuv o‘yinlarida psixolog nazoratida qatnashtirish.',
      isConfidential: true,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    PsychologicalObservationModel(
      id: 'obs_04',
      studentId: 'student_01',
      studentName: 'Aliyev Jasur',
      studentGrade: '3-A',
      psychologistId: 'user_psychologist',
      psychologistName: 'Usmonova Dilnoza (Psixolog)',
      date: DateTime.now().subtract(const Duration(days: 1)),
      category: 'Kognitiv faollik va diqqat',
      emotionalState: 'Barqaror / Ijobiy',
      triggerOrContext: 'Korreksion individual mashg‘ulotda',
      observationText:
          'Landolt halqalari bo‘yicha diqqat tezligi 15% ga yaxshilandi. Chalg‘ish soni kamaydi.',
      recommendationOrAction:
          'Mantiqiy ketma-ketlik vazifalarini bosqichma-bosqich murakkablashtirish.',
      isConfidential: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static List<SubjectLevelAssessment> get subjectLevels => [
    SubjectLevelAssessment(
      id: 'sl_01',
      studentId: 'student_03',
      subject: SchoolSubjects.matematika,
      classGrade: 4,
      results: const {
        'dts_mat_1_1': Mastery.mastered,
        'dts_mat_1_2': Mastery.mastered,
        'dts_mat_1_3': Mastery.mastered,
        'dts_mat_2_1': Mastery.mastered,
        'dts_mat_2_2': Mastery.mastered,
        'dts_mat_2_3': Mastery.mastered,
        'dts_mat_3_1': Mastery.mastered,
        'dts_mat_3_2': Mastery.mastered,
        'dts_mat_3_3': Mastery.partial,
        'dts_mat_4_1': Mastery.notYet,
        'dts_mat_4_2': Mastery.notYet,
      },
      suggestedGrade: 3,
      confirmedGrade: 3,
      assessedById: 'user_teacher',
      assessedByName: 'Nazarov Farrux Odilovich',
      assessedAt: DateTime.now().subtract(const Duration(days: 6)),
      notes:
          'Rasmiy 4-sinf o‘quvchisi, biroq DTS bo‘yicha 3-sinf matematika dasturini barqaror o‘zlashtirmoqda. Individual 3-sinf darajasida o‘qitiladi.',
    ),
    SubjectLevelAssessment(
      id: 'sl_02',
      studentId: 'student_01',
      subject: SchoolSubjects.oqish,
      classGrade: 3,
      results: const {
        'dts_oqi_1_1': Mastery.mastered,
        'dts_oqi_1_2': Mastery.mastered,
        'dts_oqi_1_3': Mastery.mastered,
        'dts_oqi_2_1': Mastery.mastered,
        'dts_oqi_2_2': Mastery.mastered,
        'dts_oqi_2_3': Mastery.partial,
        'dts_oqi_3_1': Mastery.notYet,
      },
      suggestedGrade: 2,
      confirmedGrade: 2,
      assessedById: 'user_teacher',
      assessedByName: 'Nazarov Farrux Odilovich',
      assessedAt: DateTime.now().subtract(const Duration(days: 10)),
      notes:
          'O‘qish va adabiyotdan 2-sinf me’yorlariga mos; bo‘g‘inlab va so‘zlab o‘qish tezligi ustida ishlanmoqda.',
    ),
    SubjectLevelAssessment(
      id: 'sl_03',
      studentId: 'student_05',
      subject: SchoolSubjects.matematika,
      classGrade: 3,
      results: const {
        'dts_mat_1_1': Mastery.mastered,
        'dts_mat_1_2': Mastery.mastered,
        'dts_mat_1_3': Mastery.partial,
        'dts_mat_2_1': Mastery.notYet,
      },
      suggestedGrade: 1,
      confirmedGrade: 1,
      assessedById: 'user_teacher',
      assessedByName: 'Nazarov Farrux Odilovich',
      assessedAt: DateTime.now().subtract(const Duration(days: 12)),
      notes:
          'Vizual kartochkalar yordamida 1-sinf matematika dasturi (20 ichida qo‘shish va ayirish) asosida individual ishlanmoqda.',
    ),
  ];

  static List<SubjectTask> get subjectTasks => [
    SubjectTask(
      id: 'tsk_01',
      studentId: 'student_03',
      subject: SchoolSubjects.matematika,
      levelGrade: 3,
      standardId: 'dts_mat_3_3',
      title: 'Matnli masalalarni 2 amal bilan yechish (3-sinf DTS)',
      description:
          'Kattalashtirilgan shriftli kartochkada berilgan 3 ta matnli masalani chizma yordamida yechish.',
      assignedById: 'user_teacher',
      assignedByName: 'Nazarov Farrux Odilovich',
      assignedAt: DateTime.now().subtract(const Duration(days: 5)),
      dueDate: DateTime.now().add(const Duration(days: 7)),
      result: Mastery.mastered,
      resultNote: '3 ta masaladan 3 tasini mustaqil to‘g‘ri yechdi.',
      completedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    SubjectTask(
      id: 'tsk_02',
      studentId: 'student_01',
      subject: SchoolSubjects.oqish,
      levelGrade: 2,
      standardId: 'dts_oqi_2_3',
      title: 'Qisqa hikoyani o‘qib, asosiy qahramon harakatini aytib berish',
      description:
          '5-6 gapdan iborat hikoyani ovoz chiqarib o‘qish va savollarga javob berish.',
      assignedById: 'user_teacher',
      assignedByName: 'Nazarov Farrux Odilovich',
      assignedAt: DateTime.now().subtract(const Duration(days: 4)),
      dueDate: DateTime.now().add(const Duration(days: 5)),
    ),
  ];

  static List<ProgressMeasurement> get measurements => [
    ProgressMeasurement(
      id: 'msr_01',
      studentId: 'student_01',
      metricId: 'metric_attention_minutes',
      value: 3,
      measuredAt: DateTime.now().subtract(const Duration(days: 35)),
      recordedById: 'user_psychologist',
      recordedByName: 'Usmonova Dilnoza Anvarovna',
      note: 'Boshlang‘ich holat: 3 daqiqadan so‘ng chalg‘ish kuzatildi.',
    ),
    ProgressMeasurement(
      id: 'msr_02',
      studentId: 'student_01',
      metricId: 'metric_attention_minutes',
      value: 5,
      measuredAt: DateTime.now().subtract(const Duration(days: 18)),
      recordedById: 'user_psychologist',
      recordedByName: 'Usmonova Dilnoza Anvarovna',
      note: 'Vizual taymer qo‘llanganda 5 daqiqagacha barqaror ishladi.',
    ),
    ProgressMeasurement(
      id: 'msr_03',
      studentId: 'student_01',
      metricId: 'metric_attention_minutes',
      value: 8,
      measuredAt: DateTime.now().subtract(const Duration(days: 3)),
      recordedById: 'user_psychologist',
      recordedByName: 'Usmonova Dilnoza Anvarovna',
      note: 'O‘sish: 8 daqiqa davomida mustaqil topshiriq bajardi.',
    ),
    ProgressMeasurement(
      id: 'msr_04',
      studentId: 'student_01',
      metricId: 'metric_reading_wpm',
      value: 18,
      measuredAt: DateTime.now().subtract(const Duration(days: 30)),
      recordedById: 'user_teacher',
      recordedByName: 'Nazarov Farrux Odilovich',
      note: 'Bo‘g‘inlab o‘qish: 18 so‘z/daqiqa.',
    ),
    ProgressMeasurement(
      id: 'msr_05',
      studentId: 'student_01',
      metricId: 'metric_reading_wpm',
      value: 29,
      measuredAt: DateTime.now().subtract(const Duration(days: 4)),
      recordedById: 'user_teacher',
      recordedByName: 'Nazarov Farrux Odilovich',
      note: 'So‘zlab o‘qishga o‘tdi: 29 so‘z/daqiqa.',
    ),
  ];

  static List<SoundEntry> get soundEntries => [
    SoundEntry(
      id: 'snd_01',
      studentId: 'student_01',
      soundId: 'r',
      stage: SoundStage.preparation,
      disorder: SoundDisorder.substitution,
      substitutedWith: 'l',
      note: 'R tovushini L ga almashtiradi, artikulyatsion mashqlar boshlandi.',
      recordedById: 'user_speech',
      recordedByName: 'Sodiqov Bobur Mirzayevich',
      recordedAt: DateTime.now().subtract(const Duration(days: 28)),
    ),
    SoundEntry(
      id: 'snd_02',
      studentId: 'student_01',
      soundId: 'r',
      stage: SoundStage.staging,
      disorder: SoundDisorder.none,
      note: 'Titrash hosil qilindi, R tovushi alohida qo‘yildi.',
      recordedById: 'user_speech',
      recordedByName: 'Sodiqov Bobur Mirzayevich',
      recordedAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
    SoundEntry(
      id: 'snd_03',
      studentId: 'student_01',
      soundId: 'r',
      stage: SoundStage.words,
      disorder: SoundDisorder.none,
      note: 'So‘z boshida va o‘rtasida R tovushini to‘g‘ri talaffuz qilmoqda.',
      recordedById: 'user_speech',
      recordedByName: 'Sodiqov Bobur Mirzayevich',
      recordedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    SoundEntry(
      id: 'snd_04',
      studentId: 'student_01',
      soundId: 'l',
      stage: SoundStage.spontaneous,
      disorder: SoundDisorder.none,
      note: 'L tovushi erkin nutqda to‘liq avtomatlashtirildi!',
      recordedById: 'user_speech',
      recordedByName: 'Sodiqov Bobur Mirzayevich',
      recordedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static List<Achievement> get achievements => [
    Achievement(
      id: 'ach_01',
      studentId: 'student_01',
      category: AchievementCategory.skill,
      title: '«L» tovushini erkin nutqda xatosiz talaffuz qilishga erishdi',
      description:
          'Logopedik mashg‘ulotlar natijasida L tovushi to‘liq o‘zlashtirildi.',
      achievedAt: DateTime.now().subtract(const Duration(days: 5)),
      recordedById: 'user_speech',
      recordedByName: 'Sodiqov Bobur Mirzayevich',
    ),
    Achievement(
      id: 'ach_02',
      studentId: 'student_03',
      category: AchievementCategory.subject,
      title:
          'Matematikadan 3-sinf DTS darajasidagi 2 amalli masalalarni mustaqil yechdi',
      description:
          'Individual moslashtirilgan 3-sinf dasturi bo‘yicha yuqori natija.',
      achievedAt: DateTime.now().subtract(const Duration(days: 1)),
      recordedById: 'user_teacher',
      recordedByName: 'Nazarov Farrux Odilovich',
    ),
  ];

  static List<CaseConference> get conferences => [
    CaseConference(
      id: 'cnf_01',
      studentId: 'student_01',
      studentName: 'Aliyev Jasur',
      agenda:
          '1-chorak yakuni bo‘yicha logoped, psixolog va maxsus o‘qituvchi qo‘shma konsiliumi',
      scheduledAt: DateTime.now().subtract(const Duration(days: 4)),
      convenedById: 'user_coordinator',
      convenedByName: 'Hakimova Zebo Erkinovna',
      participantIds: const [
        'user_coordinator',
        'user_speech',
        'user_psychologist',
        'user_teacher',
      ],
      status: ConferenceStatus.held,
      contributions: [
        ConferenceContribution(
          userId: 'user_speech',
          userName: 'Sodiqov Bobur Mirzayevich',
          role: 'Logoped-defektolog',
          summary:
              'L tovushi erkin nutqqa chiqdi, R tovushi so‘zlarda avtomatlashtirilmoqda.',
          recommendations:
              'Ota-onaga uyda har kuni 10 daqiqa artikulyatsion mashq berish.',
          at: DateTime.now().subtract(const Duration(days: 4)),
        ),
        ConferenceContribution(
          userId: 'user_psychologist',
          userName: 'Usmonova Dilnoza Anvarovna',
          role: 'Amaliyotchi psixolog',
          summary: 'Diqqat davomiyligi 3 daqiqadan 8 daqiqagacha oshdi.',
          recommendations:
              'Darsda vizual jadval va rag‘bat stikerlarini davom ettirish.',
          at: DateTime.now().subtract(const Duration(days: 4)),
        ),
      ],
      conclusion:
          'Barcha yo‘nalishlarda ijobiy dinamika tasdiqlandi. O‘qish fanidan 2-sinf darajasidan 3-sinf DTS talablariga bosqichma-bosqich o‘tkazish tavsiya etildi.',
      decisions: [
        ConferenceDecision(
          id: 'dec_01',
          text:
              'R va L tovushlarini farqlash (differensiatsiya) mashqlarini boshlash',
          responsibleId: 'user_speech',
          responsibleName: 'Sodiqov Bobur Mirzayevich',
          dueDate: DateTime.now().add(const Duration(days: 14)),
          isDone: false,
        ),
      ],
    ),
  ];
}
