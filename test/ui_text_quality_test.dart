import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:talim_nazorat/models/user_model.dart';

/// Ekranlardagi matn sifati: takroriy lavozim, texnik kodlar, asossiz da'volar, soxta qiymatlar.
void main() {
  UserModel user(UserRole role, String? spec) =>
      UserModel(id: 'u', email: 'u@talim.uz', fullName: 'U', role: role, specialization: spec);

  group('Role title is never duplicated', () {
    test('same text is shown once', () {
      expect(user(UserRole.speechTherapist, 'Logoped-defektolog').roleTitle, 'Logoped-defektolog');
      expect(user(UserRole.specialEducation, 'Maxsus pedagog / Defektolog').roleTitle,
          'Maxsus pedagog (Defektolog)');
    });

    test('the more specific title wins when one contains the other', () {
      expect(user(UserRole.psychologist, 'Bolalar amaliyotchi psixologi').roleTitle,
          'Bolalar amaliyotchi psixologi');
    });

    test('different texts are both shown; empty specialization shows the role', () {
      expect(user(UserRole.coordinator, 'ITR eksperti').roleTitle,
          '${UserRole.coordinator.label} • ITR eksperti');
      expect(user(UserRole.teacher, null).roleTitle, UserRole.teacher.label);
      expect(user(UserRole.teacher, '  ').roleTitle, UserRole.teacher.label);
    });
  });

  group('Screens contain no technical or misleading text', () {
    final screens = Directory('lib/screens')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => (f.path, f.readAsStringSync()))
        .toList();

    void expectNone(Pattern pattern, String what) {
      final hits = [
        for (final (path, text) in screens)
          if (text.contains(pattern)) path,
      ];
      expect(hits, isEmpty, reason: '$what topildi: $hits');
    }

    test('no internal rule codes shown to users', () {
      expectNone(RegExp(r"\$\{\w+\.ruleCode\}"), 'Monitoring qoidasi kodi');
    });

    test('no unverified "100% compliant" claims or wrong law names', () {
      expectNone('100% muvofiq', '"100% muvofiq" da’vosi');
      expectNone('Psixologik yordam ko‘rsatish to‘g‘risida', 'Noto‘g‘ri qonun nomi');
    });

    test('no fake fallback people, phones or schools', () {
      expectNone(RegExp(r"\?\? '[^']*(Usmonova|Dilnoza)"), 'Soxta mutaxassis ismi');
      expectNone(RegExp(r"\?\? '\+998 9\d 000"), 'Soxta telefon raqami');
      expectNone(RegExp(r"\?\? '\d+-sonli"), 'Soxta maktab nomi');
      expectNone('inst_tashkent_14', 'Qattiq yozilgan maktab');
    });

    test('no hard-coded demo password in screens', () {
      expectNone('Parol2026!', 'Namunaviy parol');
    });

    test('Uzbek suffixes are not split from ITR', () {
      expectNone(RegExp(r"ITR (ga|da|dagi|ning|ni)\b"), 'Ajratib yozilgan qo‘shimcha');
    });
  });
}
