import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/constants/app_brand.dart';
import '../../core/constants/app_colors.dart';

/// Platformaga kirganda birinchi ko‘rinadigan minimalist brend animatsiyasi.
///
/// Ortiqcha shakllar, aylanuvchi yuklagichlar yoki shiorlarsiz — faqatgina
/// [AppBrand.markAsset] belgisi va "Individ" so‘z belgisining optik fokus,
/// silliq markaziy siljish, harfma-harf uyg‘onish hamda nozik nur o‘tishi
/// orqali jonlanishi.
class IntroScreen extends StatefulWidget {
  final VoidCallback? onDone;
  final bool canFinish;

  const IntroScreen({
    super.key,
    this.onDone,
    this.canFinish = true,
  });

  static const Duration entranceDuration = Duration(milliseconds: 1750);
  static const Duration exitDuration = Duration(milliseconds: 320);

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  static const double _markAspectRatio = 325.0 / 512.0;
  static const String _word = AppBrand.name; // "Individ"

  static const Cubic _easeOutExpo = Cubic(0.16, 1.0, 0.30, 1.0);
  static const Cubic _easeOutQuint = Cubic(0.22, 1.0, 0.36, 1.0);

  late final AnimationController _entranceController;
  late final AnimationController _exitController;

  ImageStream? _markStream;
  ImageStreamListener? _markListener;
  Timer? _fallbackTimer;

  bool _entranceStarted = false;
  bool _exitStarted = false;
  bool _doneFired = false;

