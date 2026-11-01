import '../models/assessment_model.dart';
import '../models/assessment_question_model.dart';
import '../models/development_profile_model.dart';
import '../models/student_model.dart';

/// Savolning bolaga mosligi
enum QuestionSuitability {
  suitable,
  needsAdaptation,
  unsuitable;

  String get label => switch (this) {
    QuestionSuitability.suitable => 'Mos',
    QuestionSuitability.needsAdaptation => 'Moslashtirish kerak',
    QuestionSuitability.unsuitable => 'Mos emas',
  };
}

/// Bitta savol bo'yicha tavsiya va uning sabablari.
/// Bu faqat tavsiya — yakuniy qarorni psixolog qabul qiladi.
class QuestionFit {
  final AssessmentQuestionModel question;
  final QuestionSuitability suitability;
  final bool gradeMatches;

  /// Nima uchun shunday baholandi (foydalanuvchiga ko'rsatiladi)
  final List<String> reasons;

  /// Qo'lda tekshirish kerak bo'lgan holatlar (profil yoki savol talablari to'ldirilmagan)
  final List<String> warnings;

  const QuestionFit({
    required this.question,
    required this.suitability,
    required this.gradeMatches,
    this.reasons = const [],
    this.warnings = const [],
  });

  bool get isRecommended =>
      suitability != QuestionSuitability.unsuitable && gradeMatches;
}

/// Ishchi sinf bo'yicha tavsiya (baholash natijasidan keyin)
enum LevelSuggestion { lower, keep, higher }

class LevelChangeAdvice {
  final LevelSuggestion suggestion;
  final int suggestedGrade;
  final String reason;

  const LevelChangeAdvice(this.suggestion, this.suggestedGrade, this.reason);
}

/// Qaysi savollar qaysi bolaga mos kelishini aniqlaydi.
///
/// Qoidalar:
/// 1. Sinf: odatiy holatda bola o'z sinfi uchun standart savollarni oladi
///    (yuqori sinflar savollari murakkabroq). Psixolog yo'nalish bo'yicha boshqa
///    "ishchi sinf"ni belgilagan bo'lsa — o'sha sinf savollari.
/// 2. Imkoniyat: savol bola bajara olmaydigan narsani (nutq, eshitish, ko'rish,
///    qo'l motorikasi, o'qish, yozish) talab qilsa — moslashtirish kerak yoki mos emas.
/// 3. Qayta baholash bir xil savollar to'plami bilan o'tkaziladi — solishtirish shundagina adolatli.
class QuestionSelectionService {
  static final QuestionSelectionService _instance =
      QuestionSelectionService._internal();
  factory QuestionSelectionService() => _instance;
  QuestionSelectionService._internal();

  // Natija ulushi bo'yicha ishchi sinfni o'zgartirish chegaralari
  static const double lowerLevelThreshold = 0.25;
  static const double higherLevelThreshold = 0.9;

  /// Bolaning sinfi (sinf matnidan; aniqlab bo'lmasa yoshidan: 7 yosh ≈ 1-sinf)
  int studentGrade(StudentModel student) =>
      GradeBand.parseGrade(student.grade) ??
      (student.age - 6).clamp(GradeBand.lowestGrade, GradeBand.highestGrade);

  /// Yo'nalish bo'yicha ishchi sinf: psixolog belgilagan bo'lsa — o'sha,
  /// aks holda bolaning o'z sinfi (odatiy holat).
  int workingGrade(StudentModel student, String domain) =>
      student.domainLevels[domain]?.workingGrade ?? studentGrade(student);

  /// Psixolog bu yo'nalish uchun alohida ishchi sinf belgilaganmi?
  bool hasCustomLevel(StudentModel student, String domain) =>
      student.domainLevels.containsKey(domain);

