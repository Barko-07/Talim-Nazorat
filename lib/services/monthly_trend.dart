import '../models/assessment_model.dart';

/// Bir oy bo'yicha yakunlangan baholashlarning o'rtacha natijasi (foizda).
class MonthlyAverage {
  final DateTime month; // oyning 1-kuni
  final double percent;
  final int count;

  const MonthlyAverage(this.month, this.percent, this.count);

  String get shortLabel => monthShortNames[month.month - 1];
}

const monthShortNames = [
  'Yan',
  'Fev',
  'Mar',
  'Apr',
  'May',
  'Iyun',
  'Iyul',
  'Avg',
  'Sen',
  'Okt',
  'Noy',
  'Dek',
];

/// So'nggi [months] kalendar oyi ichidagi haqiqiy baholashlardan oylik
/// o'rtachalarni hisoblaydi. Ma'lumoti yo'q oylar qo'shilmaydi — hech qanday
/// taxminiy yoki oraliq nuqta yaratilmaydi.
List<MonthlyAverage> monthlyAverages(
  Iterable<AssessmentModel> assessments, {
  required DateTime now,
  int months = 6,
}) {
  final firstMonth = DateTime(now.year, now.month - (months - 1));
  final buckets = <DateTime, List<double>>{};
  for (final a in assessments) {
    if (!a.isCompleted || a.maxScore <= 0) continue;
    final m = DateTime(a.assessmentDate.year, a.assessmentDate.month);
    if (m.isBefore(firstMonth) || m.isAfter(now)) continue;
    buckets
        .putIfAbsent(m, () => [])
        .add((a.totalScore / a.maxScore * 100).clamp(0.0, 100.0));
  }
  final keys = buckets.keys.toList()..sort();
  return [
    for (final k in keys)
      MonthlyAverage(
        k,
        buckets[k]!.reduce((a, b) => a + b) / buckets[k]!.length,
        buckets[k]!.length,
      ),
  ];
}

/// So'nggi [days] kun ichidagi baholashlar — haftalar bo'yicha o'rtacha
/// (foizda). Bosh sahifadagi "So'nggi 1 oy" grafigi uchun. Ma'lumoti yo'q
/// haftalar qo'shilmaydi.
class WeeklyAverage {
  final DateTime weekStart; // dushanba
  final double percent;
  final int count;

  const WeeklyAverage(this.weekStart, this.percent, this.count);

  String get shortLabel =>
      '${weekStart.day.toString().padLeft(2, '0')}.${weekStart.month.toString().padLeft(2, '0')}';
}

List<WeeklyAverage> weeklyAverages(
  Iterable<AssessmentModel> assessments, {
  required DateTime now,
  int days = 30,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final from = today.subtract(Duration(days: days));
  final buckets = <DateTime, List<double>>{};
  for (final a in assessments) {
    if (!a.isCompleted || a.maxScore <= 0) continue;
    final d = DateTime(a.assessmentDate.year, a.assessmentDate.month, a.assessmentDate.day);
    if (d.isBefore(from) || d.isAfter(today)) continue;
    final monday = d.subtract(Duration(days: d.weekday - 1));
    buckets
        .putIfAbsent(monday, () => [])
        .add((a.totalScore / a.maxScore * 100).clamp(0.0, 100.0));
  }
  final keys = buckets.keys.toList()..sort();
  return [
    for (final k in keys)
      WeeklyAverage(
        k,
        buckets[k]!.reduce((a, b) => a + b) / buckets[k]!.length,
        buckets[k]!.length,
      ),
  ];
}
