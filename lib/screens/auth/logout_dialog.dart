import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Profildan chiqishdan oldin tasdiq so'raydi. Tasdiqlansa — tizimdan chiqadi va
/// navigatsiya tarixini tozalab, kirish sahifasiga qaytaradi (orqaga tugmasi bilan
/// yopilgan profilga qaytib bo'lmaydi).
Future<void> confirmLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          icon: const Icon(LucideIcons.logOut, color: AppColors.error),
          title: const Text('Profildan chiqish'),
          content: const Text(
            'Profilingizdan chiqib ketishga ishonchingiz komilmi?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ha, chiqish'),
            ),
          ],
        ),
  );
  if (confirmed != true || !context.mounted) return;

  // Ochiq oynalar yopiladi; ildiz oynasi (main.dart) chiqib ketgan foydalanuvchiga
  // saytda landing sahifani, ilovada "Xush kelibsiz" ekranini ko'rsatadi.
  final auth = context.read<AuthProvider>();
  Navigator.of(context).popUntil((route) => route.isFirst);
  await auth.logout();
}
