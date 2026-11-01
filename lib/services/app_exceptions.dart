/// Backend xatolari. UI `e.toString()` ni to'g'ridan-to'g'ri foydalanuvchiga ko'rsatishi mumkin —
/// xabarlar o'zbek tilida va texnik tafsilotsiz.
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Foydalanuvchining bu amalni bajarishga huquqi yo'q
class PermissionDeniedException extends AppException {
  const PermissionDeniedException(String reason)
    : super('Ruxsat cheklangan: $reason');
}

/// So'ralgan yozuv topilmadi
class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

/// Kiritilgan ma'lumot noto'g'ri yoki to'liq emas
class ValidationException extends AppException {
  const ValidationException(super.message);
}
