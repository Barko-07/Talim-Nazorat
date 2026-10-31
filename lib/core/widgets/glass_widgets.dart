import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/user_model.dart';
import '../constants/app_colors.dart';

/// Rollar uchun minimalistik vektor ikonkalar (models/ ni o'zgartirmasdan)
IconData premiumRoleIcon(UserRole role) {
  switch (role) {
    case UserRole.superAdmin:
      return LucideIcons.shieldCheck;
    case UserRole.institutionAdmin:
      return LucideIcons.landmark;
    case UserRole.coordinator:
      return LucideIcons.sparkles;
    case UserRole.psychologist:
      return LucideIcons.brain;
    case UserRole.speechTherapist:
      return LucideIcons.mic;
    case UserRole.specialEducation:
      return LucideIcons.puzzle;
    case UserRole.teacher:
      return LucideIcons.bookOpen;
    case UserRole.reviewer:
      return LucideIcons.eye;
    case UserRole.parent:
      return LucideIcons.heartHandshake;
  }
}

/// Sokin va toza minimalist orqa fon (ortiqcha yorqin ranglarsiz)
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
    final subtleAlpha = intense ? 0.045 : 0.025;

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF8F9FB),
                Color(0xFFF5F6F9),
                Color(0xFFF7F8FA),
              ],
            ),
          ),
        ),
        Positioned(
          top: -180,
          right: -120,
          child: IgnorePointer(
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: subtleAlpha),
                    AppColors.primary.withValues(alpha: 0.0),
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

/// Minimalist Soft-Glass konteyneri (18px radius + 1.0px nozik hairline border)
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
    this.blur = 16,
    this.opacity = 0.90,
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
        color: baseColor.withValues(alpha: opacity.clamp(0.0, 1.0)),
        border: Border.all(
          color: borderColor ?? AppColors.glassWhiteBorder,
          width: 1.0,
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

/// Minimalist asosiy karta: 18px radius, toza oq yuza va 1.0px nozik chegara
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
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius = 18,
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
            ? AppColors.borderSlate
            : AppColors.glassWhiteBorder);

    final bgColor = widget.backgroundColor ??
        Colors.white.withValues(
          alpha: _hovered && interactive ? 0.99 : 0.95,
        );

    Widget cardBody = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.0,
        ),
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
          splashColor: AppColors.primary.withValues(alpha: 0.04),
          highlightColor: AppColors.primary.withValues(alpha: 0.02),
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
        scale: _pressed ? 0.988 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: cardBody,
      ),
    );
  }
}

/// Karta ichidagi konsentrik (outer 18 -> inner 12) sokin ichki blok
class GlassWell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? tintColor;
  final Color? borderColor;

  const GlassWell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.borderRadius = 12,
    this.tintColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: tintColor ?? AppColors.glassWellFill,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.glassInnerBorder,
          width: 0.85,
        ),
      ),
      child: child,
    );
  }
}

/// Qat'iy balandliksiz (0% vertical text overflow!) moslashuvchan grid
class ResponsiveGlassGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;

  const ResponsiveGlassGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 4,
    this.spacing = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w >= 960
            ? desktopColumns
            : w >= 540
                ? tabletColumns
                : mobileColumns;

        if (cols <= 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (int i = 0; i < children.length; i += cols) {
          final end = (i + cols < children.length) ? i + cols : children.length;
          final slice = children.sublist(i, end);
          final remaining = cols - slice.length;

          if (rows.isNotEmpty) {
            rows.add(SizedBox(height: spacing));
          }

          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int j = 0; j < slice.length; j++) ...[
                    if (j > 0) SizedBox(width: spacing),
                    Expanded(child: slice[j]),
                  ],
                  for (int k = 0; k < remaining; k++) ...[
                    SizedBox(width: spacing),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}

/// Keng monitorlarda kontentni o'rtaga tekislab, iPhone'da nafas oladigan hoshiya beruvchi konteyner
class ResponsivePageContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsivePageContainer({
    super.key,
    required this.child,
    this.maxWidth = 1260,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 600
        ? 16.0
        : width < 1024
            ? 24.0
            : 32.0;
    final vertical = width < 600 ? 16.0 : 24.0;

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
                width < 860 ? 28.0 : vertical,
              ),
          child: child,
        ),
      ),
    );
  }
}

/// Barcha ekranlar uchun mobil/desktop moslashuvchan sahifa sarlavhasi (qutisiz erkin ikonka)
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
        final isCompact = constraints.maxWidth < 580;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: isCompact ? 21 : 23,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isCompact ? 19.5 : 23,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.45,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
                height: 1.4,
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
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [action!],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 18),
            Flexible(child: action!),
          ],
        );
      },
    );
  }
}

/// Minimalist segmentli filtr-bar (12px tashqi, 9px ichki)
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
        padding: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF1F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: items.map((item) {
            final isSelected = item == selectedItem;
            final count = counts?[item];

            return GestureDetector(
              onTap: () => onSelected(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.glassWhiteBorder
                        : Colors.transparent,
                    width: 0.85,
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x0D0F172A),
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
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
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

/// Minimalist holat nishoni (8px radius + 0.85px nozik chegara)
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final Color? borderColor;
  final IconData? icon;
  final bool showDot;
  final double maxWidth;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.borderColor,
    this.icon,
    this.showDot = false,
    this.maxWidth = 240,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? color.withValues(alpha: 0.08);
    final border = borderColor ?? color.withValues(alpha: 0.18);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9.5, vertical: 4.5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: 0.85),
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
              const SizedBox(width: 5.5),
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
      ),
    );
  }
}
