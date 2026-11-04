/// Rivojlanish dinamikasi: oldingi va yangi natijalarni taqqoslab holatni aniqlaydi.
/// Barcha xulosalar mutaxassislar kiritgan natijalarga asoslanadi — tizim taxmin qilmaydi.
enum DynamicsStatus {
  growth,
  decline,
  stable,
  ineffective,
  insufficientData;

  String get label => switch (this) {
    DynamicsStatus.growth => 'O‘sish',
    DynamicsStatus.decline => 'Pasayish',
    DynamicsStatus.stable => 'Barqaror holat',
    DynamicsStatus.ineffective => 'Samarasiz natija',
    DynamicsStatus.insufficientData => 'Ma’lumot yetarli emas',
  };
}

/// Taqqoslash davri: har bir o'lchov, oylik yoki choraklik
enum DynamicsPeriod { measurement, month, quarter }

class DataPoint {
  final DateTime at;
  final double value;
  const DataPoint(this.at, this.value);
}

class DynamicsResult {
  final DynamicsStatus status;
  final DataPoint? previous;
  final DataPoint? latest;

  /// Davr bo'yicha qatorlar (oylik bo'lsa — har oy uchun bitta nuqta)
  final List<DataPoint> series;
  final String reason;

  const DynamicsResult({
    required this.status,
    required this.series,
    required this.reason,
    this.previous,
    this.latest,
  });

  double? get change =>
      (previous != null && latest != null)
          ? latest!.value - previous!.value
          : null;

  double? get changePercent =>
      (previous != null && latest != null && previous!.value != 0)
          ? (latest!.value - previous!.value) / previous!.value.abs() * 100
          : null;
}

class DynamicsService {
  static final DynamicsService _instance = DynamicsService._internal();
  factory DynamicsService() => _instance;
  DynamicsService._internal();

  /// Sezilarli o'zgarish chegarasi: oldingi qiymatning 10%
  static const double defaultRelativeThreshold = 0.1;

  /// "Samarasiz natija": kamida shuncha o'lchov va kun davomida sezilarli yaxshilanish yo'q
  static const int ineffectiveMinPoints = 3;
  static const int ineffectiveMinDays = 30;

  /// Nuqtalarni davr bo'yicha guruhlash: har davr uchun oxirgi qiymat olinadi
  List<DataPoint> aggregate(List<DataPoint> points, DynamicsPeriod period) {
    final sorted = [...points]..sort((a, b) => a.at.compareTo(b.at));
    if (period == DynamicsPeriod.measurement) return sorted;
    final byKey = <DateTime, DataPoint>{};
    for (final p in sorted) {
      final key =
          period == DynamicsPeriod.month
              ? DateTime(p.at.year, p.at.month)
              : DateTime(p.at.year, ((p.at.month - 1) ~/ 3) * 3 + 1);
      byKey[key] = DataPoint(key, p.value);
    }
    return byKey.values.toList()..sort((a, b) => a.at.compareTo(b.at));
  }

  DynamicsResult evaluate(
    List<DataPoint> points, {
    bool higherIsBetter = true,
    DynamicsPeriod period = DynamicsPeriod.measurement,
    double relativeThreshold = defaultRelativeThreshold,
    double? absoluteThreshold,
    String unit = '',
  }) {
    final series = aggregate(points, period);
    if (series.length < 2) {
      return DynamicsResult(
        status: DynamicsStatus.insufficientData,
        series: series,
        latest: series.isEmpty ? null : series.last,
        reason: 'Taqqoslash uchun kamida ikkita natija kerak.',
      );
    }

    final prev = series[series.length - 2];
    final last = series.last;
    double threshold(double base) =>
        absoluteThreshold ??
        (base.abs() > 0 ? base.abs() * relativeThreshold : relativeThreshold);
    double improvement(double from, double to) =>
        higherIsBetter ? to - from : from - to;

    final u = unit.isEmpty ? '' : ' $unit';
    final changeText = '${_fmt(prev.value)}$u → ${_fmt(last.value)}$u';

    // 1. Pasayish: oxirgi natija oldingisidan sezilarli yomon
    final step = improvement(prev.value, last.value);
    if (step < -threshold(prev.value)) {
      return DynamicsResult(
        status: DynamicsStatus.decline,
        series: series,
        previous: prev,
        latest: last,
        reason:
            'Oldingi natijaga nisbatan ko‘rsatkich yomonlashgan: $changeText.',
      );
    }

    // 2. Samarasiz natija: uzoq vaqt davomida sezilarli yaxshilanish yo'q
    if (series.length >= ineffectiveMinPoints) {
      final window = series.sublist(series.length - ineffectiveMinPoints);
      final days = window.last.at.difference(window.first.at).inDays;
      final overall = improvement(window.first.value, window.last.value);
      if (days >= ineffectiveMinDays &&
          overall <= threshold(window.first.value)) {
        return DynamicsResult(
          status: DynamicsStatus.ineffective,
          series: series,
          previous: prev,
          latest: last,
          reason:
              'Oxirgi $ineffectiveMinPoints ta natija ($days kun) davomida sezilarli yaxshilanish yo‘q '
              '(${_fmt(window.first.value)}$u → ${_fmt(window.last.value)}$u). '
              'Qo‘llanilayotgan yordamni qayta ko‘rib chiqing.',
        );
      }
    }

    // 3. O'sish yoki barqaror holat
    if (step > threshold(prev.value)) {
      return DynamicsResult(
        status: DynamicsStatus.growth,
        series: series,
        previous: prev,
        latest: last,
        reason: 'Oldingi natijaga nisbatan ijobiy o‘zgarish: $changeText.',
      );
    }
    return DynamicsResult(
      status: DynamicsStatus.stable,
      series: series,
      previous: prev,
      latest: last,
      reason: 'Sezilarli o‘zgarish kuzatilmadi: $changeText.',
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}
