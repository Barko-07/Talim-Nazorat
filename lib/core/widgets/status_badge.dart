import 'package:flutter/material.dart';

import '../../services/child_status_service.dart';
import '../constants/app_colors.dart';

/// Holat rangi. Qizil / Sariq / Yashil ma'nosi o'quvchilar filtridagi bilan bir xil.
enum StatusTone { success, warning, danger, info, primary, neutral }

extension StatusToneColor on StatusTone {
  Color get color {
    switch (this) {
      case StatusTone.success:
        return AppColors.success;
      case StatusTone.warning:
        return AppColors.warning;
      case StatusTone.danger:
        return AppColors.error;
      case StatusTone.info:
        return AppColors.info;
      case StatusTone.primary:
        return AppColors.primary;
      case StatusTone.neutral:
        return AppColors.textMuted;
    }
  }

  static StatusTone of(StatusColor c) {
    switch (c) {
      case StatusColor.red:
        return StatusTone.danger;
      case StatusColor.yellow:
        return StatusTone.warning;
      case StatusColor.green:
        return StatusTone.success;
    }
  }
}

/// Ixcham holat belgisi — Profil sahifasidagi "Faol" belgisi uslubida: to'liq
/// yumaloq, to'q rangli fon, 12px yarim qalin yozuv. Barcha holatlar (Faol,
/// Faol emas, Bloklangan, Qizil, Sariq, Yashil va h.k.) shu bitta ko'rinishda.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusTone tone;
  final IconData? icon;

  const StatusBadge(
    this.label, {
    super.key,
    this.tone = StatusTone.neutral,
    this.icon,
  });

  /// O'quvchining Qizil / Sariq / Yashil holati.
  factory StatusBadge.child(StatusColor c, String label, {Key? key}) =>
      StatusBadge(label, key: key, tone: StatusToneColor.of(c));

  /// Hisob faolligi: "Faol" yoki boshqa (masalan "Bloklangan", "Faol emas").
  factory StatusBadge.active(
    bool active, {
    String inactiveLabel = 'Faol emas',
    Key? key,
  }) => StatusBadge(
    active ? 'Faol' : inactiveLabel,
    key: key,
    tone: active ? StatusTone.success : StatusTone.neutral,
  );

  @override
  Widget build(BuildContext context) {
    final bg = tone.color;
    // Qorong'i mavzuda urg'u ranglari och — ularda to'q yozuv o'qiladi.
    final fg = AppColors.isDark ? const Color(0xFF0E1116) : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              softWrap: true,
              style: TextStyle(
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
