// Administrator paroli uchun PBKDF2 xesh yaratadi (ochiq parol hech qayerga yozilmaydi).
//
//   dart run tool/hash_password.dart
//
// Natijani yig'ishda bering: --dart-define=ADMIN_PASSWORD_HASH='<natija>'
import 'dart:io';

import 'package:talim_nazorat/services/password_hasher.dart';

void main() {
  stdout.write('Administrator paroli (kamida 12 belgi): ');
  stdin.echoMode = false;
  final password = stdin.readLineSync() ?? '';
  stdin.echoMode = true;
  stdout.writeln();

  final problems = <String>[
    if (password.length < 12) 'kamida 12 belgi',
    if (!RegExp(r'[A-Z]').hasMatch(password)) 'katta harf',
    if (!RegExp(r'[a-z]').hasMatch(password)) 'kichik harf',
    if (!RegExp(r'\d').hasMatch(password)) 'raqam',
  ];
  if (problems.isNotEmpty) {
    stderr.writeln('Parol yetarlicha kuchli emas. Kerak: ${problems.join(', ')}.');
    exit(1);
  }
  stdout.writeln(PasswordHasher.hash(password));
}
