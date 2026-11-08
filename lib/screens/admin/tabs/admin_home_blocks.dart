import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';

// Administrator bosh sahifasining bloklari: salomlashuv, holat banneri,
// rangli ko'rsatkich plitkalari, "Bolalar holati" kartasi va bo'limlar.
// Ranglar AppColors orqali — qorong'i rejimda ham to'g'ri chiqadi.

/// Ko'rsatkich plitkasining rangi (fon, ikona plitkasi).
enum AdminTone { blue, green, purple, orange }

extension AdminToneColors on AdminTone {
  Color get color => switch (this) {
    AdminTone.blue => AppColors.primary,
    AdminTone.green => AppColors.success,
    AdminTone.purple => AppColors.purple,
    AdminTone.orange => AppColors.warning,
  };

  Color get background => switch (this) {
    AdminTone.blue => AppColors.infoBg,
    AdminTone.green => AppColors.successBg,
    AdminTone.purple => AppColors.purpleBg,
    AdminTone.orange => AppColors.warningBg,
  };
}

/// Yengil soya — admin kartalarining hammasida bir xil.
List<BoxShadow> adminCardShadow() => [
  BoxShadow(
    color: Colors.black.withValues(alpha: AppColors.isDark ? 0.25 : 0.05),
    blurRadius: 18,
    offset: const Offset(0, 6),
  ),
];

/// Burchakdagi yashil-ko'k to'lqin — logodagi barg shaklidan.
class _LeafSwoosh extends CustomPainter {
  const _LeafSwoosh({required this.opacity, this.white = false});

  final double opacity;
  final bool white;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path =
        Path()
          ..moveTo(size.width, size.height * 0.05)
          ..quadraticBezierTo(
            size.width * 0.15,
            size.height * 0.1,
            size.width * 0.05,
            size.height,
          )
          ..lineTo(size.width, size.height)
          ..close();
    final paint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors:
                white
                    ? [
                      Colors.white.withValues(alpha: opacity * 0.22),
                      Colors.white.withValues(alpha: opacity * 0.1),
                      Colors.white.withValues(alpha: 0),
                    ]
                    : [
                      AppColors.brandGreen.withValues(alpha: opacity),
                      AppColors.brandTeal.withValues(alpha: opacity * 0.5),
                      AppColors.brandBlueBright.withValues(alpha: 0),
                    ],
          ).createShader(rect);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LeafSwoosh old) =>
      old.opacity != opacity || old.white != white;
}

/// "Xush kelibsiz," va administrator ismi, ostida roli va hududi.
class AdminWelcome extends StatelessWidget {
  const AdminWelcome({super.key, required this.user, required this.scope});

  final UserModel? user;

