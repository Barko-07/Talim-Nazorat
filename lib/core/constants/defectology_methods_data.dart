import 'psychological_methods_data.dart';

/// Defektolog metodikalari kutubxonasi. Tanlangan metodikalar ommaviy foydalanishdagi
/// (mualliflik muddati o'tgan) yoki umumiy defektologik amaliyotdagi topshiriqlar —
/// litsenziya talab qilinmaydi. Natija bolaning o'z oldingi natijasi bilan solishtiriladi;
/// ilova bolaga daraja yorlig'i qo'ymaydi.
class DefectologyMethodsData {
  static const _sensorMotor = 'Sensor-motor rivojlanish';
  static const _cognitive = 'Kognitiv va intellekt';

  static const List<PsychologicalMethodItem> methods = [
    PsychologicalMethodItem(
      id: 'method_seguin_board',
      code: 'SEGUIN_BOARD',
      title: 'Segen doskasi (shakllar taxtasi)',
      author: 'E. Segen (XIX asr) — ommaviy foydalanishdagi metodika',
      targetAge: '3 — 8 yosh (rivojlanish darajasi bo‘yicha)',
      domain: _sensorMotor,
      durationMinutes: 10,
      purpose:
          'Shaklni ko‘rib idrok qilish, ko‘z va qo‘l harakatlari muvofiqligi hamda topshiriqni bajarish usulini (sinab ko‘rish yoki ko‘z bilan tanlash) o‘rganish.',
      instructions:
          'Shakllar taxtadan olinib, bola oldiga aralash qo‘yiladi. Bolaga shakllarni o‘z joyiga qo‘yish taklif etiladi (ko‘rsatma imo-ishora yoki namuna bilan ham beriladi). '
          'Topshiriq 3 marta takrorlanadi. Har urinishda vaqt, xatolar soni va bajarish usuli qayd etiladi.',
      subscales: [
        'Bajarish vaqti (har bir urinish)',
        'Xato joylashtirishlar soni',
        'Bajarish usuli: tasodifiy / sinab ko‘rish / ko‘z bilan tanlash',
        'O‘rganuvchanlik: 3-urinishda yaxshilanish',
      ],
      scoringGuide:
          'Bajarish usuli: tasodifiy harakat — 0, sinab ko‘rish — 1, aralash — 2, ko‘z bilan tanlash — 3 ball. '
          'Xatolar: 3 tadan ko‘p — 0, 2–3 — 1, 1 — 2, xatosiz — 3 ball. '
          'O‘rganuvchanlik: yaxshilanish yo‘q — 0, qisman — 1, aniq — 2 ball. Mustaqillik: yordam bilan — 0, mustaqil — 1 ball.',
      maxScore: 9.0,
      normCriteria:
          'Natija bolaning o‘z oldingi natijasi bilan solishtiriladi. Vaqtning qisqarishi, xatolarning kamayishi va '
          'ko‘z bilan tanlashga o‘tish — ijobiy o‘zgarish. Bajarish vaqtini "O‘lchovlar" bo‘limiga ham kiriting.',
      profession: MethodProfession.defectology,
    ),
    PsychologicalMethodItem(
      id: 'method_kohs_blocks',
      code: 'KOHS_BLOCKS',
      title: 'Koos kubiklari (naqsh tuzish)',
      author: 'S. Koos (1923) — ommaviy foydalanishdagi metodika',
      targetAge: '5 — 14 yosh (rivojlanish darajasi bo‘yicha)',
      domain: _cognitive,
      durationMinutes: 20,
      purpose:
          'Fazoviy tahlil va sintez, konstruktiv fikrlash hamda harakatni rejalashtirish qobiliyatini o‘rganish.',
      instructions:
          'Bolaga rangli kubiklar va murakkabligi oshib boruvchi naqsh kartochkalari beriladi. Bola kubiklardan namunadagi naqshni tuzadi. '
          'Har bir naqsh uchun vaqt, to‘g‘riligi va berilgan yordam darajasi qayd etiladi. Ketma-ket 2 ta naqsh yordam bilan ham bajarilmasa, topshiriq to‘xtatiladi.',
      subscales: [
        'Tuzilgan naqshlar soni',
        'Har bir naqsh uchun vaqt',
        'Yordam darajasi: mustaqil / yo‘naltiruvchi ko‘rsatma / namuna bo‘yicha birga',
        'Ishlash uslubi: rejali / sinab ko‘rish',
      ],
      scoringGuide:
          'Har bir naqsh: mustaqil va to‘g‘ri — 2 ball, yo‘naltiruvchi ko‘rsatma bilan — 1 ball, bajarilmadi yoki to‘liq yordam — 0 ball. 8 ta naqsh.',
      maxScore: 16.0,
      normCriteria:
          'Natija bolaning o‘z oldingi natijasi bilan solishtiriladi. Mustaqil tuzilgan naqshlar sonining ortishi va yordam darajasining kamayishi — ijobiy o‘zgarish. '
          'Qayta tekshiruvda o‘sha naqshlar to‘plamidan foydalaning.',
      profession: MethodProfession.defectology,
    ),
    PsychologicalMethodItem(
      id: 'method_cut_pictures',
      code: 'CUT_PICTURES',
      title: 'Kesilgan rasmlarni yig‘ish',
      author: 'Umumiy defektologik amaliyot',
      targetAge: '3 — 10 yosh (rivojlanish darajasi bo‘yicha)',
      domain: _cognitive,
      durationMinutes: 10,
      purpose:
          'Ko‘rish orqali idrok qilish, butunni qismlardan tiklash (vizual sintez) va harakatlarni rejalashtirishni o‘rganish.',
      instructions:
          'Tanish predmet rasmi teng bo‘lmagan qismlarga kesiladi: 2 bo‘lak (to‘g‘ri), 3 bo‘lak, 4 bo‘lak (to‘g‘ri), 4 bo‘lak (diagonal), 6 bo‘lak. '
          'Bolaga rasm butun holida ko‘rsatilmaydi; avval nima ekanligi aytiladi. Qiyinlik bosqichma-bosqich oshiriladi. Qiynalsa — butun rasm namuna sifatida ko‘rsatiladi.',
      subscales: [
        'Yig‘ilgan eng murakkab variant (bo‘laklar soni)',
        'Namuna kerak bo‘ldimi',
        'Bajarish usuli: tasodifiy / sinab ko‘rish / rejali',
      ],
      scoringGuide:
          'Har bir variant: mustaqil — 2 ball, namuna bilan — 1 ball, bajarilmadi — 0 ball. 5 ta variant.',
      maxScore: 10.0,
      normCriteria:
          'Natija bolaning o‘z oldingi natijasi bilan solishtiriladi. Murakkabroq variantni mustaqil yig‘ishga o‘tish — ijobiy o‘zgarish.',
      profession: MethodProfession.defectology,
    ),
    PsychologicalMethodItem(
      id: 'method_ozeretsky_motor',
      code: 'OZERETSKY_MOTOR',
      title: 'Harakat koordinatsiyasi sinovlari (N.I. Ozeretskiy asosida)',
      author: 'N.I. Ozeretskiy (1923) — ommaviy foydalanishdagi metodika asosida soddalashtirilgan',
      targetAge: '4 — 16 yosh',
      domain: _sensorMotor,
      durationMinutes: 15,
      purpose:
          'Statik muvozanat, dinamik koordinatsiya, harakat tezligi va ikki qo‘lning bir vaqtdagi harakatlarini o‘rganish.',
      instructions:
          '6 ta topshiriq: (1) ko‘zni yumib bir oyoqda turish, (2) chiziq bo‘ylab yurish, (3) bir oyoqda sakrash, '
          '(4) 15 soniyada tangalarni qutiga terish, (5) barmoqlar bilan navbatma-navbat stolni urish, (6) bir vaqtda ikki qo‘l bilan doira chizish. '
          'Harakati cheklangan bolada bajarib bo‘lmaydigan topshiriq o‘tkazib yuboriladi va qayd etiladi.',
      subscales: [
        'Statik muvozanat',
        'Dinamik koordinatsiya',
        'Mayda harakatlar tezligi',
        'Ikki qo‘l harakatlari muvofiqligi',
      ],
      scoringGuide:
          'Har bir topshiriq: bajarildi — 2 ball, qisman yoki qiyinchilik bilan — 1 ball, bajarilmadi — 0 ball. '
          'O‘tkazib yuborilgan topshiriq hisobga olinmaydi (maksimal ball shunga mos kamayadi).',
      maxScore: 12.0,
      normCriteria:
          'Natija bolaning o‘z oldingi natijasi bilan solishtiriladi. Asl metodikaning yosh jadvallari ilovada saqlanmaydi.',
      profession: MethodProfession.defectology,
    ),
    PsychologicalMethodItem(
      id: 'method_classification',
      code: 'OBJECT_CLASSIFICATION',
      title: 'Predmetlarni guruhlash (tasniflash)',
      author: 'Umumiy defektologik amaliyot',
      targetAge: '4 — 12 yosh (rivojlanish darajasi bo‘yicha)',
      domain: _cognitive,
      durationMinutes: 15,
      purpose:
          'Umumlashtirish, muhim belgini ajratish va tushunchalar bo‘yicha fikrlashni o‘rganish.',
      instructions:
          '16–20 ta predmet rasmi (oziq-ovqat, kiyim, hayvonlar, transport) aralash beriladi. Bolaga "mos keladiganlarini birga qo‘y" deyiladi. '
          'Guruhlash tugagach, har bir guruhni nomlash so‘raladi (nutqi cheklangan bolada umumlashtiruvchi rasm kartochkasi tanlanadi).',
      subscales: [
        'Guruhlash asosi: tashqi belgi (rang, shakl) / vaziyat / tushuncha',
        'To‘g‘ri tuzilgan guruhlar soni',
        'Umumlashtiruvchi so‘z yoki kartochkani tanlash',
      ],
      scoringGuide:
          'Asos: tashqi belgi — 1, vaziyat bo‘yicha — 2, tushuncha bo‘yicha — 3 ball. Har bir to‘g‘ri guruh — 1 ball (4 ta). '
          'Umumlashtiruvchi nom: yo‘q — 0, yordam bilan — 1, mustaqil — 2 ball.',
      maxScore: 9.0,
      normCriteria:
          'Natija bolaning o‘z oldingi natijasi bilan solishtiriladi. Tashqi belgidan tushuncha bo‘yicha guruhlashga o‘tish — ijobiy o‘zgarish.',
      profession: MethodProfession.defectology,
    ),
    PsychologicalMethodItem(
      id: 'method_self_care_scale',
      code: 'SELF_CARE_SCALE',
      title: 'Hayotiy ko‘nikmalar va o‘z-o‘ziga xizmat kuzatuv shkalasi',
      author: 'Umumiy defektologik amaliyot',
      targetAge: 'Barcha yoshlar',
      domain: _sensorMotor,
      durationMinutes: 20,
      purpose:
          'Kundalik hayotda mustaqillik darajasini aniqlash va keyingi o‘rgatiladigan ko‘nikmani belgilash.',
      instructions:
          '10 ta ko‘nikma kuzatuv, ota-ona va o‘qituvchi ma’lumoti asosida baholanadi: kiyinish, tugma qadash, poyabzal kiyish, '
          'qo‘l yuvish, qoshiq bilan ovqatlanish, hojatxonadan foydalanish, narsalarini yig‘ishtirish, sumkasini tayyorlash, '
          'kunlik tartibga amal qilish, xavfsizlik qoidalarini bilish (yo‘l, issiq narsalar).',
      subscales: [
        'Kiyinish va o‘z tashqi ko‘rinishiga qarash',
        'Ovqatlanish va gigiyena',
        'Tartib va o‘z narsalari bilan ishlash',
        'Xavfsizlik va kundalik tartib',
      ],
      scoringGuide:
          'Har bir ko‘nikma: to‘liq yordam kerak — 0, qisman yordam yoki eslatma bilan — 1, mustaqil — 2 ball. 10 ta ko‘nikma.',
      maxScore: 20.0,
      normCriteria:
          'Natija bolaning o‘z oldingi natijasi bilan solishtiriladi. Mustaqil bajarilgan ko‘nikmalar sonini '
          '"O‘z-o‘ziga xizmat" ko‘rsatkichiga kiriting — dinamika va yutuqlar pasporti shu orqali yangilanadi.',
      profession: MethodProfession.defectology,
    ),
  ];
}
