import '../../models/curriculum_model.dart';

/// NAMUNAVIY talablar — tizimni sinash uchun umumiy ko'nikmalar.
/// Bu rasmiy DTS matni EMAS. Rasmiy davlat ta'lim standartlari olingach,
/// LocalDbService.importCurriculumStandards() orqali almashtiriladi.
class CurriculumStandardsSeed {
  static const _source = 'Namuna (rasmiy DTS bilan almashtirilishi kerak)';

  static const Map<String, Map<int, List<String>>> _table = {
    SchoolSubjects.matematika: {
      1: [
        '20 ichida sanaydi va sonlarni taqqoslaydi',
        '10 ichida qo‘shish va ayirishni bajaradi',
        'Oddiy geometrik shakllarni (doira, kvadrat, uchburchak) taniydi',
      ],
      2: [
        '100 ichida qo‘shish va ayirishni bajaradi',
        '2–5 ga ko‘paytirish jadvalini biladi',
        'Uzunlikni santimetr va metrda o‘lchaydi',
      ],
      3: [
        'Ko‘paytirish va bo‘lish jadvalini to‘liq biladi',
        '1000 ichidagi sonlarni o‘qiydi, yozadi va taqqoslaydi',
        'Soat bo‘yicha vaqtni aniqlaydi',
      ],
      4: [
        'Ko‘p xonali sonlar ustida to‘rt amalni bajaradi',
        'Oddiy kasr tushunchasini tushunadi',
        'To‘g‘ri to‘rtburchakning perimetri va yuzini hisoblaydi',
      ],
      5: [
        'Natural sonlar va oddiy kasrlar bilan amallar bajaradi',
        'O‘nli kasrlarni o‘qiydi va ular bilan amallar bajaradi',
        'Oddiy matnli masalalarni yechadi',
      ],
      6: [
        'Musbat va manfiy sonlar bilan amallar bajaradi',
        'Nisbat va proporsiyani qo‘llaydi',
        'Sonning foizini hisoblaydi',
      ],
      7: [
        'Algebraik ifodalarni soddalashtiradi',
        'Bir noma’lumli chiziqli tenglamalarni yechadi',
        'Burchak va uchburchak xossalarini qo‘llaydi',
      ],
    },
    SchoolSubjects.onaTili: {
      1: [
        'Harf va tovushlarni farqlaydi',
        'So‘zlarni bo‘g‘inlab yozadi',
        'Gapdagi so‘zlarni ajratadi',
      ],
      2: [
        'Tanish so‘zlarni imlo qoidalariga muvofiq yozadi',
        'Darak va so‘roq gaplarni farqlaydi',
        'Kichik matnni xatosiz ko‘chiradi',
      ],
      3: [
        'Ot, sifat va fe’lni farqlaydi',
        'Gapning bosh bo‘laklarini topadi',
        '5–6 gapdan iborat matn tuzadi',
      ],
      4: [
        'So‘z tarkibini (o‘zak, qo‘shimcha) ajratadi',
        'Asosiy tinish belgilarini to‘g‘ri qo‘llaydi',
        'Eshitgan yoki o‘qigan matni bo‘yicha bayon yozadi',
      ],
      5: [
        'Asosiy imlo qoidalarini qo‘llaydi',
        'So‘z yasalishini tushunadi',
        'Reja asosida matn tuzadi',
      ],
      6: [
        'Ot, sifat, son va olmoshning grammatik belgilarini ajratadi',
        'So‘z birikmalarini tuzadi',
        'Berilgan mavzuda insho yozadi',
      ],
      7: [
        'Fe’l shakllarini to‘g‘ri qo‘llaydi',
        'Ravish va ko‘makchilarni farqlaydi',
        'Qo‘shma gaplar tuzadi',
      ],
    },
    SchoolSubjects.oqish: {
      1: [
        'Harflarni tanib, bo‘g‘inlab o‘qiydi',
        'Qisqa so‘z va gaplarni o‘qiydi',
        'Eshitgan ertak mazmunini aytib beradi',
      ],
      2: [
        'Qisqa matnni so‘zlab, ravon o‘qiydi',
        'O‘qigan matni bo‘yicha savollarga javob beradi',
        'Kichik she’rni yod oladi',
      ],
      3: [
        'Matnni ifodali o‘qiydi',
        'Matn bo‘yicha oddiy reja tuzadi',
        'Matnning asosiy fikrini aytadi',
      ],
      4: [
        'Matnni mustaqil o‘qib, mazmunini qayta hikoya qiladi',
        'Asar qahramonlariga baho beradi',
        'O‘qigan kitobi haqida qisqa fikr bildiradi',
      ],
    },
  };

  static String _subjectKey(String subject) => switch (subject) {
    SchoolSubjects.matematika => 'mat',
    SchoolSubjects.onaTili => 'ona',
    SchoolSubjects.oqish => 'oqi',
    _ => subject.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_'),
  };

  static List<CurriculumStandard> get standards => [
    for (final subject in _table.entries)
      for (final grade in subject.value.entries)
        for (var i = 0; i < grade.value.length; i++)
          CurriculumStandard(
            id: 'dts_${_subjectKey(subject.key)}_${grade.key}_${i + 1}',
            subject: subject.key,
            grade: grade.key,
            description: grade.value[i],
            source: _source,
          ),
  ];
}
