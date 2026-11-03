import 'package:flutter_test/flutter_test.dart';
import 'package:talim_nazorat/models/assessment_model.dart';
import 'package:talim_nazorat/services/monthly_trend.dart';

AssessmentModel _a(
  DateTime date,
  double score, {
  double max = 100,
  String status = 'completed',
}) => AssessmentModel(
  id: 'a-${date.toIso8601String()}-$score',
  studentId: 's1',
  studentName: 'Test',
  specialistId: 'u1',
  specialistName: 'Mutaxassis',
  specialistRole: 'psychologist',
  assessmentDate: date,
  type: 'test',
  category: 'Kompleks',
  title: 'Test',
  notes: '',
  recommendations: '',
  totalScore: score,
  maxScore: max,
  status: status,
);

void main() {
  final now = DateTime(2026, 11, 3);

  test('no assessments gives no points (no invented data)', () {
    expect(monthlyAverages(const [], now: now), isEmpty);
  });

  test('averages per month, sorted, skipping empty months', () {
    final points = monthlyAverages([
      _a(DateTime(2026, 11, 1), 80),
      _a(DateTime(2026, 9, 10), 50),
      _a(DateTime(2026, 9, 20), 70),
    ], now: now);
    expect([for (final p in points) p.shortLabel], ['Sen', 'Noy']);
    expect(points.first.percent, 60);
    expect(points.first.count, 2);
    expect(points.last.percent, 80);
  });

  test('drafts, zero max score and old months are ignored', () {
    final points = monthlyAverages([
      _a(DateTime(2026, 10, 5), 90, status: 'draft'),
      _a(DateTime(2026, 10, 5), 5, max: 0),
      _a(DateTime(2026, 5, 31), 40), // 6 oylik oynadan tashqarida (Iyun–Noy)
      _a(DateTime(2026, 6, 1), 30, max: 60),
    ], now: now);
    expect(points.length, 1);
    expect(points.single.shortLabel, 'Iyun');
    expect(points.single.percent, 50);
  });
}
