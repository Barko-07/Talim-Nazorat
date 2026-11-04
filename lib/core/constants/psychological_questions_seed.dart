import '../../models/assessment_question_model.dart';
import '../../models/development_profile_model.dart';

class PsychologicalQuestionsSeed {
  static List<AssessmentQuestionModel> get standardQuestions =>
      initialQuestions;
  static List<AssessmentQuestionModel> get initialQuestions => [
    // ==================== KOGNITIV VA INTELLEKT ====================
    AssessmentQuestionModel(
      id: 'q_kog_01',
      title: 'Umumlashtirish va tushunchalar',
      text:
          'O‘quvchi taqdim etilgan 4 ta jism yoki tushunchadan mantiqan ortiqchasini ajrata oladimi? (Masalan: olma, nok, shaftoli, sabzi)',
      domain: 'Kognitiv va intellekt',
      targetAgeRange: '7–10 yosh (1-4 sinf)',
      minGrade: 1,
      maxGrade: 4,
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'opt_1',
          text: 'To‘liq mustaqil va sababini tushuntirib ajratadi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'opt_2',
          text: 'Yo‘naltiruvchi savollar yordamida to‘g‘ri topadi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'opt_3',
          text: 'Faqat tashqi belgilari (rangi, shakli) bo‘yicha adashadi',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'opt_4',
          text: 'Topshiriq mohiyatini tushunmaydi',
          score: 0.0,
        ),
      ],
      scoringCriteria: 'Har bir daraja uchun 0 dan 3 gacha ball beriladi.',
      psychologistNotes:
          'Kognitiv analiz va sintez qobiliyatini aniqlash. Boladan nega aynan shu ortiqcha ekanligini so‘rang.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2024, 9, 1),
      requirements: {QuestionRequirement.vision, QuestionRequirement.speech},
      adaptationHint:
          'Rasmli kartochkalar bilan; bola ortiqchasini ko‘rsatib beradi, og‘zaki tushuntirish talab qilinmaydi.',
    ),
    AssessmentQuestionModel(
      id: 'q_kog_02',
      title: 'Mantiqiy ketma-ketlik',
      text:
          'Voqealar ketma-ketligi aks etgan 4 ta syujetli rasmni mantiqiy tartibda to‘g‘ri joylashtiradimi?',
      domain: 'Kognitiv va intellekt',
      targetAgeRange: '7–11 yosh (1-5 sinf)',
      minGrade: 1,
      maxGrade: 4,
      questionType: 'yes_no',
      options: [
        AssessmentQuestionOption(
          id: 'yes',
          text: 'Ha (To‘g‘ri va ketma-ket hikoya qilib beradi)',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'no',
          text: 'Yo‘q (Tartib buzilgan yoki sabab-oqibatni tushunmaydi)',
          score: 0.0,
        ),
      ],
      scoringCriteria: 'Ha = 2 ball, Yo‘q = 0 ball.',
      psychologistNotes:
          'Sabab-oqibat bog‘lanishlarini tushunish va vaqt tushunchasini tekshirish.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2024, 9, 1),
      requirements: {QuestionRequirement.vision, QuestionRequirement.handMotor},
      adaptationHint:
          'Kartochkalarni psixolog joylashtiradi, bola tartibni ko‘rsatish orqali belgilaydi.',
    ),
    AssessmentQuestionModel(
      id: 'q_kog_03',
      title: 'Fazoviy tasavvur va yo‘nalish',
      text:
          'O‘quvchining o‘ng-chap, yuqori-past va koordinata fazoviy yo‘nalishlarni anglash darajasi:',
      domain: 'Kognitiv va intellekt',
      targetAgeRange: 'Barcha yoshlar',
      questionType: 'scale_1_5',
      options: [
        AssessmentQuestionOption(
          id: 'sc_1',
          text: '1 - Fazoviy oriyentatsiya mutlaqo shakllanmagan',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'sc_2',
          text: '2 - Doimiy adashadi, faqat o‘z tanasida qisman biladi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'sc_3',
          text: '3 - O‘rtacha, qog‘ozda adashadi, amalda to‘g‘ri bajaradi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'sc_4',
          text: '4 - Yaxshi, faqat murakkab topshiriqda o‘ylanadi',
          score: 4.0,
        ),
        AssessmentQuestionOption(
          id: 'sc_5',
          text: '5 - Yuqori, fazoviy tasavvuri to‘liq barqaror',
          score: 5.0,
        ),
      ],
      scoringCriteria: '1 dan 5 gacha shkala ko‘rsatkichi.',
      psychologistNotes:
          'Grafik diktant yoki qog‘oz varag‘ida yo‘nalish topshiriqlari bilan sinov o‘tkaziladi.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2024, 9, 1),
      requirements: {
        QuestionRequirement.vision,
        QuestionRequirement.hearing,
        QuestionRequirement.handMotor,
      },
      adaptationHint:
          'Grafik diktant o‘rniga ko‘rsatish bilan bajariladigan topshiriq; ko‘rsatmalar vizual yoki imo-ishorada beriladi.',
    ),

    // ==================== DIQQAT VA XOTIRA ====================
    AssessmentQuestionModel(
      id: 'q_diq_01',
      title: 'Diqqat barqarorligi va chalg‘uvchanlik',
      text:
          'Bir xil faoliyat (masalan, matn yoki shakllarni ko‘chirish) bilan shug‘ullanganda necha daqiqa chalg‘imasdan ishlay oladi?',
      domain: 'Diqqat va xotira',
      targetAgeRange: '7–12 yosh',
      minGrade: 1,
      maxGrade: 4,
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'opt_d1',
          text: '15 daqiqadan ko‘proq (Yosh me’yoridan yuqori)',
          score: 4.0,
        ),
        AssessmentQuestionOption(
          id: 'opt_d2',
          text: '10–15 daqiqa (Me’yoriy daraja)',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'opt_d3',
          text: '5–10 daqiqa (Qisman beqaror, tez toliqadi)',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'opt_d4',
          text: '3 daqiqadan kam (Yuqori chalg‘uvchanlik va beqarorlik)',
          score: 1.0,
        ),
      ],
      scoringCriteria: '0 dan 4 ballgacha unumdorlik darajasi.',
      psychologistNotes:
          'Landolt yoki Shulte jadvali orqali o‘lchanishi tavsiya etiladi.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2024, 9, 2),
      requirements: {QuestionRequirement.vision, QuestionRequirement.handMotor},
      adaptationHint:
          'Ko‘chirish o‘rniga saralash yoki ko‘rsatish bilan bajariladigan bir xil topshiriqda vaqtni o‘lchang.',
    ),
    AssessmentQuestionModel(
      id: 'q_diq_02',
      title: 'Eshitish-nutqiy tezkor xotira hajmi',
      text:
          'Ketma-ket aytilgan 10 ta oddiy so‘zdan birinchi eshitishda nechtasini bexato takrorlay oladi?',
      domain: 'Diqqat va xotira',
      targetAgeRange: 'Barcha yoshlar',
      questionType: 'scale_1_5',
      options: [
        AssessmentQuestionOption(
          id: 'sc_x1',
          text: '1 - 2 tadan kam so‘z (Og‘ir darajadagi xotira sustligi)',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'sc_x2',
          text: '2 - 3–4 ta so‘z (Sust birlamchi eslab qolish)',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'sc_x3',
          text: '3 - 5–6 ta so‘z (O‘rtacha yosh me’yori)',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'sc_x4',
          text: '4 - 7–8 ta so‘z (Yaxshi xotira hajmi)',
          score: 4.0,
        ),
        AssessmentQuestionOption(
          id: 'sc_x5',
          text: '5 - 9–10 ta so‘z (Yuqori ko‘rsatkich)',
          score: 5.0,
        ),
      ],
      scoringCriteria: 'Luriya 10 so‘z shkalasi bo‘yicha 1 dan 5 gacha ball.',
      psychologistNotes:
          'Bir-biriga ma’nodosh bo‘lmagan 1 bo‘g‘inli so‘zlarni taqdim eting.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2024, 9, 2),
      requirements: {QuestionRequirement.hearing, QuestionRequirement.speech},
    ),
    AssessmentQuestionModel(
      id: 'q_diq_03',
      title: 'Vizual xotira va detallarga e’tibor',
      text:
          'O‘quvchiga 10 soniya ko‘rsatilgan rasmdagi asosiy o‘zgarish yoki yo‘qolgan detallarni topish qobiliyati:',
      domain: 'Diqqat va xotira',
      targetAgeRange: '7–12 yosh',
      minGrade: 1,
      maxGrade: 4,
      questionType: 'multiple_choice',
      options: [
        AssessmentQuestionOption(
          id: 'm1',
          text: 'Ranglardagi o‘zgarishlarni darhol payqaydi',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'm2',
          text: 'Shakllar va ob’ektlar joylashuvini eslaydi',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'm3',
          text: 'Mayda ikkilamchi detallarni e’tibordan qochiradi',
          score: 0.0,
        ),
        AssessmentQuestionOption(
          id: 'm4',
          text: 'Xotirada uzoq vaqt saqlay oladi va tasvirlaydi',
          score: 1.0,
        ),
      ],
      scoringCriteria: 'Har bir ijobiy belgi uchun 1 ball.',
      psychologistNotes:
          'Kuzatish davomida bolaning qayerga ko‘proq nigoh qaratganini qayd eting.',
      authorId: 'user_psychologist',
      authorName: 'Usmonova Dilnoza Anvarovna',
      isStandard: false,
      status: 'ready',
      createdAt: DateTime(2024, 9, 10),
      requirements: {QuestionRequirement.vision},
    ),

    // ==================== EMOTSIONAL VA XAVOTIR ====================
    AssessmentQuestionModel(
      id: 'q_emo_01',
      title: 'Baholanish va xatodan qo‘rquv',
      text:
          'Darsda doskaga chiqqanda yoki tekshiruv topshirig‘i berilganda bolada qanday xavotir alomatlari kuzatiladi?',
      domain: 'Emotsional va xavotir',
      targetAgeRange: 'Barcha yoshlar',
      questionType: 'multiple_choice',
      options: [
        AssessmentQuestionOption(
          id: 'opt_e1',
          text: 'Qo‘llarda qaltirash, qizarish yoki fiziologik zo‘riqish',
          score: 0.0,
        ),
        AssessmentQuestionOption(
          id: 'opt_e2',
          text: 'Ovoz pasayishi va gapirishdan bosh tortish',
          score: 0.0,
        ),
        AssessmentQuestionOption(
          id: 'opt_e3',
          text: 'Javob berishdan oldin ko‘p ikkilanish va ma’qullash kutish',
          score: 0.0,
        ),
        AssessmentQuestionOption(
          id: 'opt_e4',
          text: 'Vaziyatga xotirjam va ishonch bilan yondashadi',
          score: 3.0,
        ),
      ],
      scoringCriteria:
          'Belgilar yo‘qligi va xotirjamlik 3 ball. Xavotir belgilari qayd etiladi.',
      psychologistNotes:
          'Filipps maktab xavotiri metodikasi bilan muvofiqlashtirilgan.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2024, 9, 3),
      requirements: <QuestionRequirement>{},
    ),
    AssessmentQuestionModel(
      id: 'q_emo_02',
      title: 'Frustratsiya va qiyinchilikka chidamlilik',
      text:
          'Topshiriq o‘xshamaganda yoki qiyinchilikka uchraganda bola qanday munosabat bildiradi?',
      domain: 'Emotsional va xavotir',
      targetAgeRange: 'Barcha yoshlar',
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'f1',
          text: 'Irodani jamlab, qaytadan urinib ko‘radi (Konstruktiv)',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'f2',
          text: 'Kattalardan yoki do‘stlaridan yordam so‘raydi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'f3',
          text: 'Tez taslim bo‘ladi va daftarni yopib qo‘yadi (Passiv)',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'f4',
          text: 'G‘azablanadi, yig‘laydi yoki o‘quv qurollarini uloqtiradi',
          score: 0.0,
        ),
      ],
      scoringCriteria: 'Konstruktiv reaksiyalar yuqori ball bilan baholanadi.',
      psychologistNotes:
          'Hissiy barqarorlik va o‘z-o‘zini regulyatsiya qilish ko‘rsatkichi.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2024, 9, 3),
      requirements: <QuestionRequirement>{},
    ),
    AssessmentQuestionModel(
      id: 'q_emo_03',
      title: 'Kayfiyat foni va hissiy kuzatuv',
      text:
          'Suhbat davomida bolaning yuz ifodasi, umumiy hissiy foni va kontaktga kirishish darajasini tasvirlang:',
      domain: 'Emotsional va xavotir',
      targetAgeRange: 'Barcha yoshlar',
      questionType: 'open_text',
      options: [],
      scoringCriteria: 'Sifatli psixologik xulosa sifatida tahlil qilinadi.',
      psychologistNotes:
          'Ko‘z kontakti, tabassum, mimika va qiziqish bor-yo‘qligini batafsil yozing.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2024, 9, 3),
      requirements: <QuestionRequirement>{},
    ),

    // ==================== IJTIMOIY MOSLASHUV VA MOTIVATSIYA ====================
    AssessmentQuestionModel(
      id: 'q_ijt_01',
      title: 'Tengdoshlar bilan o‘yinda qoidalarga amal qilish',
      text:
          'Guruhli o‘yin yoki jamoaviy topshiriqda belgilangan qoidalarga rioya qiladimi va navbatini kuta oladimi?',
      domain: 'Ijtimoiy moslashuv va motivatsiya',
      targetAgeRange: '6–11 yosh',
      minGrade: 0,
      maxGrade: 4,
      questionType: 'yes_no',
      options: [
        AssessmentQuestionOption(
          id: 'y',
          text: 'Ha (Qoidani tushunadi va navbat kutadi)',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'n',
          text: 'Yo‘q (Qoidani buzadi yoki navbatsiz harakat qiladi)',
          score: 0.0,
        ),
      ],
      scoringCriteria: 'Ha = 2 ball, Yo‘q = 0 ball.',
      psychologistNotes:
          'Ijtimoiy intizom va o‘zaro hamkorlik ko‘nikmasini o‘rganish.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2024, 9, 4),
      requirements: <QuestionRequirement>{},
    ),
    AssessmentQuestionModel(
      id: 'q_ijt_02',
      title: 'O‘quv motivatsiyasi yo‘nalishi',
      text:
          'Bolada maktabga borish va dars qilishning asosiy yetakchi sababi nima?',
      domain: 'Ijtimoiy moslashuv va motivatsiya',
      targetAgeRange: '7–12 yosh',
      minGrade: 1,
      maxGrade: 4,
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'm_1',
          text: 'Bilish va yangi narsalarni o‘rganishga qiziqish (Ichki motiv)',
          score: 4.0,
        ),
        AssessmentQuestionOption(
          id: 'm_2',
          text: 'Yaxshi baho olish va maqtov eshitish (Ijtimoiy motiv)',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'm_3',
          text: 'Faqat do‘stlari bilan muloqot va tanaffus uchun (Pozitsion)',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'm_4',
          text: 'Ota-ona yoki o‘qituvchi jazolashidan qo‘rqish (Majburiy)',
          score: 1.0,
        ),
      ],
      scoringCriteria:
          'Ichki bilish motivi eng yuqori 4 ball bilan baholanadi.',
      psychologistNotes:
          'Luskina o‘quv motivatsiyasi metodikasi bilan korrelyatsiya qilinadi.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2024, 9, 4),
      requirements: {QuestionRequirement.hearing, QuestionRequirement.speech},
      adaptationHint:
          'Rasmli tanlov kartochkalari orqali yoki ota-ona va o‘qituvchi bilan suhbat asosida aniqlang.',
    ),
    AssessmentQuestionModel(
      id: 'q_ijt_03',
      title: 'Konfliktli vaziyatlarni hal qilish uslubi',
      text:
          'Tengdoshlari bilan bahsli yoki ziddiyatli holat vujudga kelganda bola qanday yo‘l tutadi?',
      domain: 'Ijtimoiy moslashuv va motivatsiya',
      targetAgeRange: 'Barcha yoshlar',
      questionType: 'open_text',
      options: [],
      scoringCriteria: 'Sifatli kuzatuv yozuvi.',
      psychologistNotes:
          'Kompromiss, chekinish, agressiya yoki o‘qituvchiga murojaat qilish holatini qayd qiling.',
      authorId: 'user_psychologist',
      authorName: 'Usmonova Dilnoza Anvarovna',
      isStandard: false,
      status: 'ready',
      createdAt: DateTime(2024, 9, 15),
      requirements: <QuestionRequirement>{},
    ),

    // ==================== XULQ-ATVOR VA IRODA ====================
    AssessmentQuestionModel(
      id: 'q_xul_01',
      title: 'Kattalarning ko‘rsatmalariga itoatkorlik',
      text:
          'O‘qituvchi yoki psixologning og‘zaki ko‘rsatma va talablarini qanchalik tez qabul qiladi va bajaradi?',
      domain: 'Xulq-atvor va iroda',
      targetAgeRange: 'Barcha yoshlar',
      questionType: 'scale_1_5',
      options: [
        AssessmentQuestionOption(
          id: 'x_1',
          text: '1 - Ko‘rsatmalarga qarshilik ko‘rsatadi (Negativizm)',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'x_2',
          text: '2 - Bir necha bor takrorlangandan so‘ng noiloj bajaradi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'x_3',
          text: '3 - Vaziyatga qarab o‘zgaruvchan',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'x_4',
          text: '4 - Ko‘p hollarda to‘g‘ri qabul qiladi',
          score: 4.0,
        ),
        AssessmentQuestionOption(
          id: 'x_5',
          text:
              '5 - Ko‘rsatmalarni birinchi martada to‘liq va ixtiyoriy bajaradi',
          score: 5.0,
        ),
      ],
      scoringCriteria: '1 dan 5 gacha irodaviy nazorat shkalasi.',
      psychologistNotes:
          'Irodaviy zo‘riqish va xatti-harakatni boshqara olish darajasi.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2024, 9, 5),
      requirements: {QuestionRequirement.hearing},
      adaptationHint:
          'Ko‘rsatmalarni bolaning muloqot usulida (imo-ishora, rasm, surdo tili) bering va shunga ko‘ra baholang.',
    ),
    AssessmentQuestionModel(
      id: 'q_xul_02',
      title: 'Impulsivlik va harakat faolligi',
      text:
          'Dars va mashg‘ulot davomida o‘rinsiz joyidan turib ketish, gap qo‘shish yoki ortiqcha harakatlar kuzatiladimi?',
      domain: 'Xulq-atvor va iroda',
      targetAgeRange: 'Barcha yoshlar',
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'imp_1',
          text: 'Deyarli kuzatilmaydi, o‘zini to‘liq boshqaradi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'imp_2',
          text: 'Faqat darsning ikkinchi yarmida toliqqanda qimirlab qoladi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'imp_3',
          text:
              'Doimiy ravishda harakatda va gapirishni to‘xtatolmaydi (Giperfaollik)',
          score: 1.0,
        ),
      ],
      scoringCriteria: 'Harakat intizomi bo‘yicha 1 dan 3 gacha ball.',
      psychologistNotes:
          'Diqqat yetishmasligi va giperfaollik sindromi (SDVG) belgilarini e’tiborga oling.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2024, 9, 5),
      requirements: <QuestionRequirement>{},
    ),
    // ==================== 5–8-SINFLAR (O'RTA BO'G'IN) ====================
    AssessmentQuestionModel(
      id: 'q_kog_58_01',
      title: 'So‘z analogiyalari',
      text:
          'O‘quvchiga 5 ta analogiya beriladi (masalan: "Kitob — o‘qish, qalam — ?"). Nechtasini to‘g‘ri yakunlaydi?',
      domain: 'Kognitiv va intellekt',
      targetAgeRange: '11–14 yosh (5-8 sinf)',
      minGrade: 5,
      maxGrade: 8,
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'an_1',
          text: '5 tadan 5 tasini mustaqil va asoslab yakunlaydi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'an_2',
          text: '3–4 tasini to‘g‘ri yakunlaydi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'an_3',
          text: '1–2 tasini, yo‘naltiruvchi savollar bilan',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'an_4',
          text: 'Bog‘lanish tamoyilini tushunmaydi',
          score: 0.0,
        ),
      ],
      scoringCriteria:
          'To‘g‘ri yakunlangan analogiyalar soniga qarab 0–3 ball.',
      psychologistNotes:
          'Tushunchalar o‘rtasidagi munosabatni (vazifa, qism–butun, sabab–oqibat) anglashni tekshiradi.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: {QuestionRequirement.vision, QuestionRequirement.reading},
      adaptationHint:
          'Analogiyalarni ovoz chiqarib o‘qib bering yoki rasmli analogiyalardan foydalaning.',
    ),
    AssessmentQuestionModel(
      id: 'q_diq_58_01',
      title: 'Korrektura topshirig‘ida diqqat aniqligi',
      text:
          'Harflar jadvalida berilgan 2 ta harfni 5 daqiqa davomida belgilashda o‘quvchi qancha xato yoki o‘tkazib yuborishga yo‘l qo‘yadi?',
      domain: 'Diqqat va xotira',
      targetAgeRange: '11–14 yosh (5-8 sinf)',
      minGrade: 5,
      maxGrade: 8,
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'kr_1',
          text: '0–2 ta xato, sur’at barqaror',
          score: 3.0,
        ),
        AssessmentQuestionOption(id: 'kr_2', text: '3–6 ta xato', score: 2.0),
        AssessmentQuestionOption(
          id: 'kr_3',
          text: '7–12 ta xato, oxiriga kelib toliqadi',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'kr_4',
          text: '12 tadan ko‘p xato yoki topshiriqni yakunlay olmaydi',
          score: 0.0,
        ),
      ],
      scoringCriteria: 'Xatolar soniga qarab 0–3 ball.',
      psychologistNotes:
          'Bir xil jadvalni qayta baholashda ham ishlating — natijalar solishtiriladi.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: {
        QuestionRequirement.vision,
        QuestionRequirement.handMotor,
        QuestionRequirement.reading,
      },
      adaptationHint:
          'Harflar o‘rniga oddiy shakllardan foydalaning; bola belgilash o‘rniga barmoq bilan ko‘rsatadi.',
    ),
    AssessmentQuestionModel(
      id: 'q_emo_58_01',
      title: 'Nazorat ishi oldidan xavotir',
      text:
          'Nazorat ishi yoki imtihon oldidan o‘quvchi o‘z xavotirini 1 dan 5 gacha qanday baholaydi?',
      domain: 'Emotsional va xavotir',
      targetAgeRange: '11–14 yosh (5-8 sinf)',
      minGrade: 5,
      maxGrade: 8,
      questionType: 'scale_1_5',
      options: [
        AssessmentQuestionOption(
          id: 'nx_1',
          text:
              '1 - Juda kuchli xavotir, topshiriqni bajarishga xalaqit beradi',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'nx_2',
          text: '2 - Kuchli xavotir',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'nx_3',
          text: '3 - O‘rtacha, o‘zini boshqara oladi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'nx_4',
          text: '4 - Yengil hayajon',
          score: 4.0,
        ),
        AssessmentQuestionOption(id: 'nx_5', text: '5 - Xotirjam', score: 5.0),
      ],
      scoringCriteria: '1–5 shkala (yuqori ball — xotirjamroq).',
      psychologistNotes: 'O‘quvchining o‘z bahosi; kuzatuv bilan solishtiring.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: {QuestionRequirement.hearing, QuestionRequirement.speech},
      adaptationHint:
          'Shkalani rasmli shaklda (yuz ifodalari) ko‘rsating; bola mos rasmni ko‘rsatadi.',
    ),
    AssessmentQuestionModel(
      id: 'q_ijt_58_01',
      title: 'Sinfdagi o‘rni va do‘stlik munosabatlari',
      text:
          'O‘quvchining sinfdoshlari orasidagi o‘rni va do‘stlik munosabatlari qanday?',
      domain: 'Ijtimoiy moslashuv va motivatsiya',
      targetAgeRange: '11–14 yosh (5-8 sinf)',
      minGrade: 5,
      maxGrade: 8,
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'sd_1',
          text: 'Barqaror do‘stlari bor, guruh ishida faol',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'sd_2',
          text: '1–2 ta yaqin do‘sti bor, guruhda kam faol',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'sd_3',
          text: 'Ko‘pincha yolg‘iz, tengdoshlar bilan aloqasi kam',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'sd_4',
          text: 'Tengdoshlar bilan aloqadan qochadi yoki chetlashtiriladi',
          score: 0.0,
        ),
      ],
      scoringCriteria: '0–3 ball, kuzatuv va sinf rahbari ma’lumoti asosida.',
      psychologistNotes:
          'Chetlashtirish belgilari bo‘lsa, alohida kuzatuv qaydi yozing.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: <QuestionRequirement>{},
    ),
    AssessmentQuestionModel(
      id: 'q_xul_58_01',
      title: 'Vazifani rejalashtirish va mustaqil boshlash',
      text:
          'O‘quvchi uy vazifasi yoki topshiriqni o‘zi rejalashtirib, eslatmasiz boshlay oladimi?',
      domain: 'Xulq-atvor va iroda',
      targetAgeRange: '11–14 yosh (5-8 sinf)',
      minGrade: 5,
      maxGrade: 8,
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'rj_1',
          text: 'Mustaqil rejalashtiradi va o‘z vaqtida boshlaydi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'rj_2',
          text: 'Bitta eslatmadan keyin boshlaydi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'rj_3',
          text: 'Doimiy nazorat va bosqichma-bosqich yo‘l-yo‘riq kerak',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'rj_4',
          text: 'Kattalar yordamisiz boshlay olmaydi',
          score: 0.0,
        ),
      ],
      scoringCriteria: '0–3 ball.',
      psychologistNotes:
          'Ota-ona va sinf rahbari bilan suhbat orqali aniqlashtiring.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: <QuestionRequirement>{},
    ),

    // ==================== 9–11-SINFLAR (YUQORI BO'G'IN, MURAKKABROQ) ====================
    AssessmentQuestionModel(
      id: 'q_kog_911_01',
      title: 'Mantiqiy xulosa chiqarish',
      text:
          'O‘quvchiga ikki asosdan xulosa chiqarish bo‘yicha 5 ta topshiriq beriladi (masalan: "Barcha metallar elektr o‘tkazadi. Mis — metall. Demak...?"). Natija:',
      domain: 'Kognitiv va intellekt',
      targetAgeRange: '15–17 yosh (9-11 sinf)',
      minGrade: 9,
      maxGrade: 11,
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'mx_1',
          text:
              '5 tasini to‘g‘ri hal qiladi va noto‘g‘ri xulosalarni ham ajratadi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'mx_2',
          text: '3–4 tasini to‘g‘ri hal qiladi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'mx_3',
          text: '1–2 tasini, faqat aniq misollarda',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'mx_4',
          text: 'Asoslar va xulosa o‘rtasidagi bog‘liqlikni tushunmaydi',
          score: 0.0,
        ),
      ],
      scoringCriteria:
          'To‘g‘ri hal qilingan topshiriqlar soniga qarab 0–3 ball.',
      psychologistNotes:
          'Mavhum mantiqiy fikrlashni tekshiradi. Topshiriqlar mazmuni o‘quvchiga tanish bo‘lishi kerak.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: {QuestionRequirement.hearing, QuestionRequirement.speech},
      adaptationHint:
          'Topshiriqlarni yozma shaklda va javob variantlari bilan bering; o‘quvchi to‘g‘ri variantni ko‘rsatadi.',
    ),
    AssessmentQuestionModel(
      id: 'q_kog_911_02',
      title: 'Matndan asosiy fikrni ajratish',
      text:
          'O‘quvchi bir xatboshili ilmiy-ommabop matnni o‘qib, asosiy fikrni o‘z so‘zlari bilan ifodalay oladimi?',
      domain: 'Kognitiv va intellekt',
      targetAgeRange: '15–17 yosh (9-11 sinf)',
      minGrade: 9,
      maxGrade: 11,
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'af_1',
          text: 'Asosiy fikrni aniq ifodalaydi va dalillarni ajratadi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'af_2',
          text: 'Asosiy fikrni topadi, lekin dalillarni ajratmaydi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'af_3',
          text: 'Matnni qisman qayta hikoya qiladi, umumlashtirmaydi',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'af_4',
          text: 'Matn mazmunini tushunmaydi',
          score: 0.0,
        ),
      ],
      scoringCriteria: '0–3 ball.',
      psychologistNotes:
          'Qayta baholashda bir xil murakkablikdagi matndan foydalaning.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: {QuestionRequirement.reading, QuestionRequirement.speech},
      adaptationHint:
          'Matnni ovoz chiqarib o‘qib bering; asosiy fikrni 3–4 variantdan tanlash orqali aniqlang.',
    ),
    AssessmentQuestionModel(
      id: 'q_diq_911_01',
      title: 'Ishchi xotira: teskari tartibda takrorlash',
      text:
          'Ovoz chiqarib aytilgan raqamlar qatorini teskari tartibda nechtagacha bexato takrorlay oladi?',
      domain: 'Diqqat va xotira',
      targetAgeRange: '15–17 yosh (9-11 sinf)',
      minGrade: 9,
      maxGrade: 11,
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'tx_1',
          text: '6 va undan ortiq raqam',
          score: 3.0,
        ),
        AssessmentQuestionOption(id: 'tx_2', text: '4–5 ta raqam', score: 2.0),
        AssessmentQuestionOption(id: 'tx_3', text: '2–3 ta raqam', score: 1.0),
        AssessmentQuestionOption(
          id: 'tx_4',
          text: 'Teskari tartibda takrorlay olmaydi',
          score: 0.0,
        ),
      ],
      scoringCriteria: 'Eng uzun to‘g‘ri qator uzunligiga qarab 0–3 ball.',
      psychologistNotes:
          'Eshitish-nutqiy ishchi xotirani o‘lchaydi; vizual shaklga o‘tkazilsa boshqa ko‘rsatkich o‘lchanadi.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: {QuestionRequirement.hearing, QuestionRequirement.speech},
    ),
    AssessmentQuestionModel(
      id: 'q_diq_911_02',
      title: 'Uzoq vaqt diqqatni ushlab turish',
      text:
          '20 daqiqalik mustaqil yozma yoki amaliy ish davomida o‘quvchi necha marta chalg‘iydi?',
      domain: 'Diqqat va xotira',
      targetAgeRange: '15–17 yosh (9-11 sinf)',
      minGrade: 9,
      maxGrade: 11,
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'ud_1',
          text: 'Chalg‘imaydi yoki 1 marta, o‘zi qaytadi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'ud_2',
          text: '2–3 marta, o‘zi qaytadi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'ud_3',
          text: 'Tez-tez chalg‘iydi, eslatma kerak',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'ud_4',
          text: '5 daqiqadan ortiq ishlay olmaydi',
          score: 0.0,
        ),
      ],
      scoringCriteria: '0–3 ball, kuzatuv asosida.',
      psychologistNotes:
          'Ishni bolaning imkoniyatiga mos shaklda tanlang; o‘lchanadigan narsa — diqqat davomiyligi.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: <QuestionRequirement>{},
    ),
    AssessmentQuestionModel(
      id: 'q_emo_911_01',
      title: 'Imtihon stressi va o‘zini boshqarish',
      text:
          'Bitiruv yoki kirish imtihonlariga tayyorgarlik davrida o‘quvchi stressni qanday boshqaradi?',
      domain: 'Emotsional va xavotir',
      targetAgeRange: '15–17 yosh (9-11 sinf)',
      minGrade: 9,
      maxGrade: 11,
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'is_1',
          text:
              'Stressni anglaydi va o‘ziga yordam berish usullarini qo‘llaydi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'is_2',
          text: 'Stressni anglaydi, lekin kattalar yordami bilan boshqaradi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'is_3',
          text: 'Uyqu, ishtaha yoki o‘qishga ta’sir qiluvchi kuchli stress',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'is_4',
          text: 'Stress tufayli kundalik faoliyatdan to‘xtab qoladi',
          score: 0.0,
        ),
      ],
      scoringCriteria: '0–3 ball, suhbat va kuzatuv asosida.',
      psychologistNotes:
          'Kuchli stress belgilari bo‘lsa, ota-ona bilan suhbat va qo‘llab-quvvatlash rejasini ko‘rib chiqing.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: {QuestionRequirement.hearing, QuestionRequirement.speech},
      adaptationHint:
          'Suhbatni bolaning muloqot usulida o‘tkazing; holatni rasmli shkala orqali aniqlang.',
    ),
    AssessmentQuestionModel(
      id: 'q_emo_911_02',
      title: 'His-tuyg‘ularni anglash va nomlash',
      text:
          'O‘quvchi turli vaziyatlarda o‘z his-tuyg‘ularini qanchalik aniq anglaydi va nomlaydi?',
      domain: 'Emotsional va xavotir',
      targetAgeRange: '15–17 yosh (9-11 sinf)',
      minGrade: 9,
      maxGrade: 11,
      questionType: 'scale_1_5',
      options: [
        AssessmentQuestionOption(
          id: 'ht_1',
          text: '1 - His-tuyg‘ularini farqlamaydi',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'ht_2',
          text: '2 - Faqat "yaxshi / yomon" deb ajratadi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'ht_3',
          text: '3 - Asosiy his-tuyg‘ularni nomlaydi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'ht_4',
          text: '4 - Aralash his-tuyg‘ularni ham nomlaydi',
          score: 4.0,
        ),
        AssessmentQuestionOption(
          id: 'ht_5',
          text: '5 - His-tuyg‘ular sababini tushuntiradi',
          score: 5.0,
        ),
      ],
      scoringCriteria: '1–5 shkala.',
      psychologistNotes:
          'Vaziyatli savollar orqali tekshiring ("Agar do‘sting va’dasini bajarmasa, nimani his qilasan?").',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: {QuestionRequirement.speech},
      adaptationHint:
          'His-tuyg‘ular aks etgan rasmli kartochkalardan foydalaning; bola mosini ko‘rsatadi.',
    ),
    AssessmentQuestionModel(
      id: 'q_ijt_911_01',
      title: 'Kasb tanlash va kelajak rejalari',
      text:
          'O‘quvchida kelajakdagi kasbi yoki ta’limi haqida qanchalik aniq tasavvur bor?',
      domain: 'Ijtimoiy moslashuv va motivatsiya',
      targetAgeRange: '15–17 yosh (9-11 sinf)',
      minGrade: 9,
      maxGrade: 11,
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'kt_1',
          text: 'Aniq maqsadi va unga erishish rejasi bor',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'kt_2',
          text: 'Qiziqish sohasi bor, lekin reja yo‘q',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'kt_3',
          text: 'Tasavvuri noaniq, boshqalar fikriga tayanadi',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'kt_4',
          text: 'Kelajak haqida o‘ylashdan qochadi',
          score: 0.0,
        ),
      ],
      scoringCriteria: '0–3 ball.',
      psychologistNotes:
          'Bolaning imkoniyatlariga mos kasblar haqida ota-ona bilan birga suhbatlashing.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: {QuestionRequirement.hearing, QuestionRequirement.speech},
      adaptationHint:
          'Kasblar aks etgan rasmli kartochkalar bilan; ota-ona suhbati orqali to‘ldiring.',
    ),
    AssessmentQuestionModel(
      id: 'q_ijt_911_02',
      title: 'Mustaqil hayot ko‘nikmalari',
      text:
          'O‘quvchi kundalik hayotda (jamoat transporti, pul bilan hisob-kitob, xarid qilish) qanchalik mustaqil?',
      domain: 'Ijtimoiy moslashuv va motivatsiya',
      targetAgeRange: '15–17 yosh (9-11 sinf)',
      minGrade: 9,
      maxGrade: 11,
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'mh_1',
          text: 'Barchasini mustaqil bajaradi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'mh_2',
          text: 'Tanish vaziyatlarda mustaqil',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'mh_3',
          text: 'Kattalar hamrohligida bajaradi',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'mh_4',
          text: 'Hali mustaqil bajarmaydi',
          score: 0.0,
        ),
      ],
      scoringCriteria: '0–3 ball, ota-ona ma’lumoti va kuzatuv asosida.',
      psychologistNotes:
          'Maqsad qo‘yish uchun foydali: qaysi ko‘nikma keyingi qadam bo‘lishi mumkinligini belgilang.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: <QuestionRequirement>{},
    ),
    AssessmentQuestionModel(
      id: 'q_xul_911_01',
      title: 'Qaror qabul qilish va oqibatni oldindan ko‘rish',
      text:
          'Hayotiy vaziyat taqdim etilganda (masalan, do‘sti darsdan qochishni taklif qiladi) o‘quvchi oqibatlarni hisobga olib qaror qabul qila oladimi?',
      domain: 'Xulq-atvor va iroda',
      targetAgeRange: '15–17 yosh (9-11 sinf)',
      minGrade: 9,
      maxGrade: 11,
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'qq_1',
          text: 'Bir nechta oqibatni ko‘radi va asoslangan qaror qabul qiladi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'qq_2',
          text: 'Asosiy oqibatni ko‘radi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'qq_3',
          text: 'Yo‘naltiruvchi savollardan keyin oqibatni ko‘radi',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'qq_4',
          text: 'Oqibatlarni hisobga olmaydi',
          score: 0.0,
        ),
      ],
      scoringCriteria: '0–3 ball.',
      psychologistNotes:
          'Bir nechta vaziyatdan foydalaning; qayta baholashda o‘sha vaziyatlarni qo‘llang.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: {QuestionRequirement.hearing, QuestionRequirement.speech},
      adaptationHint:
          'Vaziyatni rasmli hikoya shaklida ko‘rsating; javob variantlarini rasm bilan bering.',
    ),
    AssessmentQuestionModel(
      id: 'q_xul_911_02',
      title: 'Mas’uliyat va vazifani muddatida bajarish',
      text:
          'O‘quvchi berilgan vazifalarni muddatida va mustaqil bajarish darajasi:',
      domain: 'Xulq-atvor va iroda',
      targetAgeRange: '15–17 yosh (9-11 sinf)',
      minGrade: 9,
      maxGrade: 11,
      questionType: 'scale_1_5',
      options: [
        AssessmentQuestionOption(
          id: 'ms_1',
          text: '1 - Vazifalarni deyarli bajarmaydi',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'ms_2',
          text: '2 - Doimiy eslatma bilan qisman bajaradi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'ms_3',
          text: '3 - Ko‘pincha bajaradi, ba’zan kechiktiradi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'ms_4',
          text: '4 - Deyarli har doim muddatida',
          score: 4.0,
        ),
        AssessmentQuestionOption(
          id: 'ms_5',
          text: '5 - Mustaqil, rejali va o‘z vaqtida',
          score: 5.0,
        ),
      ],
      scoringCriteria: '1–5 shkala.',
      psychologistNotes:
          'Sinf rahbari va ota-ona ma’lumotlari bilan to‘ldiring.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: <QuestionRequirement>{},
    ),
    // ==================== NUTQ VA MULOQOT (LOGOPED) ====================
    AssessmentQuestionModel(
      id: 'q_nutq_01',
      title: 'Tovushlar talaffuzi',
      text:
          'Bola so‘z boshida, o‘rtasida va oxirida maqsadli tovushlarni (masalan, r, sh, s, l) qanday talaffuz qiladi?',
      domain: 'Nutq va muloqot',
      targetAgeRange: 'Barcha yoshlar',
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'tt_1',
          text: 'Barcha pozitsiyalarda to‘g‘ri talaffuz qiladi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'tt_2',
          text: 'Alohida talaffuz qiladi, nutqda ba’zan buzadi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'tt_3',
          text: 'Tovushni boshqasiga almashtiradi yoki tushirib qoldiradi',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'tt_4',
          text: 'Tovush hali shakllanmagan',
          score: 0.0,
        ),
      ],
      scoringCriteria:
          'Har bir maqsadli tovush uchun alohida baholang, 0–3 ball.',
      psychologistNotes:
          'Natijani "To‘g‘ri talaffuz qilinadigan tovushlar" ko‘rsatkichiga ham kiriting.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: {QuestionRequirement.speech, QuestionRequirement.hearing},
    ),
    AssessmentQuestionModel(
      id: 'q_nutq_02',
      title: 'Fonematik eshitish',
      text:
          'Bola talaffuzi yaqin so‘zlarni (masalan, "qum — qo‘l", "tosh — tush") eshitib farqlay oladimi? 6 juft so‘z bo‘yicha:',
      domain: 'Nutq va muloqot',
      targetAgeRange: 'Barcha yoshlar',
      maxGrade: 4,
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'fe_1',
          text: '6 juftning barchasini farqlaydi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'fe_2',
          text: '4–5 juftni farqlaydi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'fe_3',
          text: '2–3 juftni farqlaydi',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'fe_4',
          text: 'Farqlay olmaydi',
          score: 0.0,
        ),
      ],
      scoringCriteria: 'To‘g‘ri farqlangan juftlar soni bo‘yicha 0–3 ball.',
      psychologistNotes:
          'Bola javobni rasmni ko‘rsatish orqali berishi mumkin — og‘zaki javob shart emas.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: {QuestionRequirement.hearing},
    ),
    AssessmentQuestionModel(
      id: 'q_nutq_03',
      title: 'Faol lug‘at',
      text:
          'Bolaga 20 ta tanish predmet rasmi ko‘rsatiladi. Nechtasini to‘g‘ri nomlaydi?',
      domain: 'Nutq va muloqot',
      targetAgeRange: 'Barcha yoshlar',
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(id: 'fl_1', text: '17–20 ta', score: 3.0),
        AssessmentQuestionOption(id: 'fl_2', text: '11–16 ta', score: 2.0),
        AssessmentQuestionOption(id: 'fl_3', text: '5–10 ta', score: 1.0),
        AssessmentQuestionOption(id: 'fl_4', text: '5 tadan kam', score: 0.0),
      ],
      scoringCriteria: 'Nomlangan rasmlar soni bo‘yicha 0–3 ball.',
      psychologistNotes:
          'Aniq sonni "Faol lug‘at" ko‘rsatkichiga kiriting — dinamika shu orqali kuzatiladi.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: {QuestionRequirement.vision, QuestionRequirement.speech},
      adaptationHint:
          'Og‘zaki nutqi cheklangan bola uchun: psixolog so‘zni aytadi, bola mos rasmni ko‘rsatadi (passiv lug‘at).',
    ),
    AssessmentQuestionModel(
      id: 'q_nutq_04',
      title: 'Bog‘lanishli nutq',
      text:
          'Syujetli rasm (yoki 3 ta ketma-ket rasm) bo‘yicha bola qanday hikoya tuzadi?',
      domain: 'Nutq va muloqot',
      targetAgeRange: 'Barcha yoshlar',
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'bn_1',
          text: 'Mustaqil, mantiqiy va to‘liq gaplar bilan hikoya qiladi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'bn_2',
          text: 'Yo‘naltiruvchi savollar bilan hikoya qiladi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'bn_3',
          text: 'Alohida so‘z yoki qisqa iboralar bilan javob beradi',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'bn_4',
          text: 'Hikoya tuza olmaydi',
          score: 0.0,
        ),
      ],
      scoringCriteria: '0–3 ball.',
      psychologistNotes: 'Grammatik xatolar va gap tuzilishini ham qayd eting.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: {QuestionRequirement.vision, QuestionRequirement.speech},
      adaptationHint:
          'Surdo tili yoki rasmli kartochkalardan foydalanadigan bola hikoyani o‘z muloqot usulida tuzadi.',
    ),

    // ==================== SENSOR-MOTOR RIVOJLANISH (DEFEKTOLOG) ====================
    AssessmentQuestionModel(
      id: 'q_sm_01',
      title: 'Mayda motorika',
      text:
          'Bola mayda predmetlar bilan ishlashda (munchoq terish, tugma qadash, qaychi bilan kesish) qanchalik mustaqil?',
      domain: 'Sensor-motor rivojlanish',
      targetAgeRange: 'Barcha yoshlar',
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'mm_1',
          text: 'Barchasini mustaqil va aniq bajaradi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'mm_2',
          text: 'Sekin, lekin mustaqil bajaradi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'mm_3',
          text: 'Kattalar yordami bilan bajaradi',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'mm_4',
          text: 'Hali bajara olmaydi',
          score: 0.0,
        ),
      ],
      scoringCriteria: '0–3 ball.',
      psychologistNotes:
          'Aniq natijani "Mayda motorika" ko‘rsatkichiga kiriting.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: {QuestionRequirement.handMotor},
    ),
    AssessmentQuestionModel(
      id: 'q_sm_02',
      title: 'Sensor etalonlar: rang, shakl, kattalik',
      text:
          'Bola predmetlarni rangi, shakli va kattaligi bo‘yicha guruhlay oladimi?',
      domain: 'Sensor-motor rivojlanish',
      targetAgeRange: 'Barcha yoshlar',
      maxGrade: 4,
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'se_1',
          text: 'Uchala belgi bo‘yicha mustaqil guruhlaydi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'se_2',
          text: 'Ikki belgi bo‘yicha guruhlaydi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'se_3',
          text: 'Bitta belgi bo‘yicha, namuna bilan',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'se_4',
          text: 'Guruhlay olmaydi',
          score: 0.0,
        ),
      ],
      scoringCriteria: '0–3 ball.',
      psychologistNotes:
          'Ko‘rishi zaif bolada rang o‘rniga tuzilma (silliq/g‘adir-budur) bilan tekshiring.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: {QuestionRequirement.vision},
      adaptationHint:
          'Rang o‘rniga sirt tuzilmasi va og‘irlik bo‘yicha taktil guruhlash.',
    ),
    AssessmentQuestionModel(
      id: 'q_sm_03',
      title: 'Fazoviy mo‘ljal',
      text:
          'Bola o‘z tanasida va atrofdagi predmetlarda yo‘nalishlarni (o‘ng-chap, oldi-orqa, ustida-tagida) ko‘rsata oladimi?',
      domain: 'Sensor-motor rivojlanish',
      targetAgeRange: 'Barcha yoshlar',
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'fm_1',
          text: 'O‘zida va predmetlarda to‘g‘ri ko‘rsatadi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'fm_2',
          text: 'O‘z tanasida to‘g‘ri, predmetlarda adashadi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'fm_3',
          text: 'Faqat ayrim yo‘nalishlarni biladi',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'fm_4',
          text: 'Yo‘nalishlarni farqlamaydi',
          score: 0.0,
        ),
      ],
      scoringCriteria: '0–3 ball.',
      psychologistNotes: 'Ko‘rsatma bolaning muloqot usulida beriladi.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: {QuestionRequirement.hearing},
      adaptationHint:
          'Ko‘rsatmani imo-ishora yoki namuna ko‘rsatish orqali bering.',
    ),
    AssessmentQuestionModel(
      id: 'q_sm_04',
      title: 'O‘z-o‘ziga xizmat ko‘nikmalari',
      text:
          'Bola kundalik o‘z-o‘ziga xizmat amallarini (kiyinish, qo‘l yuvish, ovqatlanish, narsalarini yig‘ish) qanchalik mustaqil bajaradi?',
      domain: 'Sensor-motor rivojlanish',
      targetAgeRange: 'Barcha yoshlar',
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'ox_1',
          text: 'Barchasini mustaqil bajaradi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'ox_2',
          text: 'Ko‘pchiligini mustaqil, ayrimlarini eslatma bilan',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'ox_3',
          text: 'Ko‘pchiligini yordam bilan',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'ox_4',
          text: 'To‘liq yordam kerak',
          score: 0.0,
        ),
      ],
      scoringCriteria: '0–3 ball, kuzatuv va ota-ona ma’lumoti asosida.',
      psychologistNotes:
          'Mustaqil bajarilgan amallar sonini "O‘z-o‘ziga xizmat" ko‘rsatkichiga kiriting.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: <QuestionRequirement>{},
    ),

    // ==================== O'QUV KO'NIKMALARI (MAXSUS TA'LIM O'QITUVCHISI) ====================
    AssessmentQuestionModel(
      id: 'q_oq_01',
      title: 'Topshiriqni mustaqil bajarish',
      text:
          'Darajasiga mos o‘quv topshirig‘ini bola qanchalik mustaqil bajaradi?',
      domain: 'O‘quv ko‘nikmalari',
      targetAgeRange: 'Barcha yoshlar',
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'tm_1',
          text: 'Ko‘rsatmani tushunib, mustaqil bajaradi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'tm_2',
          text: 'Bitta-ikkita yo‘naltiruvchi ko‘rsatma bilan bajaradi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'tm_3',
          text: 'Bosqichma-bosqich yordam bilan bajaradi',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'tm_4',
          text: 'Yordam bilan ham bajara olmaydi',
          score: 0.0,
        ),
      ],
      scoringCriteria: '0–3 ball.',
      psychologistNotes:
          'Topshiriq bolaning fan bo‘yicha haqiqiy darajasiga mos bo‘lishi kerak, sinfiga emas.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: <QuestionRequirement>{},
    ),
    AssessmentQuestionModel(
      id: 'q_oq_02',
      title: 'O‘qish texnikasi',
      text: 'Bola darajasiga mos matnni qanday o‘qiydi?',
      domain: 'O‘quv ko‘nikmalari',
      targetAgeRange: 'Barcha yoshlar',
      minGrade: 1,
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'ot_1',
          text: 'Ravon, so‘zlab, tushunib o‘qiydi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'ot_2',
          text: 'So‘zlab o‘qiydi, ba’zan bo‘g‘inlaydi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'ot_3',
          text: 'Bo‘g‘inlab o‘qiydi',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'ot_4',
          text: 'Harflarni taniydi, lekin o‘qiy olmaydi',
          score: 0.0,
        ),
      ],
      scoringCriteria: '0–3 ball.',
      psychologistNotes:
          'O‘qish tezligini (so‘z/daqiqa) "O‘qish tezligi" ko‘rsatkichiga kiriting.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: {QuestionRequirement.vision, QuestionRequirement.reading},
      adaptationHint:
          'Ko‘rishi zaif bola uchun yirik shrift yoki Brayl yozuvi; nutqi cheklangan bola uchun o‘qiganini rasm bilan moslashtirish.',
    ),
    AssessmentQuestionModel(
      id: 'q_oq_03',
      title: 'Yozish ko‘nikmasi',
      text:
          'Bola darajasiga mos so‘z va gaplarni qanday yozadi (ko‘chirib yoki diktant)?',
      domain: 'O‘quv ko‘nikmalari',
      targetAgeRange: 'Barcha yoshlar',
      minGrade: 1,
      questionType: 'single_choice',
      options: [
        AssessmentQuestionOption(
          id: 'yz_1',
          text: 'Mustaqil, deyarli xatosiz yozadi',
          score: 3.0,
        ),
        AssessmentQuestionOption(
          id: 'yz_2',
          text: 'Ko‘chirib to‘g‘ri yozadi, diktantda xato qiladi',
          score: 2.0,
        ),
        AssessmentQuestionOption(
          id: 'yz_3',
          text: 'Alohida harflar va qisqa so‘zlarni yozadi',
          score: 1.0,
        ),
        AssessmentQuestionOption(
          id: 'yz_4',
          text: 'Hali yoza olmaydi',
          score: 0.0,
        ),
      ],
      scoringCriteria: '0–3 ball.',
      psychologistNotes:
          'Harakat imkoniyati cheklangan bola uchun klaviatura yoki harfli kartochkalar.',
      authorId: 'system_standard',
      authorName: 'Standart diagnostika banki',
      isStandard: true,
      status: 'ready',
      createdAt: DateTime(2026, 11, 1),
      requirements: {
        QuestionRequirement.writing,
        QuestionRequirement.handMotor,
      },
      adaptationHint:
          'Qo‘lda yozish o‘rniga klaviatura, planshet yoki harfli kartochkalardan so‘z terish.',
    ),
  ];
}
