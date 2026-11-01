/// O'lchanadigan ko'rsatkich (masalan, "Diqqatni jamlash davomiyligi, daqiqa").
/// Natijalar ball emas, birligi bilan qayd etiladi — "2 daqiqa -> 5 daqiqa".
class ProgressMetric {
  final String id;
  final String name;
  final String unit;
  final String domain;

  /// true: qiymat oshsa — yaxshilanish (daqiqa, so'zlar soni).
  /// false: qiymat kamaysa — yaxshilanish (xatolar soni, haftalik portlashlar).
  final bool higherIsBetter;

  const ProgressMetric({
    required this.id,
    required this.name,
    required this.unit,
    required this.domain,
    this.higherIsBetter = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'unit': unit,
    'domain': domain,
    'higherIsBetter': higherIsBetter,
  };

  factory ProgressMetric.fromJson(Map<String, dynamic> json) => ProgressMetric(
    id: json['id'] as String,
    name: json['name'] as String,
    unit: json['unit'] as String? ?? '',
    domain: json['domain'] as String? ?? '',
    higherIsBetter: json['higherIsBetter'] as bool? ?? true,
  );
}

/// Bitta o'lchov: qaysi bola, qaysi ko'rsatkich, qachon, qancha.
class ProgressMeasurement {
  final String id;
  final String studentId;
  final String metricId;
  final double value;
  final DateTime measuredAt;
  final String recordedById;
  final String recordedByName;
  final String? note;

  /// Bog'liq ITR maqsadi (yordam samaradorligini baholash uchun)
  final String? iepObjectiveId;

  const ProgressMeasurement({
    required this.id,
    required this.studentId,
    required this.metricId,
    required this.value,
    required this.measuredAt,
    required this.recordedById,
    required this.recordedByName,
    this.note,
    this.iepObjectiveId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'metricId': metricId,
    'value': value,
    'measuredAt': measuredAt.toIso8601String(),
    'recordedById': recordedById,
    'recordedByName': recordedByName,
    'note': note,
    'iepObjectiveId': iepObjectiveId,
  };

  factory ProgressMeasurement.fromJson(Map<String, dynamic> json) =>
      ProgressMeasurement(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        metricId: json['metricId'] as String,
        value: (json['value'] as num).toDouble(),
        measuredAt: DateTime.parse(json['measuredAt'] as String),
        recordedById: json['recordedById'] as String? ?? '',
        recordedByName: json['recordedByName'] as String? ?? '',
        note: json['note'] as String?,
        iepObjectiveId: json['iepObjectiveId'] as String?,
      );
}
