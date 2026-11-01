import '../../models/speech_sound_model.dart';

/// O'zbek tili tovushlari: logopedik guruhlar va ko'p uchraydigan aralashtirish juftlari.
class UzbekSpeechSounds {
  static const all = <SpeechSound>[
    // Unlilar
    SpeechSound('a', 'a', SoundGroup.vowel),
    SpeechSound('o', 'o', SoundGroup.vowel, confusedWith: ['o‘']),
    SpeechSound('u', 'u', SoundGroup.vowel, confusedWith: ['o‘']),
    SpeechSound('e', 'e', SoundGroup.vowel, confusedWith: ['i']),
    SpeechSound('i', 'i', SoundGroup.vowel, confusedWith: ['e']),
    SpeechSound('o‘', 'o‘', SoundGroup.vowel, confusedWith: ['u', 'o']),

    // Hushtaksimon
    SpeechSound('s', 's', SoundGroup.whistling, confusedWith: ['sh', 'z']),
    SpeechSound('z', 'z', SoundGroup.whistling, confusedWith: ['s', 'j']),

    // Shivillovchi
    SpeechSound('sh', 'sh', SoundGroup.hissing, confusedWith: ['s', 'ch', 'j']),
    SpeechSound('j', 'j', SoundGroup.hissing, confusedWith: ['z', 'sh']),
    SpeechSound('ch', 'ch', SoundGroup.hissing, confusedWith: ['sh', 's']),

    // Sonor
    SpeechSound('r', 'r', SoundGroup.sonorant, confusedWith: ['l', 'y']),
    SpeechSound('l', 'l', SoundGroup.sonorant, confusedWith: ['r', 'y']),

    // Til orqa
    SpeechSound('k', 'k', SoundGroup.backLingual, confusedWith: ['q', 't', 'g']),
    SpeechSound('g', 'g', SoundGroup.backLingual, confusedWith: ['g‘', 'd', 'k']),
    SpeechSound('q', 'q', SoundGroup.backLingual, confusedWith: ['k', 'g‘']),
    SpeechSound('g‘', 'g‘', SoundGroup.backLingual, confusedWith: ['g', 'q']),
    SpeechSound('x', 'x', SoundGroup.backLingual, confusedWith: ['h', 'q']),
    SpeechSound('h', 'h', SoundGroup.backLingual, confusedWith: ['x']),

    // Boshqa undoshlar
    SpeechSound('b', 'b', SoundGroup.other, confusedWith: ['p']),
    SpeechSound('p', 'p', SoundGroup.other, confusedWith: ['b']),
    SpeechSound('d', 'd', SoundGroup.other, confusedWith: ['t']),
    SpeechSound('t', 't', SoundGroup.other, confusedWith: ['d', 'k']),
    SpeechSound('v', 'v', SoundGroup.other, confusedWith: ['f']),
    SpeechSound('f', 'f', SoundGroup.other, confusedWith: ['v', 'p']),
    SpeechSound('m', 'm', SoundGroup.other),
    SpeechSound('n', 'n', SoundGroup.other, confusedWith: ['ng']),
    SpeechSound('ng', 'ng', SoundGroup.other, confusedWith: ['n']),
    SpeechSound('y', 'y', SoundGroup.other, confusedWith: ['l']),
  ];

  static SpeechSound? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }

  static List<SpeechSound> inGroup(SoundGroup g) =>
      all.where((s) => s.group == g).toList();
}
