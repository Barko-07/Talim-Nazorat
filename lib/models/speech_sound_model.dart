// Logopedik tovushlar kartasi: har bir maqsadli tovushning tuzatish bosqichlari tarixi.

/// Tovushlar guruhi (logopediyada ish shu guruhlar bo'yicha rejalashtiriladi)
enum SoundGroup {
  vowel('Unli tovushlar'),
  whistling('Hushtaksimon (s, z)'),
  hissing('Shivillovchi (sh, j, ch)'),
  sonorant('Sonor (r, l)'),
  backLingual('Til orqa (k, g, q, g‘, x, h)'),
  other('Boshqa undoshlar');

  final String label;
  const SoundGroup(this.label);
}

/// O'zbek tilidagi tovush
class SpeechSound {
  final String id;
  final String display;
  final SoundGroup group;

  /// Ko'pincha shu tovush bilan aralashtiriladigan tovushlar (differensiatsiya juftlari)
  final List<String> confusedWith;

  const SpeechSound(this.id, this.display, this.group, {this.confusedWith = const []});
}

/// Tovush talaffuzidagi buzilish turi
enum SoundDisorder {
  none('Me’yorda'),
  omission('Tushirib qoldiradi'),
  substitution('Boshqa tovushga almashtiradi'),
  distortion('Buzib talaffuz qiladi');

  final String label;
  const SoundDisorder(this.label);

  static SoundDisorder fromName(String? name) => SoundDisorder.values
      .firstWhere((d) => d.name == name, orElse: () => SoundDisorder.none);
}

/// Tovushni tuzatish bosqichlari (tartib — rivojlanish tartibi)
enum SoundStage {
  preparation('Tayyorlov (artikulyatsion mashqlar)'),
  staging('Tovush qo‘yish'),
  syllables('Avtomatlashtirish: bo‘g‘inlarda'),
  words('Avtomatlashtirish: so‘zlarda'),
  phrases('Avtomatlashtirish: gaplarda'),
  connectedSpeech('Avtomatlashtirish: matn va hikoyada'),
  differentiation('Differensiatsiya (o‘xshash tovushlardan farqlash)'),
  spontaneous('Erkin nutqda to‘g‘ri talaffuz');

  final String label;
  const SoundStage(this.label);

  bool get isMastered => this == SoundStage.spontaneous;

  /// Tovush qo'yilganmi (alohida to'g'ri aytiladi)
  bool get isSet => index >= SoundStage.syllables.index;

  SoundStage? get next =>
      index + 1 < SoundStage.values.length ? SoundStage.values[index + 1] : null;

  static SoundStage? fromName(String? name) {
    for (final s in values) {
      if (s.name == name) return s;
    }
    return null;
  }
}

/// Tovush bo'yicha bitta qayd: qaysi bosqichda, qanday buzilish bilan, kim va qachon qayd etdi.
/// Qaydlar o'chirilmaydi — tarix tovushning rivojlanish chizig'ini beradi.
class SoundEntry {
  final String id;
  final String studentId;
  final String soundId;
  final SoundStage stage;
  final SoundDisorder disorder;

  /// Almashtirish bo'lsa — qaysi tovushga almashtiradi
  final String? substitutedWith;

  /// Differensiatsiya bosqichida — qaysi tovushdan farqlanmoqda
  final String? differentiatedFrom;
  final String? note;
  final String recordedById;
  final String recordedByName;
  final DateTime recordedAt;

  const SoundEntry({
    required this.id,
    required this.studentId,
    required this.soundId,
    required this.stage,
    this.disorder = SoundDisorder.none,
    this.substitutedWith,
    this.differentiatedFrom,
    this.note,
    required this.recordedById,
    required this.recordedByName,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'soundId': soundId,
    'stage': stage.name,
    'disorder': disorder.name,
    'substitutedWith': substitutedWith,
    'differentiatedFrom': differentiatedFrom,
    'note': note,
    'recordedById': recordedById,
    'recordedByName': recordedByName,
    'recordedAt': recordedAt.toIso8601String(),
  };

  factory SoundEntry.fromJson(Map<String, dynamic> json) => SoundEntry(
    id: json['id'] as String,
    studentId: json['studentId'] as String,
    soundId: json['soundId'] as String,
    stage: SoundStage.fromName(json['stage'] as String?) ?? SoundStage.preparation,
    disorder: SoundDisorder.fromName(json['disorder'] as String?),
    substitutedWith: json['substitutedWith'] as String?,
    differentiatedFrom: json['differentiatedFrom'] as String?,
    note: json['note'] as String?,
    recordedById: json['recordedById'] as String? ?? '',
    recordedByName: json['recordedByName'] as String? ?? '',
    recordedAt: DateTime.parse(json['recordedAt'] as String),
  );
}
