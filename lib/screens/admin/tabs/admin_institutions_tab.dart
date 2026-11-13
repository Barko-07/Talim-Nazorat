import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/namangan_data.dart';
import '../../../providers/app_provider.dart';
import '../../../core/theme/box_input_border.dart';

class AdminInstitutionsTab extends StatefulWidget {
  const AdminInstitutionsTab({super.key});

  @override
  State<AdminInstitutionsTab> createState() => _AdminInstitutionsTabState();
}

class _AdminInstitutionsTabState extends State<AdminInstitutionsTab> {
  String _search = '';
  String? _filterDistrict;
  String? _filterType;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final institutions = app.institutionsSummary;
    final allStudents = app.students;
    final allUsers = app.allUsers;

    final filtered =
        institutions.where((inst) {
          final name = (inst['name'] as String).toLowerCase();
          final dist = (inst['district'] as String).toLowerCase();
          final type = (inst['type'] as String);

          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            if (!name.contains(q) && !dist.contains(q)) return false;
          }
          if (_filterDistrict != null &&
              _filterDistrict!.isNotEmpty &&
              inst['district'] != _filterDistrict) {
            return false;
          }
          if (_filterType != null &&
              _filterType!.isNotEmpty &&
              type != _filterType) {
            return false;
          }
          return true;
        }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Ta’lim Muassasalari Reyestri',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.infoBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.info.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            '${filtered.length} ta muassasa',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Namangan viloyati bo‘yicha umumta’lim maktablari, inklyuziv tayanch markazlari va ixtisoslashtirilgan maktab-internatlar',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. FILTRLAR
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: AppColors.cardGlassBorder, width: 1.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v.trim()),
                      decoration: InputDecoration(
                        hintText:
                            'Muassasa nomi yoki hudud bo‘yicha qidiruv...',
                        prefixIcon: const Icon(LucideIcons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: BoxInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _filterDistrict,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Hudud / Tuman',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: BoxInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Barcha tumanlar'),
                        ),
                        ...NamanganData.districts.map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(d, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _filterDistrict = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: _filterType,
                      decoration: InputDecoration(
                        labelText: 'Muassasa turi',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: BoxInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Barcha turlar'),
                        ),
                        DropdownMenuItem(
                          value: 'Umumiy o‘rta ta’lim maktabi',
                          child: Text('Umumiy o‘rta maktab'),
                        ),
                        DropdownMenuItem(
                          value: 'Inklyuziv tayanch maktab',
                          child: Text('Inklyuziv tayanch'),
                        ),
                        DropdownMenuItem(
                          value: 'Ixtisoslashtirilgan maktab-internati',
                          child: Text('Ixtisoslashtirilgan internat'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _filterType = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. MUASSASALAR JADVALI
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final inst = filtered[i];
              final name = inst['name'] as String;
              final district = inst['district'] as String;
              final type = inst['type'] as String;
              final studentsCount = inst['studentsCount'] as int;
              final specialistsCount = inst['specialistsCount'] as int;
              final iepCount = inst['activeIepCount'] as int;

              final schoolStudents =
                  allStudents
                      .where(
                        (st) =>
                            st.institutionName.toLowerCase() ==
                            name.toLowerCase(),
                      )
                      .toList();
              final schoolStaff =
                  allUsers
                      .where(
                        (u) =>
                            (u.institutionName ?? '').toLowerCase() ==
                            name.toLowerCase(),
                      )
                      .toList();

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: BorderSide(
                    color: AppColors.cardGlassBorder,
                    width: 1.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: LayoutBuilder(
                    builder: (context, cardConstraints) {
                      final isCompact = cardConstraints.maxWidth < 560;

                      final iconBadge = Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.infoBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          LucideIcons.building2,
                          color: AppColors.info,
                          size: 18,
                        ),
                      );

                      final instInfo = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$district • Namangan viloyati',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Text(
                                'O‘quvchilar: $studentsCount nafar',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      studentsCount > 0
                                          ? AppColors.primary
                                          : AppColors.textMuted,
                                ),
                              ),
                              Text(
                                'Kadrlar: $specialistsCount ta',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      specialistsCount > 0
                                          ? AppColors.purple
                                          : AppColors.textMuted,
                                ),
                              ),
                              Text(
                                'Faol ITR: $iepCount ta',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      iepCount > 0
                                          ? AppColors.success
                                          : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );

                      final actionBtn = ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceMuted,
                          foregroundColor: AppColors.textPrimary,
                          elevation: 0,
                          side: BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          _showInstitutionDetailsModal(
                            context,
                            name,
                            district,
                            type,
                            schoolStudents,
                            schoolStaff,
                          );
                        },
                        icon: const Icon(LucideIcons.eye, size: 16),
                        label: const Text('Tarkibini ko‘rish'),
                      );

                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                iconBadge,
                                const SizedBox(width: 14),
                                Expanded(child: instInfo),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(width: double.infinity, child: actionBtn),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          iconBadge,
                          const SizedBox(width: 16),
                          Expanded(child: instInfo),
                          const SizedBox(width: 16),
                          actionBtn,
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showInstitutionDetailsModal(
    BuildContext context,
    String name,
    String district,
    String type,
    List<dynamic> students,
    List<dynamic> staff,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              name,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: SizedBox(
              width: 560,
              height: 440,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hudud: $district • Turi: $type',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const Divider(height: 20),
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.isDark
                                      ? AppColors.surfaceMuted
                                      : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color:
                                    AppColors.isDark
                                        ? AppColors.border
                                        : const Color(0xFFE2E8F0),
                                width: 1.0,
                              ),
                            ),
                            child: TabBar(
                              dividerColor: Colors.transparent,
                              overlayColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                              splashFactory: NoSplash.splashFactory,
                              labelColor: AppColors.textPrimary,
                              unselectedLabelColor: AppColors.textMuted,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicator: BoxDecoration(
                                color:
                                    AppColors.isDark
                                        ? AppColors.surfaceRaised
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      AppColors.isDark
                                          ? const Color(0x35FFFFFF)
                                          : AppColors.cardGlassBorder,
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (AppColors.isDark
                                            ? Colors.black
                                            : const Color(0xFF0F172A))
                                        .withValues(
                                          alpha: AppColors.isDark ? 0.35 : 0.06,
                                        ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1.5),
                                  ),
                                ],
                              ),
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              unselectedLabelStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              tabs: [
                                Tab(
                                  height: 36,
                                  text: 'ATEB O‘quvchilar (${students.length})',
                                ),
                                Tab(
                                  height: 36,
                                  text: 'Pedagog-kadrlar (${staff.length})',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: TabBarView(
                              children: [
                                // O'quvchilar
                                students.isEmpty
                                    ? Center(
                                      child: Text(
                                        'Bu muassasada hozircha o‘quvchi ro‘yxatga olinmagan',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    )
                                    : ListView.separated(
                                      itemCount: students.length,
                                      separatorBuilder:
                                          (_, _) => const Divider(height: 1),
                                      itemBuilder: (c, idx) {
                                        final st = students[idx];
                                        return ListTile(
                                          dense: true,
                                          title: Text(
                                            st.fullName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${st.grade} • ${st.primaryNeed}',
                                          ),
                                          trailing: Text(
                                            st.supportLevel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                // Kadrlar
                                staff.isEmpty
                                    ? Center(
                                      child: Text(
                                        'Bu muassasaga hozircha kadr biriktirilmagan',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    )
                                    : ListView.separated(
                                      itemCount: staff.length,
                                      separatorBuilder:
                                          (_, _) => const Divider(height: 1),
                                      itemBuilder: (c, idx) {
                                        final u = staff[idx];
                                        return ListTile(
                                          dense: true,
                                          title: Text(
                                            u.fullName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${u.role.label} • ${u.phone ?? ''}',
                                          ),
                                        );
                                      },
                                    ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Yopish'),
              ),
            ],
          ),
    );
  }
}
