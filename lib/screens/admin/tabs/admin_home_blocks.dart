import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';

// Administrator bosh sahifasining yuqori qismi — my.gov.uz ilovasi uslubida:
// salomlashuv va ism, eng muhim topilma, bitta bo'lingan ko'rsatkichlar
// kartasi va "Sohalar" plitkalari kabi bo'limlar to'ri. Rang faqat holat
// va asosiy amalda; ikonalar bitta rangdagi chiziqli Lucide.

/// "Xush kelibsiz" va administrator ismi, ostida roli va hududi.
class AdminWelcome extends StatelessWidget {
  const AdminWelcome({super.key, required this.user, required this.scope});

  final UserModel? user;

  /// "Namangan viloyati" yoki muassasa nomi.
  final String scope;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xush kelibsiz',
          style: TextStyle(fontSize: 15.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          user?.fullName ?? 'Administrator',
          style: TextStyle(
            fontSize: 24,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${user?.role.label ?? 'Tizim administratori'} · $scope',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Bugungi eng muhim fakt va uni hal qiladigan bitta amal. Hammasi joyida
/// bo'lsa, buni ochiq aytadi (yashil emas, sokin matn bilan).
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color:
            calm
                ? AppColors.surface
                : (urgent ? AppColors.errorBg : AppColors.warningBg),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              calm
                  ? AppColors.border
                  : (urgent ? AppColors.errorBorder : AppColors.warningBorder),
        ),
      ),
      child: Row(
        children: [
          Icon(
            calm ? LucideIcons.circleCheck : LucideIcons.triangleAlert,
            size: 22,
            color:
                calm
                    ? AppColors.success
                    : (urgent ? AppColors.error : AppColors.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  calm ? 'Hammasi nazoratda' : 'Diqqat talab',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  calm
                      ? 'Kechikkan ish, javobsiz yo‘naltirish yoki tugallanmagan baholash yo‘q.'
                      : parts.join('. '),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!calm) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onOpen, child: const Text('Ko‘rish')),
          ],
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
    this.alert = false,
    this.onTap,
  });

  final String label;
  final int value;
  final String unit;

  /// Noldan katta bo'lsa — qiymat xato rangida (masalan ishlanmagan bolalar).
  final bool alert;
  final VoidCallback? onTap;
}

/// Bitta karta, ichi ingichka chiziqlar bilan teng kataklarga bo'lingan:
/// yorliq tepada kulrang, qiymat ostida. Ikona va rangli plitka yo'q.
class AdminMetricsCard extends StatelessWidget {
  const AdminMetricsCard({super.key, required this.metrics});

  final List<AdminMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 900 ? 3 : 2;
        // Kataklar qatorlab, har qator eng baland katak bo'yicha teng —
        // ikki qatorli yorliq ajratuvchi chiziqlarni uzmasin.
        final rows = <List<AdminMetric>>[
          for (var i = 0; i < metrics.length; i += columns)
            metrics.sublist(i, (i + columns).clamp(0, metrics.length)),
        ];
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (var r = 0; r < rows.length; r++)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < columns; i++)
                        Expanded(
                          child:
                              i < rows[r].length
                                  ? _cell(
                                    rows[r][i],
                                    rightRule: i != columns - 1,
                                    bottomRule: r != rows.length - 1,
                                  )
                                  : const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _cell(
    AdminMetric m, {
    required bool rightRule,
    required bool bottomRule,
  }) {
    final valueColor =
        m.alert && m.value > 0 ? AppColors.error : AppColors.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: m.onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            border: Border(
              right:
                  rightRule
                      ? BorderSide(color: AppColors.borderLight)
                      : BorderSide.none,
              bottom:
                  bottomRule
                      ? BorderSide(color: AppColors.borderLight)
                      : BorderSide.none,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.label,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${m.value}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: valueColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    TextSpan(
                      text: ' ${m.unit}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

/// Bo'limlar to'ri — my.gov.uz "Sohalar" plitkalari kabi: chapda nom,
/// o'ngda chiziqli ikona; telefonda 2 ta, kengroq ekranda 4 ta ustun.
class AdminSectionsGrid extends StatelessWidget {
  const AdminSectionsGrid({super.key, required this.sections});

  final List<AdminSection> sections;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 900 ? 4 : 2;
        const gap = 10.0;
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
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: s.onTap,
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.title,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(s.icon, size: 26, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bo'lim sarlavhasi: 17/600, ixtiyoriy o'ng tomondagi havola bilan.
class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle(this.text, {super.key, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
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
