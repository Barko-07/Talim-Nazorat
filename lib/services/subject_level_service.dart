import '../models/curriculum_model.dart';

/// Talablar natijalaridan bolaning fan bo'yicha haqiqiy darajasini hisoblaydi.
/// Bu tavsiya — yakuniy darajani o'qituvchi tasdiqlaydi.
class SubjectLevelService {
  static final SubjectLevelService _instance = SubjectLevelService._internal();
  factory SubjectLevelService() => _instance;
  SubjectLevelService._internal();

  /// Sinf talablari "o'zlashtirilgan" deb hisoblanishi uchun ulush
  /// (qisman o'zlashtirilgan talab yarim hisoblanadi)
  static const double masteryThreshold = 0.8;

  /// Har bir sinf bo'yicha o'zlashtirish ulushi (faqat baholangan talablar bo'yicha)
  Map<int, double> masteryByGrade(
    Map<String, Mastery> results,
    List<CurriculumStandard> standards,
  ) {
    final sums = <int, double>{};
    final counts = <int, int>{};
    for (final s in standards) {
      final m = results[s.id];
      if (m == null) continue;
      sums[s.grade] = (sums[s.grade] ?? 0) + m.weight;
      counts[s.grade] = (counts[s.grade] ?? 0) + 1;
    }
    return {for (final g in counts.keys) g: sums[g]! / counts[g]!};
  }

  /// Birinchi o‘zlashtirilmagan sinfdan oldingi uzluksiz darajani tavsiya qiladi.
  /// 0 = 1-sinf talablariga hali yetmagan; null = quyi sinflarda dalil yetarli
  /// emas yoki mavjud talablarning barchasi bajarilgan bo‘lib, yuqori chegara
  /// aniqlanmagan. Baholanmagan sinflar o‘zlashtirilgan deb olinmaydi.
  int? suggestGrade(
    Map<String, Mastery> results,
    List<CurriculumStandard> standards,
  ) {
    final byGrade = masteryByGrade(results, standards);
    if (byGrade.isEmpty) return null;
    final assessed = byGrade.keys.toList()..sort();
    if (assessed.first > 1) return null;
    for (var g = 1; g <= assessed.last; g++) {
      if (!byGrade.containsKey(g)) return null;
    }
    var achieved = 0;
    for (final grade in assessed) {
      if (byGrade[grade]! >= masteryThreshold) {
        achieved = grade;
      } else {
        return achieved;
      }
    }
    // Barcha mavjud talablar bajarilgani bolaning yuqori chegarasi topildi degani emas.
    return null;
  }

  /// Eng quyi baholangan sinf ham o‘zlashtirilmagan yoki quyi sinflarda
  /// baholanmagan oraliq bo‘lsa, pastroq sinflarni tekshirish kerak.
  /// (Masalan, 7-sinf o'quvchisi faqat 7-sinf talablari bo'yicha tekshirilib, o'tolmagan.)
  bool needsLowerGradeCheck(
    Map<String, Mastery> results,
    List<CurriculumStandard> standards,
  ) {
    final byGrade = masteryByGrade(results, standards);
    if (byGrade.isEmpty) return false;
    final assessed = byGrade.keys.toList()..sort();
    if (assessed.first > 1) return true;
    for (var g = 1; g <= assessed.last; g++) {
      if (!byGrade.containsKey(g)) return true;
    }
    return false;
  }

  /// Keyingi ishlash kerak bo'lgan talablar: tasdiqlangan darajadagi o'zlashtirilmaganlari
  /// va keyingi sinf talablari. Topshiriq tanlash va ITR maqsadlari uchun.
  List<CurriculumStandard> nextStandards(
    int confirmedGrade,
    Map<String, Mastery> results,
    List<CurriculumStandard> standards,
  ) {
    return standards.where((s) {
        if (s.grade > confirmedGrade + 1) return false;
        if (s.grade < confirmedGrade) return false;
        return results[s.id] != Mastery.mastered;
      }).toList()
      ..sort((a, b) => a.grade.compareTo(b.grade));
  }

  /// Foydalanuvchiga ko'rsatiladigan qisqa xulosa
  String describe(SubjectLevelAssessment a) {
    final level =
        a.confirmedGrade == 0
            ? '1-sinf talablariga hali yetmagan'
            : '${a.confirmedGrade}-sinf darajasi';
    final gapText =
        a.gap > 0
            ? ' (sinfidan ${a.gap} sinf past)'
            : a.gap < 0
            ? ' (sinfidan ${-a.gap} sinf yuqori)'
            : ' (sinfiga mos)';
    return '${a.classGrade}-sinf o‘quvchisi, ${a.subject}: $level$gapText';
  }
}
