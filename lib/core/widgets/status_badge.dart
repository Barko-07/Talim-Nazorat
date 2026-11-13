import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/child_status_service.dart';
import '../../services/dynamics_service.dart';
import '../constants/app_colors.dart';
import 'glass_widgets.dart' show StatusDotLabel;

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
    // Qizil/sariq/yashil: rangli nuqta, matn neytral.
    final dot = AppColors.statusDotFor(tone.color);
    if (dot != null) return StatusDotLabel(label: label, dotColor: dot);
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

/// Bolaning holati (svetofor) — hamma sahifada bir xil: kichik rangli nuqta va
/// qisqa nom ("Ishlanmagan", "E’tibor kerak", "Ijobiy"). Rang faqat nuqtada,
/// matn neytral. [reason] berilsa — uning ostida bitta qisqa sabab.
class ChildStatusLabel extends StatelessWidget {
  final StatusColor status;
  final String? reason;
  final CrossAxisAlignment align;

  const ChildStatusLabel(
    this.status, {
    super.key,
    this.reason,
    this.align = CrossAxisAlignment.start,
  });

  static Color dotColor(StatusColor c) => switch (c) {
    StatusColor.red => AppColors.dotRed,
    StatusColor.yellow => AppColors.dotAmber,
    StatusColor.green => AppColors.dotGreen,
  };

  @override
  Widget build(BuildContext context) {
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor(status),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          status.short,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
    if (reason == null || reason!.isEmpty) return label;
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        label,
        const SizedBox(height: 2),
        Text(
          reason!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// Natija o'zgarishi (dinamika) — svetofor nuqtasidan farqli, yo'nalish
/// ikonkasi bilan: O'sish ↗, Pasayish ↘, Barqaror →, Samarasiz ⊖.
class DynamicsIcon extends StatelessWidget {
  final DynamicsStatus status;
  final double size;
  const DynamicsIcon(this.status, {super.key, this.size = 15});

  static IconData iconFor(DynamicsStatus s) => switch (s) {
    DynamicsStatus.growth => LucideIcons.trendingUp,
    DynamicsStatus.decline => LucideIcons.trendingDown,
    DynamicsStatus.stable => LucideIcons.moveRight,
    DynamicsStatus.ineffective => LucideIcons.circleMinus,
    DynamicsStatus.insufficientData => LucideIcons.circleDashed,
  };

  static Color colorFor(DynamicsStatus s) => switch (s) {
    DynamicsStatus.growth => const Color(0xFF1F8A55),
    DynamicsStatus.decline => const Color(0xFFD23C41),
    DynamicsStatus.ineffective => const Color(0xFFB7791F),
    _ => AppColors.textMuted,
  };

  static String shortLabel(DynamicsStatus s) => switch (s) {
    DynamicsStatus.growth => 'O‘sish',
    DynamicsStatus.decline => 'Pasayish',
    DynamicsStatus.stable => 'Barqaror',
    DynamicsStatus.ineffective => 'Samarasiz',
    DynamicsStatus.insufficientData => 'Bitta natija',
  };

  /// AssessmentModel.trend matnidan ("O‘sish" / "Pasayish" / boshqa).
  static DynamicsStatus fromTrend(String t) => switch (t) {
    'O‘sish' => DynamicsStatus.growth,
    'Pasayish' => DynamicsStatus.decline,
    'Barqaror' || 'Barqarorlik' => DynamicsStatus.stable,
    _ => DynamicsStatus.insufficientData,
  };

  @override
  Widget build(BuildContext context) =>
      Icon(iconFor(status), size: size, color: colorFor(status));
}

/// Ikonka + qisqa nom (neytral matn).
class DynamicsLabel extends StatelessWidget {
  final DynamicsStatus status;
  final String? text;
  const DynamicsLabel(this.status, {super.key, this.text});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      DynamicsIcon(status),
      const SizedBox(width: 6),
      Text(
        text ?? DynamicsIcon.shortLabel(status),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    ],
  );
}
