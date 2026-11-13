import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import 'landing_screen.dart';

/// Telefon ilovasida animatsiyadan keyingi kutib olish ekrani. Sayt bosh
/// sahifasi bilan bir xil blok (EntryHero), faqat ixcham.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    BrandMark(height: 32),
                    SizedBox(width: 10),
                    BrandWordmark(fontSize: 19),
                  ],
                ),
              ),
            ),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: EntryHero()),
            ),
          ],
        ),
      ),
    );
  }
}
