/// Metodika qaysi mutaxassislik uchun
enum MethodProfession {
  psychology('Psixologiya'),
  defectology('Defektologiya'),
  speechTherapy('Logopediya');

  final String label;
  const MethodProfession(this.label);
}

class PsychologicalMethodItem {
  final String id;
  final String code;
  final String title;
  final String author;
  final String targetAge;
  final String
  domain; // 'Kognitiv va intellekt', 'Diqqat va ishchanlik', 'Xotira jarayonlari', 'Emotsional va xavotir', 'Shaxsiyat va moslashuv'
  final int durationMinutes;
  final String purpose;
  final String instructions;
  final List<String> subscales;
  final String scoringGuide;
  final double maxScore;
  final String normCriteria;
  final MethodProfession profession;

  /// Metodika mualliflik huquqi bilan himoyalangan: test materiallari va me'yor jadvallari
  /// faqat litsenziyalangan nashrdan olinadi, ilovada saqlanmaydi.
  final bool requiresLicensedMaterials;
  final String? licenseNote;

  const PsychologicalMethodItem({
    required this.id,
    required this.code,
    required this.title,
    required this.author,
    required this.targetAge,
    required this.domain,
    required this.durationMinutes,
    required this.purpose,
    required this.instructions,
    required this.subscales,
    required this.scoringGuide,
    required this.maxScore,
    required this.normCriteria,
    this.profession = MethodProfession.psychology,
    this.requiresLicensedMaterials = false,
    this.licenseNote,
  });
}

