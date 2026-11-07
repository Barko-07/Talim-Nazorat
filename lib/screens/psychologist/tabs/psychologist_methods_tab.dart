import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/psychological_methods_data.dart';
import '../../../providers/app_provider.dart';
import '../../../core/widgets/glass_widgets.dart';

class PsychologistMethodsTab extends StatefulWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const PsychologistMethodsTab({super.key, this.onNavigateToTab});

  @override
  State<PsychologistMethodsTab> createState() => _PsychologistMethodsTabState();
}

class _PsychologistMethodsTabState extends State<PsychologistMethodsTab> {
  String _searchQuery = '';
  String _selectedDomain = 'Barchasi';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getDomainIcon(String domain) {
    switch (domain) {
      case 'Kognitiv va intellekt':
        return LucideIcons.brain;
      case 'Diqqat va ishchanlik':
        return LucideIcons.target;
      case 'Xotira jarayonlari':
        return LucideIcons.brain;
      case 'Emotsional va xavotir':
        return LucideIcons.smile;
      case 'Shaxsiyat va moslashuv':
        return LucideIcons.user;
      default:
        return LucideIcons.bookOpen;
    }
  }

  Color _getDomainColor(String domain) {
    switch (domain) {
      case 'Kognitiv va intellekt':
        return AppColors.primaryDark;
      case 'Diqqat va ishchanlik':
        return AppColors.brandTeal;
      case 'Xotira jarayonlari':
        return AppColors.purple;
      case 'Emotsional va xavotir':
        return AppColors.warning;
      case 'Shaxsiyat va moslashuv':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final allMethods =
        app.myMethods.isNotEmpty
            ? app.myMethods
            : PsychologicalMethodsData.methods;
    final dynamicDomains = <String>[
      'Barchasi',
      ...{for (final m in allMethods) m.domain},
    ];

    final filteredMethods =
        allMethods.where((m) {
          final matchesDomain =
              _selectedDomain == 'Barchasi' || m.domain == _selectedDomain;
          final q = _searchQuery.toLowerCase().trim();
          final matchesSearch =
              q.isEmpty ||
              m.title.toLowerCase().contains(q) ||
              m.code.toLowerCase().contains(q) ||
              m.author.toLowerCase().contains(q) ||
              m.purpose.toLowerCase().contains(q);
          return matchesDomain && matchesSearch;
        }).toList();

    final width = MediaQuery.sizeOf(context).width;
    final horizontalPad = width < 600 ? 12.0 : 18.0;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          horizontalPad,
          MediaQuery.paddingOf(context).top + (width >= 920 ? 82 : 74),
          horizontalPad,
          width < 920 ? (84 + MediaQuery.paddingOf(context).bottom) : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sarlavha paneli (Minimalist Glassy Header)
            SurfaceCard(
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusPill(
                    label: '${allMethods.length} ta tasdiqlangan metodika',
                    color: AppColors.primary,
                    backgroundColor: AppColors.primaryLight,
                    icon: LucideIcons.verified,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Psixologik metodikalar va vositalar to‘plami',
                    style: TextStyle(
                      fontSize: width < 600 ? 18.5 : 21,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Maktab amaliyotchi psixologi faoliyatida tasdiqlangan diagnostik metodikalar, ko‘rsatmalar va me’yoriy talqinlar.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Qidiruv va soha filtrlari
            SurfaceCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText:
                          'Metodika nomi, kodi (RAVEN, LANDOLT...), muallifi bo‘yicha qidiring...',
                      prefixIcon: Icon(
                        LucideIcons.search,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon:
                          _searchQuery.isNotEmpty
                              ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                              : null,
                      filled: true,
                      fillColor: AppColors.surfaceMuted,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ModernPillFilterBar(
                    items: dynamicDomains,
                    selectedItem: _selectedDomain,
                    onSelected:
                        (domain) => setState(() => _selectedDomain = domain),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Metodikalar ro'yxati yoki bo'sh holat
            if (filteredMethods.isEmpty)
              SurfaceCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.searchX,
                        size: 46,
                        color: AppColors.textSubtle,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bunday parametr bo‘yicha metodika topilmadi',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Qidiruv so‘zini o‘zgartiring yoki filtrlarni tozalang.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      HeaderActionButton(
                        label: 'Filtrlarni tozalash',
                        variant: HeaderActionVariant.secondary,
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _selectedDomain = 'Barchasi';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              )
            else
              ResponsiveGlassGrid(
                mobileColumns: 1,
                tabletColumns: 1,
                desktopColumns: 2,
                spacing: 12,
                children:
                    filteredMethods
                        .map((m) => _buildMethodCard(context, m))
                        .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(BuildContext context, PsychologicalMethodItem m) {
    final domainColor = _getDomainColor(m.domain);
    final domainIcon = _getDomainIcon(m.domain);

    return SurfaceCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Yuqori qator: Kod, Soha va Vaqt
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusPill(
                    label: m.code,
                    color: domainColor,
                    backgroundColor: domainColor.withValues(alpha: 0.1),
                  ),
                  StatusPill(
                    label: m.domain,
                    color: AppColors.textSecondary,
                    backgroundColor: AppColors.surfaceMuted,
                    icon: domainIcon,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.timer,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '~${m.durationMinutes} daq',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Nomi va muallifi
          Text(
            m.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.userRound,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      'Muallif: ${m.author}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.cake,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    m.targetAge,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Maqsad (qisqa)
          Text(
            m.purpose,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (m.requiresLicensedMaterials) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.triangleAlert,
                    size: 15,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Litsenziyalangan test: ${m.licenseNote ?? "Rasmiy litsenziyalangan qo‘llanma asosida talqin qilinadi."}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Subshkalalar soni va max ball
          GlassWell(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            borderRadius: 12,
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.listChecks, size: 14, color: domainColor),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 170),
                      child: Text(
                        '${m.subscales.length} ta parametr / shkala',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Maksimal ball: ${m.maxScore.toInt()}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tugmalar
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              HeaderActionButton(
                label: 'Ko‘rsatma va me’yor',
                compactLabel: 'Ko‘rsatma',
                icon: LucideIcons.info,
                variant: HeaderActionVariant.secondary,
                onPressed: () => _showMethodDetailsDialog(context, m),
              ),
              HeaderActionButton(
                label: 'Baholashni boshlash',
                compactLabel: 'Baholash',
                icon: LucideIcons.play,
                onPressed: () => _startAssessmentWithMethod(context, m),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMethodDetailsDialog(
    BuildContext context,
    PsychologicalMethodItem m,
  ) {
    final domainColor = _getDomainColor(m.domain);

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 720,
            constraints: const BoxConstraints(maxHeight: 750),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal sarlavhasi
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: domainColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getDomainIcon(m.domain),
                        color: domainColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: domainColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  m.code,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: domainColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                m.domain,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Muallif: ${m.author} • Yosh guruhi: ${m.targetAge} • Vaqt: ~${m.durationMinutes} daqiqa',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Asosiy kontent
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Maqsad
                        _buildSectionHeader(
                          '1. Metodikaning maqsadi',
                          LucideIcons.flag,
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            m.purpose,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // O'tkazish bo'yicha yo'riqnoma
                        _buildSectionHeader(
                          '2. O‘tkazish bo‘yicha yo‘riqnoma',
                          LucideIcons.listChecks,
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            m.instructions,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Subshkalalar
                        _buildSectionHeader(
                          '3. Baholanadigan parametrlar / shkalalar',
                          LucideIcons.list,
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                m.subscales.map((s) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          LucideIcons.circleCheck,
                                          size: 16,
                                          color: AppColors.brandTeal,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            s,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Baholash va hisoblash
                        _buildSectionHeader(
                          '4. Natijalarni hisoblash tartibi',
                          LucideIcons.calculator,
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.scoringGuide,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Maksimal natija: ${m.maxScore.toInt()} ball',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Me'yoriy ko'rsatkichlar va talqin
                        _buildSectionHeader(
                          '5. Me’yoriy ko‘rsatkichlar va psixologik talqin',
                          LucideIcons.chartColumn,
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warningBg.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.warningBorder),
                          ),
                          child: Text(
                            m.normCriteria,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nizom va vakolat eslatmasi
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.shield,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Mazkur metodika O‘zR Maktabgacha va maktab ta’limi vazirligi psixologik xizmat standartlariga mos va pedagogik-psixologik tavsiyanoma shakllantirishda qo‘llaniladi.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tugmalar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Yopish'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _startAssessmentWithMethod(context, m);
                      },
                      icon: const Icon(LucideIcons.play),
                      label: const Text('Ushbu metodika bilan baholash'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: domainColor,
                        foregroundColor: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _startAssessmentWithMethod(
    BuildContext context,
    PsychologicalMethodItem m,
  ) {
    if (widget.onNavigateToTab != null) {
      // 2 - index corresponds to "Baholash" tab
      widget.onNavigateToTab!(2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${m.title}" metodikasi bo‘yicha baholash oynasiga yo‘naltirildi.',
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
