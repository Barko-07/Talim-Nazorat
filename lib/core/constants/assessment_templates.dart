import '../../models/user_model.dart';

class AssessmentTemplateField {
  final String key;
  final String label;
  final String hint;
  final double maxScore;
  final double defaultScore;

  const AssessmentTemplateField({
    required this.key,
    required this.label,
    required this.hint,
    this.maxScore = 25.0,
    this.defaultScore = 20.0,
  });
}

class AssessmentTemplate {
  final String category;
  final String title;
  final UserRole targetRole;
  final String description;
  final List<AssessmentTemplateField> fields;
  final List<String> standardRecommendations;

  const AssessmentTemplate({
    required this.category,
    required this.title,
    required this.targetRole,
    required this.description,
    required this.fields,
    required this.standardRecommendations,
  });
}

class AssessmentTemplates {
  static const String disclaimerNotice =
      'Eslatma: Ushbu baholash mutaxassisning kasbiy pedagogik-psixologik kuzatuv natijasidir va tibbiy yoki psixiatrik tashxis hisoblanmaydi.';

  static const List<AssessmentTemplate> all = [
    // 1. LOGOPED-DEFEKTOLOG TEMPLAYTI
    AssessmentTemplate(
      category: 'Nutq va muloqot',
      title: 'Logopedik nutq va artikulyatsiya diagnostikasi',
      targetRole: UserRole.speechTherapist,
      description: 'Tovushlar talaffuzi, fonematik idrok, artikulyatsion apparat va bog‘lanishli nutq ko‘nikmalari tahlili.',
      fields: [
        AssessmentTemplateField(
          key: 'speech_sounds',
          label: 'Tovushlar talaffuzi va fonetik aniqlik',
          hint: 'Unli va undosh tovushlarni to‘g‘ri artikulyatsiya qilish',
          maxScore: 25.0,
          defaultScore: 18.0,
        ),
        AssessmentTemplateField(
          key: 'phonemic_hearing',
          label: 'Fonematik eshitish va idrok',
          hint: 'O‘xshash tovushlarni ajrata olish, fonematik tahlil va sintez',
          maxScore: 25.0,
          defaultScore: 19.0,
        ),
        AssessmentTemplateField(
          key: 'articulation',
          label: 'Artikulyatsion apparat va nafas kuchi',
          hint: 'Til, lab va jag‘ harakatchanligi, nutq nafasi barqarorligi',
          maxScore: 25.0,
          defaultScore: 20.0,
        ),
        AssessmentTemplateField(
          key: 'connected_speech',
          label: 'Bog‘lanishli nutq va so‘z boyligi',
          hint: 'Lug‘at boyligi, gap tuzilishi, dialog va monolog yuritish',
          maxScore: 25.0,
          defaultScore: 18.0,
        ),
      ],
      standardRecommendations: [
        'Artikulyatsion gimnastika va nafas mashqlarini kunlik 10 daqiqa bajarish.',
        'Tovushlarni avtomatlashtirish bo‘yicha logopedik kartochkalar bilan ishlash.',
        'Uyda ota-ona bilan fonematik o‘yinlar (so‘zdagi tovushni topish) o‘ynash.',
      ],
    ),

    // 2. PSIXOLOG TEMPLAYTI
    AssessmentTemplate(
      category: 'Kognitiv va psixologik',
      title: 'Psixologik kognitiv va emotsional rivojlanish',
      targetRole: UserRole.psychologist,
      description: 'Diqqat barqarorligi, xotira, tafakkur tezligi, hissiy-irodaviy holat va motivatsiya tahlili.',
      fields: [
        AssessmentTemplateField(
          key: 'attention',
          label: 'Diqqat barqarorligi va konsentratsiya',
          hint: 'Topshiriqqa diqqatni jamlay olish, chalg‘imaslik darajasi',
          maxScore: 25.0,
          defaultScore: 20.0,
        ),
        AssessmentTemplateField(
          key: 'memory_thinking',
          label: 'Xotira va ko‘rgazmali-obrazli tafakkur',
          hint: 'Qisqa va uzoq muddatli eslab qolish, mantiqiy bog‘liqlikni topish',
          maxScore: 25.0,
          defaultScore: 19.0,
        ),
        AssessmentTemplateField(
          key: 'emotional_behavior',
          label: 'Emotsional-irodaviy soha va xulq-atvor',
          hint: 'Hissiyotlarni boshqara olish, qoidalarga rioya qilish, xavotir darajasi',
          maxScore: 25.0,
          defaultScore: 21.0,
        ),
        AssessmentTemplateField(
          key: 'social_motivation',
          label: 'Ijtimoiy moslashuv va o‘quv motivatsiyasi',
          hint: 'Tengdoshlar bilan muloqot, yangi bilimlarga intilish',
          maxScore: 25.0,
          defaultScore: 20.0,
        ),
      ],
      standardRecommendations: [
        'Darsda diqqatni jamlash uchun vizual tayanch va rag‘batlantirish tizimidan foydalanish.',
        'Hissiy zo‘riqishni kamaytirish uchun qisqa dam olish daqiqalarini joriy etish.',
        'Sinf jamoasida hamkorlikdagi ijtimoiy rolli o‘yinlarda faol qatnashtirish.',
      ],
    ),

    // 3. MAXSUS PEDAGOG (DEFEKTOLOG) TEMPLAYTI
    AssessmentTemplate(
      category: 'Maxsus pedagogika va sensorika',
      title: 'Sensor-motorika va maxsus pedagogik o‘rganish',
      targetRole: UserRole.specialEducation,
      description: 'Sensor integratsiya, fazoviy tasavvur, motorika va hayotiy ko‘nikmalar holati.',
      fields: [
        AssessmentTemplateField(
          key: 'sensory_integration',
          label: 'Sensor integratsiya va fazoviy tushunchalar',
          hint: 'Rang, hajm, shakllarni farqlash, o‘ng-chapni to‘g‘ri bilish',
          maxScore: 25.0,
          defaultScore: 20.0,
        ),
        AssessmentTemplateField(
          key: 'motor_skills',
          label: 'Mayda va yirik motorika epchilligi',
          hint: 'Qalam ushlash, qaychi bilan ishlash, harakat koordinatsiyasi',
          maxScore: 25.0,
          defaultScore: 19.0,
        ),
        AssessmentTemplateField(
          key: 'academic_readiness',
          label: 'O‘quv ko‘nikmalari va topshiriq bajarish',
          hint: 'Oddiy hisob-kitob, harflarni idrok etish, ko‘rsatmalarga amal qilish',
          maxScore: 25.0,
          defaultScore: 18.0,
        ),
        AssessmentTemplateField(
          key: 'life_independence',
          label: 'O‘z-o‘ziga xizmat va amaliy mustaqillik',
          hint:
              'Kiyinish, ovqatlanish, buyumlarni tartibga solish mustaqilligi',
          maxScore: 25.0,
          defaultScore: 22.0,
        ),
      ],
      standardRecommendations: [
        'Grafomotorikani rivojlantiruvchi barmoq gimnastikasi va lepkadan foydalanish.',
        'Fazoviy tushunchalarni mustahkamlash uchun sensor konstruktorlar qo‘llash.',
        'O‘z-o‘ziga xizmat ko‘rsatish qoidalarini vizual qadamlar ketma-ketligida o‘rgatish.',
      ],
    ),

    // 4. FAN O'QITUVCHISI / SINF RAHBARI TEMPLAYTI
    AssessmentTemplate(
      category: 'O‘quv va dars faoliyati',
      title: 'Pedagogik o‘quv faoliyati va moslashuv monitoringi',
      targetRole: UserRole.teacher,
      description: 'Dars mashg‘ulotlaridagi faollik, topshiriqlarni o‘zlashtirish va sinfdagi xatti-harakat.',
      fields: [
        AssessmentTemplateField(
          key: 'academic_progress',
          label: 'O‘quv dasturini o‘zlashtirish darajasi',
          hint: 'Dars mavzularini tushunish, yozma va og‘zaki vazifalar ijrosi',
          maxScore: 25.0,
          defaultScore: 21.0,
        ),
        AssessmentTemplateField(
          key: 'class_participation',
          label: 'Darsdagi faollik va qiziqish',
          hint: 'Savollarga javob berish, dars jarayonida ishtirok etish',
          maxScore: 25.0,
          defaultScore: 20.0,
        ),
        AssessmentTemplateField(
          key: 'following_instructions',
          label: 'O‘qituvchi ko‘rsatmalariga rioya qilish',
          hint: 'Qoidalarga bo‘ysunish, o‘quv qurollaridan to‘g‘ri foydalanish',
          maxScore: 25.0,
          defaultScore: 22.0,
        ),
        AssessmentTemplateField(
          key: 'peer_interaction',
          label: 'Sinfdoshlar bilan hamkorlik munosabati',
          hint: 'Guruh bilan ishlash, do‘stona muloqot va ijtimoiy ko‘nikmalar',
          maxScore: 25.0,
          defaultScore: 20.0,
        ),
      ],
      standardRecommendations: [
        'Darsda o‘quv materialini qisqa va aniq vizual slaydlarda taqdim etish.',
        'Individual ta’lim rejasidagi maqsadlarga moslashtirilgan sinf topshiriqlari berish.',
        'Ijobiy rag‘batlantirish orqali fanga bo‘lgan ishtiyoqni oshirish.',
      ],
    ),
  ];

  static AssessmentTemplate getTemplateForRole(UserRole role) {
    return all.firstWhere((t) => t.targetRole == role, orElse: () => all.first);
  }
}