class PsychologicalMethodsData {
  static const List<PsychologicalMethodItem> methods = [
    PsychologicalMethodItem(
      id: 'method_raven',
      code: 'RAVEN_CPM',
      title: 'Raven progressiv rangli matritsalari (CPM)',
      author: 'J.C. Raven',
      targetAge: '5 — 11 yosh',
      domain: 'Kognitiv va intellekt',
      durationMinutes: 20,
      purpose:
          'Bolaning noverbal mantiqiy tafakkuri, fazoviy bog‘liqliklarni tahlil qilish va vizual sintez qobiliyatini o‘rganish.',
      instructions:
          'O‘quvchiga ketma-ket 36 ta rangli matritsa (A, Ab, B seriyalar) taqdim etiladi. O‘quvchi bo‘sh katakchaga mantiqan mos tushuvchi parchaning raqamini ko‘rsatadi.',
      subscales: [
        'A seriya — Shakllar yaxlitligi va o‘xshashligi',
        'Ab seriya — Diskret va fazoviy simmetriya',
        'B seriya — Analitik qonuniyat va o‘zgarish dinamikasi',
      ],
      scoringGuide:
          'Har bir to‘g‘ri javob 1 ball. Jami maksimal ball — 36 ball. Foiz darajasi bo‘yicha intellektual salohiyat aniqlanadi.',
      maxScore: 36.0,
      normCriteria:
          'Natijalarni faqat litsenziyalangan qo‘llanmadagi me’yorlar bo‘yicha talqin qiling. Ilova me’yor jadvallarini saqlamaydi va bolaga daraja yorlig‘i qo‘ymaydi.',
      requiresLicensedMaterials: true,
      licenseNote:
          'Test materiallari va me’yorlari nashriyot litsenziyasi bilan himoyalangan.',
    ),
    PsychologicalMethodItem(
      id: 'method_landolt',
      code: 'LANDOLT_RINGS',
      title: 'E.G. Landolt halqalari metodikasi',
      author: 'E.G. Landolt',
      targetAge: '7 — 16 yosh',
      domain: 'Diqqat va ishchanlik',
      durationMinutes: 10,
      purpose:
          'Ixtiyoriy diqqatning barqarorligi, taqsimlanishi, ko‘rish analizatori orqali aqliy ishchanlik tezligi va toliqish ko‘rsatkichini o‘lchash.',
      instructions:
          'Maxsus blankada turli yo‘nalishda tirqishi bo‘lgan halqalar berilgan. Bola 5 daqiqa ichida belgilangan yo‘nalishdagi halqalarni chizib boradi. Har daqiqa oxirida belgi qo‘yiladi.',
      subscales: [
        'Ishchanlik tezligi (A — ko‘rib chiqilgan belgilar soni)',
        'Aniqlik koeffitsiyenti (C — xatolar va tushirib qoldirishlar)',
        'Diqqat barqarorligi indeksi (S — vaqt bo‘yicha dinamika)',
        'Aqliy toliqish grafigi',
      ],
      scoringGuide:
          'Ko‘rib chiqilgan belgilar va xatolar nisbati orqali unumdorlik indeksi hisoblanadi (Maksimal 100 ball shkalasida).',
      maxScore: 100.0,
      normCriteria:
          '80-100 ball: Yuqori diqqat barqarorligi\n60-79 ball: Me’yoriy ko‘rsatkich\n40-59 ball: Chalg‘uvchanlik va tez toliqish\n40 balldan kam: Past diqqat konsentratsiyasi',
    ),
    PsychologicalMethodItem(
      id: 'method_phillips',
      code: 'PHILLIPS_ANXIETY',
      title: 'B.N. Filipps maktab xavotirlanishi testi',
      author: 'B.N. Phillips',
      targetAge: '7 — 12 yosh',
      domain: 'Emotsional va xavotir',
      durationMinutes: 15,
      purpose:
          'Maktab muhitidagi psixoemotsional zo‘riqish, baholanishdan qo‘rquv va o‘qituvchi/tengdoshlar bilan muloqotdagi xavotir darajasini aniqlash.',
      instructions:
          'O‘quvchiga maktab hayotiga doir 58 ta savol o‘qib eshittiriladi. Bola "Ha" yoki "Yo‘q" deb javob beradi.',
      subscales: [
        'Maktabdagi umumiy xavotirlanish',
        'Ijtimoiy stressni boshdan kechirish',
        'Muvaffaqiyatga erishishdagi ehtiyoj frustratsiyasi',
        'O‘zini namoyon qilishdan qo‘rqish',
        'Bilimlarni tekshirish holatidagi xavotir',
        'Atrofdagilar kutuviga mos kelmaslik qo‘rquvi',
        'Fiziologik qarshilik va stress reaksiyasi',
        'O‘qituvchi bilan munosabatdagi qo‘rquv',
      ],
      scoringGuide:
          'Xavotir belgilari yig‘indisi foizda hisoblanadi. 50% dan past — me’yor, 50-75% — yuqori xavotir, 75% dan yuqori — destruktiv zo‘riqish.',
      maxScore: 100.0,
      normCriteria:
          '0-49% ball: Emotsional barqarorlik (Sog‘lom moslashuv)\n50-74% ball: Mo‘tadil yuqori xavotir (Profilaktika talab)\n75-100% ball: Yuqori emotsional zo‘riqish (Psixologik korreksiya)',
    ),
    PsychologicalMethodItem(
      id: 'method_luria',
      code: 'LURIA_10_WORDS',
      title: 'A.R. Luriya "10 ta so‘z" xotira metodikasi',
      author: 'A.R. Luriya',
      targetAge: '6 — 15 yosh',
      domain: 'Xotira jarayonlari',
      durationMinutes: 15,
      purpose:
          'Eshitish orqali qisqa muddatli, tezkor va uzoq muddatli xotira hajmi hamda aqliy faoliyat dinamikasini o‘rganish.',
      instructions:
          'Bir-biri bilan ma’nodosh bo‘lmagan 10 ta oddiy so‘z o‘qib beriladi (5 marta takroran). 1 soatdan so‘ng kechiktirilgan eslash tekshiriladi.',
      subscales: [
        'Birlamchi eslab qolish hajmi (1-urinish)',
        'Eslab qolish egri chizig‘i (O‘sish yoki tebranish)',
        'Maksimal xotira hajmi (5-urinish)',
        'Kechiktirilgan uzoq muddatli xotira (1 soatdan so‘ng)',
      ],
      scoringGuide:
          'Har bir to‘g‘ri eslangan so‘z 1 ball. 5-urinishda 9-10 ta so‘z eslanishi me’yor hisoblanadi.',
      maxScore: 10.0,
      normCriteria:
          '9-10 so‘z: Yuqori xotira hajmi\n7-8 so‘z: Yosh me’yoriga mos\n5-6 so‘z: O‘rtadan past xotira\n4 tadan kam: Neyropsixologik tekshiruv tavsiya etiladi',
    ),
    PsychologicalMethodItem(
      id: 'method_wechsler',
      code: 'WISC_COGNITIVE',
      title: 'D. Veksler bolalar intellekt shkalasi (Kognitiv subtestlar)',
      author: 'David Wechsler',
      targetAge: '6 — 16 yosh',
      domain: 'Kognitiv va intellekt',
      durationMinutes: 30,
      purpose:
          'Verbal va noverbal intellekt, so‘z boyligi, tushunish, raqamlar ketma-ketligi va shifrlash qobiliyatlarini kompleks tahlil qilish.',
      instructions:
          'Standardlashtirilgan 4 ta asosiy subtest: "O‘xshashlikni topish", "So‘z boyligi", "Kox kubiklari bilan shakl yasash" va "Shifrlash".',
      subscales: [
        'Verbal tushunchalar va mavhum tafakkur',
        'Fazoviy konstruktiv analiz va sintez (Kox kubiklari)',
        'Tezkor diqqat va vizual-motor koordinatsiya',
        'Analitik umumlashtirish',
      ],
      scoringGuide:
          'Har bir subtest ballari standart shkalaga o‘tkaziladi (Jami 100 ballik standart indeks).',
      maxScore: 100.0,
      normCriteria:
          'Natijalarni faqat litsenziyalangan qo‘llanmadagi me’yorlar bo‘yicha talqin qiling. Ilova me’yor jadvallarini saqlamaydi va bolaga daraja yorlig‘i qo‘ymaydi.',
      requiresLicensedMaterials: true,
      licenseNote: 'Veksler shkalasi tijoriy litsenziyalangan test (Pearson).',
    ),
    PsychologicalMethodItem(
      id: 'method_yasyukova',
      code: 'YASYUKOVA_PRIMARY',
      title: 'L.A. Yasyukova kognitiv diagnostika majmuasi',
      author: 'L.A. Yasyukova',
      targetAge: '6 — 10 yosh',
      domain: 'Kognitiv va intellekt',
      durationMinutes: 25,
      purpose:
          'Boshlang‘ich sinf o‘quvchilarida maktabga kognitiv tayyorgarlik, intellektual komponentlar va o‘quv ko‘nikmalarini o‘rganish.',
      instructions:
          'Vizual va matnli topshiriqlar majmui: mantiqiy qatorlar, intellektual sintez, nutqiy umumlashtirish.',
      subscales: [
        'Intuitive vizual tafakkur',
        'Nutqiy mantiqiy tafakkur',
        'Vizual motor koordinatsiya (Tura testi)',
        'Qoidalarga amal qilish qobiliyati',
      ],
      scoringGuide:
          'Topshiriqlar to‘g‘riligi bo‘yicha ballar jamlanadi (Maksimal 50 ball).',
      maxScore: 50.0,
      normCriteria:
          'Natijalarni faqat litsenziyalangan qo‘llanmadagi me’yorlar bo‘yicha talqin qiling. Ilova me’yor jadvallarini saqlamaydi va bolaga daraja yorlig‘i qo‘ymaydi.',
      requiresLicensedMaterials: true,
      licenseNote:
          'L.A. Yasyukova metodikasi mualliflik huquqi bilan himoyalangan nashr.',
    ),
    PsychologicalMethodItem(
      id: 'method_cattell',
      code: 'CATTELL_CPQ',
      title: 'J. Kettel bolalar shaxsiy xususiyatlari so‘rovnomasi (CPQ)',
      author: 'R.B. Cattell',
      targetAge: '8 — 12 yosh',
      domain: 'Shaxsiyat va moslashuv',
      durationMinutes: 25,
      purpose:
          'Bolaning shaxsiy individual-psixologik xususiyatlari, muloqotga moyilligi, hissiy barqarorligi va intizomini 12 omil bo‘yicha o‘rganish.',
      instructions:
          'Psixolog nazoratida o‘quvchiga 12 omil bo‘yicha soddalashtirilgan situatsion savollar beriladi.',
      subscales: [
        'A omili — Ochiqlik va muloqotchanlik',
        'C omili — Hissiy barqarorlik',
        'D omili — Hissiy qo‘zg‘aluvchanlik',
        'G omili — Qoidalarga rioya qilish mas’uliyati',
        'H omili — Jasurlik va ijtimoiy dadillik',
        'O omili — Xavotirga moyillik va o‘ziga ishonchsizlik',
      ],
      scoringGuide:
          'Omillar bo‘yicha xom ballar stengacha o‘tkaziladi (1 dan 10 gacha sten shkalasi).',
      maxScore: 10.0,
      normCriteria:
          'Natijalarni faqat litsenziyalangan qo‘llanmadagi me’yorlar bo‘yicha talqin qiling. Ilova me’yor jadvallarini saqlamaydi va bolaga daraja yorlig‘i qo‘ymaydi.',
      requiresLicensedMaterials: true,
      licenseNote:
          'CPQ so‘rovnomasi va me’yorlari mualliflik huquqi bilan himoyalangan.',
    ),
    PsychologicalMethodItem(
      id: 'method_htp',
      code: 'PROJECTIVE_HTP',
      title: '"Uy, daraxt, odam" (HTP) va "Mening oilam" proyektiv testlari',
      author: 'J. Buck',
      targetAge: '5 — 16 yosh',
      domain: 'Emotsional va xavotir',
      durationMinutes: 20,
      purpose:
          'Bolaning ichki kechinmalari, oilaviy munosabatlardagi o‘rni, yashirin xavotirlari, agressiya va o‘zini anglashini proyektiv chizmalar orqali tahlil qilish.',
      instructions:
          'Bolaga A4 qog‘oz va rangli qalamlar berilib, "Uy, daraxt va odam"ni xohlaganicha chizish so‘raladi. Jarayon davomida ketma-ketlik va xatti-harakat kuzatiladi.',
      subscales: [
        'Chiziqlar bosimi va chizish sur’ati (Energetik salohiyat)',
        'Varaqdagi joylashuv (O‘tmish, kelajak, fantaziya yoki haqiqat)',
        'Elementlar nisbati va o‘lchami (O‘zini baholash)',
        'Ranglar gammasi va hissiy fon',
        'Chizilgan obrazlar mazmuni va suhbat tahlili',
      ],
      scoringGuide:
          'Sifatli psixologik tahlil bayonnomasi tuziladi. Hissiy xavfsizlik va moslashuv indeksi (Maksimal 10 ball).',
      maxScore: 10.0,
      normCriteria:
          '8-10 ball: Barqaror hissiy fon va qulay oilaviy muhit\n5-7 ball: O‘rtacha ichki ziddiyatlar, kuzatuv talab\n1-4 ball: Ichki ruhiy zo‘riqish, oilaviy maslahat zarur',
    ),
  ];
}
