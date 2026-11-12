import '../models/assessment_model.dart';
import 'dynamics_service.dart';

/// Bitta bolaning oxirgi baholashi va uning oldingisiga nisbatan o'zgarishi
/// (shu yo'nalish ichida). Qoida DynamicsService'da: 10% dan ko'p yaxshi —
/// o'sish, 10% dan ko'p yomon — pasayish.
class ChildChange {
  final AssessmentModel last;
  final DynamicsResult result;
  const ChildChange(this.last, this.result);

  /// Oldingisiga nisbatan foizdagi o'zgarish (bitta natija bo'lsa — null).
  double? get percent => result.changePercent;
}

/// Har bola uchun bitta qator: avval pasayish, keyin samarasiz, o'sish,
/// barqaror va bitta natijalilar.
List<ChildChange> childChanges(Iterable<AssessmentModel> assessments) {
  final byStudent = <String, List<AssessmentModel>>{};
  for (final a in assessments) {
    if (!a.isCompleted || a.maxScore <= 0) continue;
    byStudent.putIfAbsent(a.studentId, () => []).add(a);
  }
  final out = <ChildChange>[];
  byStudent.forEach((_, list) {
    list.sort((x, y) => x.assessmentDate.compareTo(y.assessmentDate));
    final last = list.last;
    final same = list.where((x) => x.category == last.category);
    final result = DynamicsService().evaluate([
      for (final x in same)
        DataPoint(x.assessmentDate, x.totalScore / x.maxScore * 100),
    ]);
    out.add(ChildChange(last, result));
  });
  int rank(DynamicsStatus s) => switch (s) {
    DynamicsStatus.decline => 0,
    DynamicsStatus.ineffective => 1,
    DynamicsStatus.growth => 2,
    DynamicsStatus.stable => 3,
    DynamicsStatus.insufficientData => 4,
  };
  out.sort((x, y) => rank(x.result.status).compareTo(rank(y.result.status)));
  return out;
}