  QuestionFit evaluate(
    AssessmentQuestionModel question,
    StudentModel student, {
    int? grade,
  }) {
    final reasons = <String>[];
    final warnings = <String>[];
    var suitability = QuestionSuitability.suitable;

    // ---------- 1. Sinf ----------
    final targetGrade = grade ?? workingGrade(student, question.domain);
    final gradeMatches = question.coversGrade(targetGrade);
    if (!gradeMatches) {
      final r = question.gradeRange!;
      reasons.add(
        'Sinf mos emas: savol ${r.min}–${r.max}-sinflar uchun, bola ${GradeBand.gradeLabel(targetGrade)} darajasida.',
      );
    }

    // ---------- 2. Imkoniyatlar ----------
    final profile = student.accessProfile;
    final requirements = question.requirements;
    if (profile == null) {
      warnings.add(
        'Bolaning imkoniyatlar profili to‘ldirilmagan — mosligini qo‘lda tekshiring.',
      );
    } else if (requirements == null) {
      warnings.add(
        'Savol talablari ko‘rsatilmagan — mosligini qo‘lda tekshiring.',
      );
    } else {
      for (final r in requirements) {
        final ability = profile.abilityFor(r);
        if (ability == AbilityLevel.full) continue;
        final hint = question.adaptationHint;
        if (ability == AbilityLevel.partial || hint != null) {
          suitability = _worse(suitability, QuestionSuitability.needsAdaptation);
          reasons.add(
            '${r.label} talab qilinadi (bolada: ${ability.label.toLowerCase()})'
            '${hint != null ? '. Moslashtirish: $hint' : ''}',
          );
        } else {
          suitability = QuestionSuitability.unsuitable;
          reasons.add(
            '${r.label} talab qilinadi, bolada bu imkoniyat yo‘q va savolni moslashtirib bo‘lmaydi.',
          );
        }
      }
    }

    return QuestionFit(
      question: question,
      suitability: suitability,
      gradeMatches: gradeMatches,
      reasons: reasons,
      warnings: warnings,
    );
  }

  /// Bola uchun odatiy (standart) savollar to'plami: uning ishchi sinfiga mos,
  /// tayyor standart savollar, bajarib bo'lmaydiganlari chiqarilgan holda.
  /// Psixolog bu ro'yxatga savol qo'shishi yoki olib tashlashi mumkin.
  List<QuestionFit> defaultSet(
    List<AssessmentQuestionModel> questions,
    StudentModel student, {
    String? domain,
  }) {
    return rankForStudent(questions, student, domain: domain)
        .where((f) => f.question.isStandard && f.isRecommended)
        .toList();
  }

  /// Savollarni bola uchun tartiblab qaytaradi: avval mos, keyin moslashtirish kerak,
  /// oxirida mos emaslar; har guruhda sinfga mos keladiganlari oldinda.
  /// Mos emaslar ham qaytariladi — psixolog o'zi qaror qiladi.
  List<QuestionFit> rankForStudent(
    List<AssessmentQuestionModel> questions,
    StudentModel student, {
    String? domain,
    int? grade,
    bool onlyReady = true,
  }) {
    final fits = questions
        .where((q) => domain == null || q.domain == domain)
        .where((q) => !onlyReady || q.isReady)
        .map((q) => evaluate(q, student, grade: grade))
        .toList();
    int rank(QuestionFit f) =>
        f.suitability.index * 2 + (f.gradeMatches ? 0 : 1);
    fits.sort((a, b) => rank(a).compareTo(rank(b)));
    return fits;
  }

  /// Baholash natijasi ulushiga (0..1) qarab ishchi sinf bo'yicha tavsiya.
  /// Bir sinflar guruhi pastga yoki yuqoriga suriladi.
  LevelChangeAdvice adviseLevelChange(double scoreRatio, int currentGrade) {
    final band = GradeBand.forGrade(currentGrade);
    if (scoreRatio <= lowerLevelThreshold && band != GradeBand.values.first) {
      return LevelChangeAdvice(
        LevelSuggestion.lower,
        band.shift(-1).maxGrade,
        'Topshiriqlarning ko‘pchiligi hozircha qiyin bo‘ldi — quyiroq sinf savollaridan boshlashni ko‘rib chiqing.',
      );
    }
    if (scoreRatio >= higherLevelThreshold && band != GradeBand.values.last) {
      return LevelChangeAdvice(
        LevelSuggestion.higher,
        band.shift(1).minGrade,
        'Bu sinf savollari to‘liq o‘zlashtirilgan — yuqoriroq sinf savollarini ko‘rib chiqing.',
      );
    }
    return LevelChangeAdvice(
      LevelSuggestion.keep,
      currentGrade,
      'Daraja mos — shu sinf savollari bilan davom eting.',
    );
  }

  /// Ikki baholash natijasini foiz bo'yicha solishtirish mumkinmi?
  /// Faqat bir xil savollar to'plami bilan o'tkazilganda.
  bool areComparable(AssessmentModel a, AssessmentModel b) {
    if (a.studentId != b.studentId) return false;
    if (a.questionIds.isEmpty || b.questionIds.isEmpty) return false;
    return a.questionIds.toSet().length == b.questionIds.toSet().length &&
        a.questionIds.toSet().containsAll(b.questionIds);
  }

  QuestionSuitability _worse(QuestionSuitability a, QuestionSuitability b) =>
      a.index >= b.index ? a : b;
}