  /// "Namangan viloyati" yoki muassasa nomi.
  final String scope;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: -24,
          top: -12,
          child: IgnorePointer(
            child: SizedBox(
              width: 130,
              height: 84,
              child: CustomPaint(painter: _LeafSwoosh(opacity: 0.35)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xush kelibsiz,',
                style: TextStyle(fontSize: 15.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                user?.fullName ?? 'Administrator',
                style: TextStyle(
                  fontSize: 26,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${user?.role.label ?? 'Tizim administratori'} · $scope',
                style: TextStyle(fontSize: 14.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bugungi eng muhim holat. Hammasi joyida bo'lsa — ko'k banner "Hammasi
/// nazoratda"; diqqat talab bo'lsa — to'q sariq yoki qizil, "Ko'rish" bilan.
class AdminAttentionCard extends StatelessWidget {
  const AdminAttentionCard({
    super.key,
    required this.unworked,
    required this.pendingReferrals,
    required this.incompleteAssessments,
    required this.onOpen,
  });

  final int unworked;
  final int pendingReferrals;
  final int incompleteAssessments;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (unworked > 0) '$unworked nafar bola bilan 30 kundan beri ishlanmagan',
      if (pendingReferrals > 0)
        '$pendingReferrals ta yo‘naltirish javob kutmoqda',
      if (incompleteAssessments > 0)
        '$incompleteAssessments ta baholash tugallanmagan',
    ];
    final urgent = unworked > 0;
    final calm = parts.isEmpty;
    final colors =
        calm
            ? const [AppColors.brandBlueBright, AppColors.brandBlueDeep]
            : urgent
            ? const [Color(0xFFE5484D), Color(0xFFB4232A)]
            : const [Color(0xFFF59E0B), Color(0xFFD97706)];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -6,
            child: IgnorePointer(
              child: SizedBox(
                width: 130,
                height: 70,
                child: CustomPaint(
                  painter: _LeafSwoosh(opacity: 0.9, white: !calm),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    calm ? LucideIcons.shieldCheck : LucideIcons.triangleAlert,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        calm ? 'Hammasi nazoratda' : 'Diqqat talab',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        calm
                            ? 'Kechikkan ish, javobsiz yo‘naltirish yoki tugallanmagan baholash yo‘q.'
                            : '${parts.join('. ')}.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      if (!calm) ...[
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: onOpen,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: colors.last,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Ko‘rish'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminMetric {
  const AdminMetric(
    this.label,
    this.value,
    this.unit, {
    required this.icon,
    required this.tone,
    this.alert = false,
    this.onTap,
  });

  final String label;
  final int value;
  final String unit;
  final IconData icon;
  final AdminTone tone;

  /// Noldan katta bo'lsa — qiymat xato rangida (masalan ishlanmagan bolalar).
  final bool alert;
  final VoidCallback? onTap;
}

/// Ko'rsatkichlar: har biri o'z rangidagi plitka — ikona, nom, qiymat va
/// o'q. Telefonda 2 ta, keng ekranda 3 ta ustun.
class AdminMetricsCard extends StatelessWidget {
  const AdminMetricsCard({super.key, required this.metrics});

  final List<AdminMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 900 ? 3 : 2;
        const gap = 12.0;
        final w = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final m in metrics) SizedBox(width: w, child: _tile(m)),
          ],
        );
      },
    );
  }

  Widget _tile(AdminMetric m) {
    final valueColor =
        m.alert && m.value > 0 ? AppColors.error : AppColors.textPrimary;
    final radius = BorderRadius.circular(18);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: adminCardShadow(),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: m.onTap,
          child: Ink(
            padding: const EdgeInsets.fromLTRB(12, 14, 8, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  m.tone.background,
                  Color.lerp(m.tone.background, AppColors.surface, 0.55)!,
                ],
              ),
              borderRadius: radius,
              border: Border.all(
                color: AppColors.surface.withValues(alpha: 0.8),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: m.tone.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(m.icon, size: 19, color: m.tone.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${m.value}',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: valueColor,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  TextSpan(
                                    text: '  ${m.unit}',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (m.onTap != null)
                            Icon(
                              LucideIcons.chevronRight,
                              size: 20,
                              color: AppColors.textPrimary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Oq karta — "Bolalar holati" va boshqa bloklar uchun umumiy asos.
class AdminPanelCard extends StatelessWidget {
  const AdminPanelCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: adminCardShadow(),
      ),
      child: child,
    );
  }
}

/// Qizil / Sariq / Yashil belgisi: och fon, rangli nuqta va son.
class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip(this.label, this.color, this.background, {super.key});

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Karta ichidagi havola qatori: ikona plitkasi, matn va o'q.
class AdminLinkRow extends StatelessWidget {
  const AdminLinkRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class AdminSection {
  const AdminSection(this.title, this.icon, this.onTap);

  final String title;
  final IconData icon;
  final VoidCallback onTap;
}

/// Bo'limlar to'ri: ikona plitkasi, nom va o'q; telefonda 2, kengda 4 ustun.
class AdminSectionsGrid extends StatelessWidget {
  const AdminSectionsGrid({super.key, required this.sections});

  final List<AdminSection> sections;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 900 ? 4 : 2;
        const gap = 12.0;
        final w = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final s in sections) SizedBox(width: w, child: _tile(s)),
          ],
        );
      },
    );
  }

  Widget _tile(AdminSection s) {
    final radius = BorderRadius.circular(18);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: adminCardShadow(),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: s.onTap,
          child: Ink(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: radius,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(s.icon, size: 19, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bo'lim sarlavhasi: katta va qalin, ixtiyoriy o'ng tomondagi havola bilan.
class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle(this.text, {super.key, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}
