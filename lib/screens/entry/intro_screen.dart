import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_brand.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/brand_logo.dart';

/// Ilova ochilganda (faqat telefon/desktop ilovasida, saytda emas) ko'rsatiladigan
/// qisqa animatsiya: belgi paydo bo'ladi, keyin "Individ" yozuvi va shiori.
/// Ekranga bosilsa o'tkazib yuboriladi; tizimda animatsiyalar o'chirilgan
/// bo'lsa — umuman ko'rsatilmaydi.
class IntroScreen extends StatefulWidget {
  final VoidCallback onDone;

  const IntroScreen({super.key, required this.onDone});

  static const duration = Duration(milliseconds: 2300);

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  Timer? _timer;
  bool _finished = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer ??= Timer(
      MediaQuery.of(context).disableAnimations ? Duration.zero : IntroScreen.duration,
      _finish,
    );
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.1,
              colors: [AppColors.surface, AppColors.primaryLight],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(height: 104)
                    .animate()
                    .fadeIn(duration: 450.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1, 1),
                      duration: 650.ms,
                      curve: Curves.easeOutBack,
                    )
                    .then(delay: 120.ms)
                    .shimmer(duration: 900.ms, color: Colors.white70),
                const SizedBox(height: 22),
                const BrandWordmark(fontSize: 40)
                    .animate(delay: 550.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.35, end: 0, duration: 450.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 10),
                Text(
                      AppBrand.tagline,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    )
                    .animate(delay: 900.ms)
                    .fadeIn(duration: 450.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
