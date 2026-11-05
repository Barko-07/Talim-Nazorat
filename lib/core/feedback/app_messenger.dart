import 'package:flutter/material.dart';

import '../../services/app_exceptions.dart';
import '../constants/app_colors.dart';

/// Ilova bo'ylab bitta xabar chiqaruvchi: hech bir ekran ushlamagan xatolar
/// (masalan internet uzilib, saqlash serverda rad etilsa) ham foydalanuvchiga
/// aniq matn bilan ko'rsatiladi — tugma "jim" qolmaydi.
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showAppError(String message) {
  final messenger = rootMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ),
    );
}

/// [PlatformDispatcher.onError] uchun: ilova xatolari ([AppException]) xabar
/// bo'lib chiqadi; boshqalari odatdagidek qayd etiladi.
bool reportUncaughtError(Object error, StackTrace stack) {
  if (error is AppException) {
    showAppError(error.message);
    return true;
  }
  return false;
}
