import 'package:flutter/services.dart';

/// Faqat O'zbekiston telefon raqamlari: +998 va 9 ta raqam (birinchisi 2–9).
/// Server bilan bir xil qoida (server/app/schemas.py `_uz_phone`).
class UzPhone {
  UzPhone._();

  /// Maydon shu bilan boshlanadi; foydalanuvchi faqat 9 ta raqamni teradi.
  static const prefix = '+998 ';
  static const hint = '+998 90 123 45 67';
  static const error = 'Faqat O‘zbekiston raqami: +998 XX XXX XX XX';

  static final _local = RegExp(r'^[2-9][0-9]{8}$');

  /// Kiritilgan matndagi mahalliy raqamlar (998 siz, ko'pi bilan 9 ta).
  static String _localDigits(String input) {
    var d = input.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('998')) d = d.substring(3);
    return d.length > 9 ? d.substring(0, 9) : d;
  }

  /// `+998` dan keyin hech narsa terilmagan.
  static bool isEmpty(String input) => _localDigits(input).isEmpty;

  static bool isValid(String input) => _local.hasMatch(_localDigits(input));

  /// "+998 90 123 45 67" - to'g'ri raqam bo'lsa, aks holda null.
  static String? normalize(String input) =>
      isValid(input) ? _group(_localDigits(input)) : null;

  /// Saqlangan raqam maydonga: to'g'ri bo'lsa chiroyli ko'rinishda, bo'lmasa
  /// bo'sh prefiks (foydalanuvchi qaytadan teradi).
  static String initial(String? stored) =>
      stored == null ? prefix : (normalize(stored) ?? prefix);

  static String _group(String d) {
    final b = StringBuffer(prefix);
    for (var i = 0; i < d.length; i++) {
      if (i == 2 || i == 5 || i == 7) b.write(' ');
      b.write(d[i]);
    }
    return b.toString();
  }

  /// Maydon uchun: "+998 " o'chirilmaydi, faqat raqam, avtomatik guruhlanadi.
  static final TextInputFormatter formatter = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    final text = _group(_localDigits(newValue.text));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  });
}
