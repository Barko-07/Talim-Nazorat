import '../core/constants/uzbek_speech_sounds.dart';
import '../models/speech_sound_model.dart';
import 'dynamics_service.dart';

/// Bitta tovushning holati: joriy bosqich, tarix va dinamika
class SoundProgress {
  final SpeechSound sound;

  /// Eskidan yangiga
  final List<SoundEntry> history;
  final DynamicsResult dynamics;

  const SoundProgress({
    required this.sound,
    required this.history,
    required this.dynamics,
  });

  SoundEntry get current => history.last;
  SoundEntry get first => history.first;
  SoundStage get stage => current.stage;
  bool get isMastered => stage.isMastered;

  /// Joriy bosqichda necha kundan beri turibdi
  int daysAtCurrentStage(DateTime now) {
    var since = current.recordedAt;
    for (var i = history.length - 2; i >= 0; i--) {
      if (history[i].stage != current.stage) break;
      since = history[i].recordedAt;
    }
    return now.difference(since).inDays;
  }

  /// Bosqichlar bo'yicha bajarilgan qism (0..1)
  double get completion => stage.index / (SoundStage.values.length - 1);
}

/// Bolaning nutq (tovushlar) kartasi
class SpeechProfile {
  final String studentId;
  final List<SoundProgress> sounds; // guruh va tovush tartibida

  const SpeechProfile(this.studentId, this.sounds);

  List<SoundProgress> get mastered =>
      sounds.where((s) => s.isMastered).toList();
  List<SoundProgress> get inProgress =>
      sounds.where((s) => !s.isMastered).toList();

  int countAt(SoundStage stage) => sounds.where((s) => s.stage == stage).length;

  /// Tuzatilishi kerak bo'lgan, lekin rivojlanmayotgan tovushlar
  List<SoundProgress> get stuck =>
      sounds
          .where(
            (s) =>
                s.dynamics.status == DynamicsStatus.ineffective ||
                s.dynamics.status == DynamicsStatus.decline,
          )
          .toList();
}

/// Tovushlar kartasi mantiqi: kiritilgan qaydni tekshirish, profil, keyingi qadam.
class SoundTrackerService {
  static final SoundTrackerService _instance = SoundTrackerService._internal();
  factory SoundTrackerService() => _instance;
  SoundTrackerService._internal();

  final _dynamics = DynamicsService();

  /// Qayd to'g'riligini tekshiradi. Xato bo'lsa — foydalanuvchiga ko'rsatiladigan xabar.
  String? validate(SoundEntry e, DateTime now) {
    if (UzbekSpeechSounds.byId(e.soundId) == null) {
      return 'Noma’lum tovush: ${e.soundId}';
    }
    if (e.recordedAt.isAfter(now.add(const Duration(minutes: 5)))) {
      return 'Qayd sanasi kelajakda bo‘lishi mumkin emas.';
    }
    if (e.disorder == SoundDisorder.substitution) {
      final w = e.substitutedWith;
      if (w == null || UzbekSpeechSounds.byId(w) == null) {
        return 'Tovush qaysi tovushga almashtirilishini ko‘rsating.';
      }
      if (w == e.soundId) {
        return 'Tovush o‘zi bilan almashtirilishi mumkin emas.';
      }
    }
    final from = e.differentiatedFrom;
    if (from != null) {
      if (UzbekSpeechSounds.byId(from) == null) return 'Noma’lum tovush: $from';
      if (from == e.soundId) return 'Tovushni o‘zidan farqlab bo‘lmaydi.';
    }
    if (e.stage.isMastered && e.disorder != SoundDisorder.none) {
      return 'Erkin nutqda to‘g‘ri talaffuz qilinayotgan tovushda buzilish bo‘lmaydi.';
    }
    return null;
  }

  SpeechProfile buildProfile(String studentId, List<SoundEntry> entries) {
    final bySound = <String, List<SoundEntry>>{};
    for (final e in entries.where((e) => e.studentId == studentId)) {
      bySound.putIfAbsent(e.soundId, () => []).add(e);
    }
    final order = {
      for (var i = 0; i < UzbekSpeechSounds.all.length; i++)
        UzbekSpeechSounds.all[i].id: i,
    };
    final sounds =
        bySound.entries.where((e) => UzbekSpeechSounds.byId(e.key) != null).map(
            (e) {
              final history = [...e.value]
                ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
              return SoundProgress(
                sound: UzbekSpeechSounds.byId(e.key)!,
                history: history,
                dynamics: stageDynamics(history),
              );
            },
          ).toList()
          ..sort((a, b) => order[a.sound.id]!.compareTo(order[b.sound.id]!));
    return SpeechProfile(studentId, sounds);
  }

  /// Bosqichlar dinamikasi: bir bosqich o'zgarishi sezilarli hisoblanadi.
  /// Bir bosqichda 3 qayd va 30+ kun turib qolsa — "Samarasiz natija".
  /// Erkin nutqqa yetgan tovush o'zgarmasa — bu yutuq, "Barqaror holat".
  DynamicsResult stageDynamics(List<SoundEntry> history) {
    final points =
        history
            .map((e) => DataPoint(e.recordedAt, e.stage.index.toDouble()))
            .toList();
    final r = _dynamics.evaluate(
      points,
      absoluteThreshold: 0.5,
      unit: 'bosqich',
    );
    if (history.isNotEmpty &&
        history.last.stage.isMastered &&
        r.status == DynamicsStatus.ineffective) {
      return DynamicsResult(
        status: DynamicsStatus.stable,
        series: r.series,
        previous: r.previous,
        latest: r.latest,
        reason: 'Tovush erkin nutqda barqaror to‘g‘ri talaffuz qilinmoqda.',
      );
    }
    return r;
  }

  /// Keyingi qadam bo'yicha tavsiya (logoped qaror qiladi)
  String nextStep(SoundProgress p) {
    final next = p.stage.next;
    if (next == null) {
      return '${p.sound.display} tovushi erkin nutqda to‘g‘ri — nazorat qilib boring.';
    }
    if (next == SoundStage.differentiation && p.sound.confusedWith.isNotEmpty) {
      return 'Keyingi bosqich: ${next.label} — ${p.sound.display} tovushini '
          '${p.sound.confusedWith.join(', ')} tovush(lar)idan farqlash.';
    }
    return 'Keyingi bosqich: ${next.label}.';
  }
}
