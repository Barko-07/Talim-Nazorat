import '../../models/progress_measurement_model.dart';

/// Standart o'lchov ko'rsatkichlari. Mutaxassis o'z ko'rsatkichini ham qo'shishi mumkin.
class ProgressMetrics {
  static const attentionSpan = ProgressMetric(
    id: 'metric_attention_minutes',
    name: 'Diqqatni bir topshiriqda jamlash davomiyligi',
    unit: 'daqiqa',
    domain: 'Diqqat va xotira',
  );
  static const wordsRecalled = ProgressMetric(
    id: 'metric_words_recalled',
    name: '10 ta so‘zdan eslab qolinganlari',
    unit: 'so‘z',
    domain: 'Diqqat va xotira',
  );
  static const independentTasks = ProgressMetric(
    id: 'metric_independent_tasks',
    name: 'Mustaqil bajarilgan topshiriqlar (5 tadan)',
    unit: 'topshiriq',
    domain: 'Xulq-atvor va iroda',
  );
  static const readingSpeed = ProgressMetric(
    id: 'metric_reading_wpm',
    name: 'O‘qish tezligi',
    unit: 'so‘z/daqiqa',
    domain: 'Nutq va muloqot',
  );
  static const meltdownsPerWeek = ProgressMetric(
    id: 'metric_meltdowns_week',
    name: 'Haftasiga hissiy portlashlar soni',
    unit: 'marta',
    domain: 'Emotsional va xavotir',
    higherIsBetter: false,
  );
  static const peerInitiations = ProgressMetric(
    id: 'metric_peer_initiations',
    name: 'Tengdoshlar bilan o‘zi boshlagan muloqotlar (tanaffusda)',
    unit: 'marta',
    domain: 'Ijtimoiy moslashuv va motivatsiya',
  );

  // Logoped
  static const soundsCorrect = ProgressMetric(
    id: 'metric_sounds_correct',
    name: 'To‘g‘ri talaffuz qilinadigan maqsadli tovushlar',
    unit: 'tovush',
    domain: 'Nutq va muloqot',
  );
  static const activeVocabulary = ProgressMetric(
    id: 'metric_active_vocabulary',
    name: 'Faol lug‘at (20 ta rasmdan nomlanganlari)',
    unit: 'so‘z',
    domain: 'Nutq va muloqot',
  );

  // Defektolog
  static const fineMotorBeads = ProgressMetric(
    id: 'metric_fine_motor_beads',
    name: 'Mayda motorika: 1 daqiqada ipga o‘tkazilgan munchoqlar',
    unit: 'dona',
    domain: 'Sensor-motor rivojlanish',
  );
  static const selfCareActions = ProgressMetric(
    id: 'metric_self_care',
    name: 'O‘z-o‘ziga xizmat: mustaqil bajarilgan amallar (10 tadan)',
    unit: 'amal',
    domain: 'Sensor-motor rivojlanish',
  );

  static const all = [
    attentionSpan,
    wordsRecalled,
    independentTasks,
    readingSpeed,
    meltdownsPerWeek,
    peerInitiations,
    soundsCorrect,
    activeVocabulary,
    fineMotorBeads,
    selfCareActions,
  ];
}
