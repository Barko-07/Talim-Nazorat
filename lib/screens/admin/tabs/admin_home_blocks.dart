import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../models/user_model.dart';

// Administrator bosh sahifasining bloklari — mutaxassislar ilovasining bosh
// sahifasi bilan bir xil uslubda (SurfaceCard, StatusPill, ikonali KPI).

String _initials(String? fullName) {
  final parts =
      (fullName ?? '')
          .trim()
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
  if (parts.isEmpty) return 'A';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

/// Profil kartasi: monogramma, "Xush kelibsiz" va ism, rol belgisi, hudud.
class AdminWelcome extends StatelessWidget {
  const AdminWelcome({super.key, required this.user, required this.scope});

  final UserModel? user;

  /// "Namangan viloyati" yoki muassasa nomi.
  final String scope;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryTint),
            ),
            child: Text(
              _initials(user?.fullName),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Xush kelibsiz',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      user?.fullName ?? 'Administrator',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    StatusPill(
                      label: user?.role.label ?? 'Tizim administratori',
                      color: AppColors.primary,
                      backgroundColor: AppColors.primaryLight,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  scope,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
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

/// Bugungi eng muhim holat. Muammo bo'lsa — sariq (yoki qizil) karta va
/// "Monitoringni ko'rish"; hammasi joyida bo'lsa — sokin yashil belgi.
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
    final calm = parts.isEmpty;
    final urgent = unworked > 0;
    final tone =
        calm
            ? AppColors.success
            : (urgent ? AppColors.error : AppColors.warning);

    return SurfaceCard(
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      backgroundColor:
          calm
              ? AppColors.surface
              : (urgent ? AppColors.errorBg : AppColors.warningBg),
      borderColor:
          calm
              ? AppColors.border
              : (urgent ? AppColors.errorBorder : AppColors.warningBorder),
      onTap: calm ? null : onOpen,
      child: LayoutBuilder(
        builder: (context, c) {
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                calm ? 'Hammasi nazoratda' : 'Diqqat talab',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                calm
                    ? 'Kechikkan ish, javobsiz yo‘naltirish yoki tugallanmagan baholash yo‘q.'
                    : '${parts.join('. ')}.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
          final icon = Icon(
            calm ? LucideIcons.circleCheck : LucideIcons.triangleAlert,
            color: tone,
            size: 21,
          );
          final pill = StatusPill(
            label: 'Monitoringni ko‘rish',
            color: tone,
            backgroundColor: AppColors.surface,
            icon: LucideIcons.arrowUpRight,
          );
          if (c.maxWidth < 430) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: icon,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: text),
                  ],
                ),
                if (!calm) ...[const SizedBox(height: 10), pill],
              ],
            );
          }
          return Row(
            children: [
              icon,
              const SizedBox(width: 14),
              Expanded(child: text),
              if (!calm) ...[const SizedBox(width: 12), pill],
            ],
          );
        },
      ),
    );
  }
}

class AdminMetric {
  const AdminMetric(
    this.label,
    this.value,
    this.unit, {
    this.icon = LucideIcons.chartColumn,
    this.color,
    this.caption = '',
    this.alert = false,
    this.onTap,
  });

  final String label;
  final int value;
  final String unit;
  final IconData icon;
  final Color? color;

  /// Qiymat ostidagi qisqa izoh (masalan "Inklyuziv ro'yxatda").
  final String caption;

  /// Noldan katta bo'lsa — qiymat xato rangida (masalan ishlanmagan bolalar).
  final bool alert;
  final VoidCallback? onTap;
}

/// Ko'rsatkichlar: mutaxassislar bosh sahifasidagi KPI kartalari kabi —
/// nom, o'ng burchakda rangli ikona, katta qiymat va izoh.
class AdminMetricsCard extends StatelessWidget {
  const AdminMetricsCard({super.key, required this.metrics});

  final List<AdminMetric> metrics;

  @override
  Widget build(BuildContext context) {
    // Telefonda ikki ustun tor: ichki bo'shliq va ikona kichikroq, so'zlar
    // bo'linmasin.
    final compact = MediaQuery.sizeOf(context).width < 600;
    return ResponsiveGlassGrid(
      mobileColumns: 2,
      tabletColumns: 3,
      desktopColumns: 3,
      spacing: 10,
      children: [for (final m in metrics) _card(m, compact)],
    );
  }

  Widget _card(AdminMetric m, bool compact) {
    final color = m.color ?? AppColors.primary;
    final valueColor =
        m.alert && m.value > 0 ? AppColors.error : AppColors.textPrimary;
    final iconBox = compact ? 30.0 : 36.0;
    return SurfaceCard(
      borderRadius: 16,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 13 : 18,
        vertical: compact ? 14 : 16,
      ),
      onTap: m.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  m.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 12.5 : 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: AppColors.isDark ? 0.20 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(m.icon, color: color, size: compact ? 16 : 19),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${m.value}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.7,
                    color: valueColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                TextSpan(
                  text: ' ${m.unit}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (m.caption.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              m.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AdminSection {
  const AdminSection(
    this.title,
    this.icon,
    this.onTap, {
    this.description = '',
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String description;
}

/// Bo'limlar — my.gov.uz xizmatlar to'ri kabi: ikona, nom, qisqa izoh va
/// o'q (mutaxassislar ilovasidagi "ish maydoni" plitkalari uslubida).
class AdminSectionsGrid extends StatelessWidget {
  const AdminSectionsGrid({super.key, required this.sections});

  final List<AdminSection> sections;

  @override
  Widget build(BuildContext context) {
    return ResponsiveGlassGrid(
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: 3,
      spacing: 10,
      children: [for (final s in sections) _tile(s)],
    );
  }

  Widget _tile(AdminSection s) {
    return SurfaceCard(
      elevated: false,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      backgroundColor: AppColors.glassWellFill,
      borderColor: AppColors.glassInnerBorder,
      onTap: s.onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(s.icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (s.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    s.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.textSubtle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bo'lim sarlavhasi (mutaxassislar ilovasidagi karta sarlavhalari kabi).
class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle(this.text, {super.key, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (action != null)
            InkWell(
              onTap: onAction,
              child: Text(
                '$action →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
