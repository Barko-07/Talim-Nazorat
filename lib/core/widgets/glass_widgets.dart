import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Sokin va minimalistik orqa fon nuri (Frosted Glass qatlamlari jonli ko'rinishi uchun)
class AmbientMeshBackground extends StatelessWidget {
  final Widget child;
  final bool intense;

  const AmbientMeshBackground({
    super.key,
    required this.child,
    this.intense = false,
  });

  @override
  Widget build(BuildContext context) {
    final topAlpha = intense ? 0.085 : 0.045;
    final bottomAlpha = intense ? 0.065 : 0.035;

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        Positioned(
          top: -140,
          right: -100,
          child: IgnorePointer(
            child: Container(
              width: 440,
              height: 440,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: topAlpha),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -160,
          left: -120,
          child: IgnorePointer(
            child: Container(
              width: 480,
              height: 480,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.info.withValues(alpha: bottomAlpha),
                    AppColors.info.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Haqiqiy Apple/Linear uslubidagi Frosted Glass konteyneri
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color? tintColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final bool useBlur;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 18,
    this.blur = 18,
    this.opacity = 0.78,
    this.tintColor,
    this.borderColor,
    this.boxShadow,
    this.useBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = tintColor ?? Colors.white;
    final radius = BorderRadius.circular(borderRadius);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.withValues(alpha: (opacity + 0.08).clamp(0.0, 1.0)),
            baseColor.withValues(alpha: (opacity - 0.04).clamp(0.0, 1.0)),
          ],
        ),
        border: Border.all(
          color: borderColor ?? AppColors.hairlineBorder,
          width: 1,
        ),
      ),
      child: child,
    );

    if (useBlur && blur > 0) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: boxShadow ?? AppColors.softShadow,
      ),
      child: content,
    );
  }
}

/// Bosilganda va sichqoncha borganda mayin taktil javob qaytaruvchi karta (0.985 scale, 140ms easeOutCubic)
class SurfaceCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool elevated;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.elevated = true,
  });

  @override
  State<SurfaceCard> createState() => _SurfaceCardState();
}

class _SurfaceCardState extends State<SurfaceCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    final radius = BorderRadius.circular(widget.borderRadius);

    final effectiveBorderColor = widget.borderColor ??
        (_hovered && interactive
            ? AppColors.primary.withValues(alpha: 0.28)
            : AppColors.hairlineBorder);

    Widget cardBody = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.glassFillStrong,
        borderRadius: radius,
        border: Border.all(color: effectiveBorderColor, width: 1),
        boxShadow: widget.elevated
            ? (_hovered && interactive
                ? AppColors.elevatedShadow
                : AppColors.softShadow)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: radius,
          splashColor: AppColors.primary.withValues(alpha: 0.05),
          highlightColor: AppColors.primary.withValues(alpha: 0.03),
          onHighlightChanged: interactive
              ? (value) => setState(() => _pressed = value)
              : null,
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
    );

    if (!interactive) return cardBody;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _pressed ? 0.986 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: cardBody,
      ),
    );
  }
}

/// Keng monitorlarda kontentni o'rtaga tekislab, iPhone'da ideal hoshiya beruvchi konteyner
class ResponsivePageContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsivePageContainer({
    super.key,
    required this.child,
    this.maxWidth = 1240,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 600
        ? 16.0
        : width < 1024
            ? 22.0
            : 28.0;
    final vertical = width < 600 ? 16.0 : 22.0;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ??
              EdgeInsets.fromLTRB(
                horizontal,
                vertical,
                horizontal,
                width < 860 ? 24.0 : vertical,
              ),
          child: child,
        ),
      ),
    );
  }
}

/// Barcha ekranlar uchun mobil/desktop moslashuvchan sahifa sarlavhasi (0% RenderFlex overflow)
class AdaptivePageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  final IconData? icon;

  const AdaptivePageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;

        final titleBlock = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.14),
                  ),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isCompact ? 18 : 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        if (action == null) return titleBlock;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: action!,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 16),
            action!,
          ],
        );
      },
    );
  }
}

/// Skroll bo'ladigan zamonaviy pill-filtrlar qatori (iPhone va Desktop uchun)
class ModernPillFilterBar extends StatelessWidget {
  final List<String> items;
  final String selectedItem;
  final ValueChanged<String> onSelected;
  final Map<String, int>? counts;

  const ModernPillFilterBar({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onSelected,
    this.counts,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFEAEFF7).withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.hairlineBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: items.map((item) {
            final isSelected = item == selectedItem;
            final count = counts?[item];

            return GestureDetector(
              onTap: () => onSelected(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 170),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x120F172A),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight
                              : Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Yagona minimalistik holat (status) nishoni
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final Color? borderColor;
  final IconData? icon;
  final bool showDot;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.borderColor,
    this.icon,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? color.withValues(alpha: 0.1);
    final border = borderColor ?? color.withValues(alpha: 0.22);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ] else if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
