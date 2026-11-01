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

  /// Tavsiya etiladigan daraja: talablari o'zlashtirilgan eng yuqori sinf,
  /// undan pastdagi baholangan sinflar ham o'zlashtirilgan bo'lishi sharti bilan.
  /// Baholanmagan quyi sinflar o'zlashtirilgan deb qabul qilinadi.
  /// 0 = 1-sinf talablariga hali yetmagan. null = hech narsa baholanmagan.
  int? suggestGrade(
    Map<String, Mastery> results,
    List<CurriculumStandard> standards,
  ) {
    final byGrade = masteryByGrade(results, standards);
    if (byGrade.isEmpty) return null;
    final grades = byGrade.keys.toList()..sort();
    var achieved = grades.first - 1;
    for (final g in grades) {
      if (byGrade[g]! >= masteryThreshold) {
        achieved = g;
      } else {
        break;
      }
    }
    return achieved < 0 ? 0 : achieved;
  }

  /// Eng quyi baholangan sinf ham o'zlashtirilmagan bo'lsa, haqiqiy daraja undan ham
  /// past bo'lishi mumkin — quyiroq sinf talablarini ham tekshirish kerak.
  /// (Masalan, 7-sinf o'quvchisi faqat 7-sinf talablari bo'yicha tekshirilib, o'tolmagan.)
  bool needsLowerGradeCheck(
    Map<String, Mastery> results,
    List<CurriculumStandard> standards,
  ) {
    final byGrade = masteryByGrade(results, standards);
    if (byGrade.isEmpty) return false;
    final lowest = byGrade.keys.reduce((a, b) => a < b ? a : b);
    return lowest > 1 && byGrade[lowest]! < masteryThreshold;
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
    }).toList()..sort((a, b) => a.grade.compareTo(b.grade));
  }

  /// Foydalanuvchiga ko'rsatiladigan qisqa xulosa
  String describe(SubjectLevelAssessment a) {
    final level = a.confirmedGrade == 0
        ? '1-sinf talablariga hali yetmagan'
        : '${a.confirmedGrade}-sinf darajasi';
    final gapText = a.gap > 0
        ? ' (sinfidan ${a.gap} sinf past)'
        : a.gap < 0
        ? ' (sinfidan ${-a.gap} sinf yuqori)'
        : ' (sinfiga mos)';
    return '${a.classGrade}-sinf o‘quvchisi, ${a.subject}: $level$gapText';
  }
}
