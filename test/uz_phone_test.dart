import 'package:flutter_test/flutter_test.dart';
import 'package:talim_nazorat/core/utils/uz_phone.dart';

void main() {
  test('only Uzbek numbers, stored one way', () {
    expect(UzPhone.normalize('+998 90 123 45 67'), '+998 90 123 45 67');
    expect(UzPhone.normalize('901234567'), '+998 90 123 45 67');
    // full number typed into a field that already shows "+998 "
    expect(UzPhone.normalize('+998 +998 90 123 45 67'), '+998 90 123 45 67');
    expect(UzPhone.isValid('+7 912 345 67 89'), isFalse);
    expect(UzPhone.isValid('+998 01 234 56 78'), isFalse);
    expect(UzPhone.isEmpty('+998 '), isTrue);
  });
}
