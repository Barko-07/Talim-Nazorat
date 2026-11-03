import 'package:flutter/material.dart';

import '../constants/app_brand.dart';
import '../constants/app_colors.dart';

/// Individ belgisi (figura) — sarlavha va menyularda nom yonida ishlatiladi.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.height = 24});

  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
    AppBrand.markAsset,
    height: height,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
    semanticLabel: AppBrand.name,
  );
}

/// "Individ" so'z belgisi — logotipdagidek "i" harflari yashil rangda.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.fontSize = 16});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
      color: AppColors.brandNavy,
      height: 1.1,
    );
    const green = TextStyle(color: AppColors.brandGreen);
    return Text.rich(
      TextSpan(
        style: base,
        children: const [
          TextSpan(text: 'Ind'),
          TextSpan(text: 'i', style: green),
          TextSpan(text: 'v'),
          TextSpan(text: 'i', style: green),
          TextSpan(text: 'd'),
        ],
      ),
      semanticsLabel: AppBrand.name,
      maxLines: 1,
    );
  }
}

/// To'liq logotip (belgi + nom) — kirish va yuklanish ekranlari uchun.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
    AppBrand.logoAsset,
    height: height,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
    semanticLabel: AppBrand.name,
  );
}