  _WordmarkMetrics? _cachedMetrics;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: IntroScreen.entranceDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _tryStartExit();
        }
      });

    _exitController = AnimationController(
      vsync: this,
      duration: IntroScreen.exitDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _fireDone();
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceStarted) return;

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _entranceStarted = true;
      _entranceController.value = 1.0;
      _fallbackTimer = Timer(Duration.zero, _tryStartExit);
      return;
    }

    // Belgini birinchi kadrdanoq tiniq chizish uchun tekstura tayyor bo‘lishini kutamiz.
    final stream = const AssetImage(AppBrand.markAsset).resolve(
      createLocalImageConfiguration(context),
    );
    _markStream = stream;
    _markListener = ImageStreamListener(
      (_, _) => _beginEntrance(),
      onError: (_, _) => _beginEntrance(),
    );
    stream.addListener(_markListener!);
    _fallbackTimer = Timer(const Duration(milliseconds: 90), _beginEntrance);
  }

  @override
  void didUpdateWidget(covariant IntroScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.canFinish && widget.canFinish) {
      if (_entranceController.isCompleted && !_exitStarted) {
        // Orqa fondagi asosiy sahifa birinchi kadrini chizib olishi uchun 1 kadr kutamiz.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _tryStartExit();
        });
      }
    }
  }

  void _beginEntrance() {
    if (_entranceStarted || !mounted) return;
    _entranceStarted = true;
    _fallbackTimer?.cancel();
    _detachImageListener();
    _entranceController.forward();
  }

  void _tryStartExit({bool fast = false}) {
    if (_exitStarted || !mounted || !widget.canFinish) return;
    if (widget.onDone == null) return;
    _exitStarted = true;

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _exitController.duration = const Duration(milliseconds: 140);
    } else if (fast) {
      _exitController.duration = const Duration(milliseconds: 220);
    }
    _exitController.forward();
  }

  void _fireDone() {
    if (_doneFired || !mounted) return;
    _doneFired = true;
    widget.onDone?.call();
  }

  void _detachImageListener() {
    if (_markStream != null && _markListener != null) {
      _markStream!.removeListener(_markListener!);
    }
    _markStream = null;
    _markListener = null;
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _detachImageListener();
    _entranceController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  _WordmarkMetrics _resolveMetrics(String? fontFamily, double fontSize) {
    final cached = _cachedMetrics;
    if (cached != null &&
        cached.fontFamily == fontFamily &&
        cached.fontSize == fontSize) {
      return cached;
    }

    final measureStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.022 * fontSize,
      height: 1.08,
    );

    final painter = TextPainter(
      text: TextSpan(text: _word, style: measureStyle),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    )..layout();

    final offsets = List<double>.generate(
      _word.length,
      (i) => painter.getOffsetForCaret(TextPosition(offset: i), Rect.zero).dx,
      growable: false,
    );

    final metrics = _WordmarkMetrics(
      fontFamily: fontFamily,
      fontSize: fontSize,
      width: painter.width,
      height: painter.height,
      glyphOffsets: offsets,
    );
    painter.dispose();
    _cachedMetrics = metrics;
    return metrics;
  }

  static double _intervalValue(
    double t,
    double begin,
    double end,
    Curve curve,
  ) {
    if (t <= begin) return 0.0;
    if (t >= end) return 1.0;
    return curve.transform((t - begin) / (end - begin));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final bgColor = isDark ? AppColors.background : AppColors.surface;
    final inkColor = isDark ? AppColors.textPrimary : AppColors.brandNavy;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 600;

    final markHeight = isCompact ? 62.0 : 78.0;
    final markWidth = markHeight * _markAspectRatio;
    final gap = isCompact ? 16.0 : 20.0;
    final wordmarkFontSize = isCompact ? 36.5 : 46.0;

    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    final metrics = _resolveMetrics(fontFamily, wordmarkFontSize);

    final baseGlyphStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: wordmarkFontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: 1.08,
      color: inkColor,
    );
    final greenGlyphStyle = baseGlyphStyle.copyWith(
      color: AppColors.brandGreen,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _tryStartExit(fast: true),
      child: AnimatedBuilder(
        animation: Listenable.merge([_entranceController, _exitController]),
        builder: (context, _) {
          final t = _entranceController.value;
          final exitT = Curves.easeOutCubic.transform(_exitController.value);

          final overlayOpacity = (1.0 - exitT).clamp(0.0, 1.0);
          final exitScale = 1.0 + (0.03 * exitT);

          // 1-bosqich: Belgining optik fokus bilan markazda paydo bo‘lishi
          final markOpacity = _intervalValue(t, 0.00, 0.20, Curves.easeOut);
          final markMotion = _intervalValue(t, 0.00, 0.34, _easeOutExpo);
          final markBlurProgress = _intervalValue(
            t,
            0.00,
            0.28,
            Curves.easeOutCubic,
          );
          final markScale = 0.86 + (0.14 * markMotion);
          final markTranslateY = 8.0 * (1.0 - markMotion);
          final markBlurSigma = 7.0 * (1.0 - markBlurProgress);

          // 2-bosqich: Belgining chapga silliq siljishi va "Individ" uchun joy ochilishi
          final glideProgress = _intervalValue(t, 0.20, 0.56, _easeOutQuint);

          // 3-bosqich: Belgi va nom ustidan o‘tuvchi nozik ipakdek nur (faqat harf va logo piksellarida)
          final sheenProgress = _intervalValue(
            t,
            0.55,
            0.92,
            Curves.easeInOutCubic,
          );
          final applySheen = sheenProgress > 0.0 && sheenProgress < 1.0;

          Widget markWidget = SizedBox(
            width: markWidth,
            height: markHeight,
            child: Image.asset(
              AppBrand.markAsset,
              width: markWidth,
              height: markHeight,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              isAntiAlias: true,
              semanticLabel: AppBrand.name,
            ),
          );

          if (markBlurSigma > 0.05) {
            markWidget = ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: markBlurSigma,
                sigmaY: markBlurSigma,
                tileMode: TileMode.decal,
              ),
              child: markWidget,
            );
          }

          markWidget = Opacity(
            opacity: markOpacity,
            child: Transform.translate(
              offset: Offset(0, markTranslateY),
              child: Transform.scale(
                scale: markScale,
                child: markWidget,
              ),
            ),
          );

          final wordmarkStack = SizedBox(
            width: metrics.width,
            height: metrics.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: List<Widget>.generate(_word.length, (index) {
                final start = 0.24 + (index * 0.036);
                final end = start + 0.23;
                final charProgress = _intervalValue(
                  t,
                  start,
                  end,
                  _easeOutQuint,
                );
                final charOpacity = _intervalValue(
                  t,
                  start,
                  start + 0.16,
                  Curves.easeOut,
                );
                final charBlurProgress = _intervalValue(
                  t,
                  start,
                  start + 0.19,
                  Curves.easeOutCubic,
                );

                final charTranslateY = 10.0 * (1.0 - charProgress);
                final charScale = 0.92 + (0.08 * charProgress);
                final charBlurSigma = 3.5 * (1.0 - charBlurProgress);
                final isGreenI = index == 3 || index == 5;

                Widget glyph = Text(
                  _word[index],
                  textScaler: TextScaler.noScaling,
                  style: isGreenI ? greenGlyphStyle : baseGlyphStyle,
                );

                if (charBlurSigma > 0.05) {
                  glyph = ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: charBlurSigma,
                      sigmaY: charBlurSigma,
                      tileMode: TileMode.decal,
                    ),
                    child: glyph,
                  );
                }

                return Positioned(
                  left: metrics.glyphOffsets[index],
                  top: 0,
                  child: Opacity(
                    opacity: charOpacity,
                    child: Transform.translate(
                      offset: Offset(0, charTranslateY),
                      child: Transform.scale(
                        scale: charScale,
                        alignment: Alignment.bottomCenter,
                        child: glyph,
                      ),
                    ),
                  ),
                );
              }, growable: false),
            ),
          );

          Widget lockup = Semantics(
            label: AppBrand.name,
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  markWidget,
                  Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: glideProgress,
                    child: Padding(
                      padding: EdgeInsets.only(left: gap, top: 3),
                      child: wordmarkStack,
                    ),
                  ),
                ],
              ),
            ),
          );

          if (applySheen) {
            final sweep = -1.85 + (sheenProgress * 3.70);
            final zeroWhite = Colors.white.withValues(alpha: 0.0);
            final peakWhite = Colors.white.withValues(
              alpha: isDark ? 0.22 : 0.32,
            );

            lockup = ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(sweep - 0.55, -0.35),
                end: Alignment(sweep + 0.55, 0.35),
                colors: [zeroWhite, peakWhite, zeroWhite],
                stops: const [0.0, 0.5, 1.0],
              ).createShader(bounds),
              child: lockup,
            );
          }

          return Opacity(
            opacity: overlayOpacity,
            child: Material(
              color: bgColor,
              child: SafeArea(
                child: Center(
                  child: Transform.scale(
                    scale: exitScale,
                    child: lockup,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WordmarkMetrics {
  final String? fontFamily;
  final double fontSize;
  final double width;
  final double height;
  final List<double> glyphOffsets;

  const _WordmarkMetrics({
    required this.fontFamily,
    required this.fontSize,
    required this.width,
    required this.height,
    required this.glyphOffsets,
  });
}
