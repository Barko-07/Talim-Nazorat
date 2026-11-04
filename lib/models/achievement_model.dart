/// "Mening yutuqlar pasportim" yozuvi (talab #11): bolaning erishgan natijalari,
/// o'zlashtirgan ko'nikmalari va ijobiy o'zgarishlari.
enum AchievementCategory {
  skill('Yangi ko‘nikma'),
  subject('O‘quv natijasi'),
  goal('Maqsadga erishildi'),
  task('Topshiriq bajarildi'),
  progress('Ijobiy o‘zgarish'),
  social('Muloqot va ijtimoiy yutuq'),
  other('Boshqa yutuq');

  final String label;
  const AchievementCategory(this.label);

  static AchievementCategory fromName(String? name) =>
      AchievementCategory.values.firstWhere(
        (c) => c.name == name,
        orElse: () => AchievementCategory.other,
      );
}

class Achievement {
  final String id;
  final String studentId;
  final AchievementCategory category;
  final String title;
  final String? description;
  final DateTime achievedAt;

  /// true — tizim natijalardan avtomatik aniqlagan; false — mutaxassis qo'lda kiritgan
  final bool isAutomatic;
  final String? recordedById;
  final String? recordedByName;

  const Achievement({
    required this.id,
    required this.studentId,
    required this.category,
    required this.title,
    this.description,
    required this.achievedAt,
    this.isAutomatic = false,
    this.recordedById,
    this.recordedByName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'category': category.name,
    'title': title,
    'description': description,
    'achievedAt': achievedAt.toIso8601String(),
    'recordedById': recordedById,
    'recordedByName': recordedByName,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'] as String,
    studentId: json['studentId'] as String,
    category: AchievementCategory.fromName(json['category'] as String?),
    title: json['title'] as String,
    description: json['description'] as String?,
    achievedAt: DateTime.parse(json['achievedAt'] as String),
    recordedById: json['recordedById'] as String?,
    recordedByName: json['recordedByName'] as String?,
  );
}

/// Bolaning yutuqlar pasporti: yangidan eskiga tartiblangan yozuvlar
class AchievementPassport {
  final String studentId;
  final String studentName;
  final List<Achievement> entries;

  const AchievementPassport({
    required this.studentId,
    required this.studentName,
    required this.entries,
  });

  int count(AchievementCategory c) =>
      entries.where((e) => e.category == c).length;
  bool get isEmpty => entries.isEmpty;
}
