import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/psychological_methods_data.dart';
import '../../../providers/app_provider.dart';

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
        return Icons.psychology_outlined;
      case 'Diqqat va ishchanlik':
        return Icons.track_changes_outlined;
      case 'Xotira jarayonlari':
        return Icons.memory_outlined;
      case 'Emotsional va xavotir':
        return Icons.mood_outlined;
      case 'Shaxsiyat va moslashuv':
        return Icons.person_outline_outlined;
      default:
        return Icons.menu_book_outlined;
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

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sarlavha paneli
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Psixologik metodikalar va vositalar to‘plami',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Maktab amaliyotchi psixologi faoliyatida tasdiqlangan diagnostik metodikalar, ko‘rsatmalar va me’yoriy talqinlar.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryTint),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 16,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${allMethods.length} ta tasdiqlangan metodika',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Qidiruv va soha filtrlari
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Qidiruv maydoni
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
                        Icons.search,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon:
                          _searchQuery.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
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
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Soha chiplari
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          dynamicDomains.map((domain) {
                            final isSelected = _selectedDomain == domain;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(domain),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedDomain = domain;
                                    });
                                  }
                                },
                                selectedColor: AppColors.primary.withOpacity(
                                  0.12,
                                ),
                                backgroundColor: AppColors.surfaceMuted,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                  color:
                                      isSelected
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                ),
                                side: BorderSide(
                                  color:
                                      isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Metodikalar ro'yxati yoki bo'sh holat
            if (filteredMethods.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 54,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bunday parametr bo‘yicha metodika topilmadi',
                      style: TextStyle(
                        fontSize: 15,
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
                    OutlinedButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _selectedDomain = 'Barchasi';
                        });
                      },
                      child: const Text('Filtrlarni tozalash'),
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 850) {
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children:
                          filteredMethods.map((m) {
                            final cardWidth = (constraints.maxWidth - 16) / 2;
                            return SizedBox(
                              width: cardWidth,
                              child: _buildMethodCard(context, m),
                            );
                          }).toList(),
                    );
                  } else {
                    return Column(
                      children:
                          filteredMethods.map((m) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: _buildMethodCard(context, m),
                            );
                          }).toList(),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(BuildContext context, PsychologicalMethodItem m) {
    final domainColor = _getDomainColor(m.domain);
    final domainIcon = _getDomainIcon(m.domain);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yuqori qator: Kod, Soha va Vaqt
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: domainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: domainColor.withOpacity(0.3)),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(domainIcon, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      m.domain,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '~${m.durationMinutes} daq',
                    style: TextStyle(
                      fontSize: 11,
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
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.person_pin_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Muallif: ${m.author}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.cake_outlined,
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
          const SizedBox(height: 10),

          // Maqsad (qisqa)
          Text(
            m.purpose,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
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
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 15,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '⚠ Litsenziyalangan test: ${m.licenseNote ?? "Rasmiy litsenziyalangan qo‘llanma asosida talqin qilinadi."}',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.checklist_rtl_rounded, size: 14, color: domainColor),
                const SizedBox(width: 6),
                Text(
                  '${m.subscales.length} ta parametr / shkala',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Maksimal ball: ${m.maxScore.toInt()}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tugmalar
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showMethodDetailsDialog(context, m),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Ko‘rsatma va me’yor'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _startAssessmentWithMethod(context, m),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Baholash'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: domainColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                        color: domainColor.withOpacity(0.1),
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
                                  color: domainColor.withOpacity(0.12),
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
                              fontSize: 18,
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
                      icon: const Icon(Icons.close),
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
                          Icons.flag_outlined,
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
                          Icons.rule_sharp,
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
                          Icons.format_list_bulleted_rounded,
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
                                          Icons.check_circle_outline,
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
                          Icons.calculate_outlined,
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
                          Icons.analytics_outlined,
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warningBg.withOpacity(0.3),
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
                                Icons.shield_outlined,
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
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Ushbu metodika bilan baholash'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: domainColor,
                        foregroundColor: Colors.white,
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
