import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/namangan_data.dart';
import '../../../providers/app_provider.dart';

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

    final filtered = institutions.where((inst) {
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
      if (_filterType != null && _filterType!.isNotEmpty && type != _filterType) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Ta’lim Muassasalari Reyestri',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          '${filtered.length} ta muassasa',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Namangan viloyati bo‘yicha umumta’lim maktablari, inklyuziv tayanch markazlari va ixtisoslashtirilgan maktab-internatlar',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. FILTRLAR
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
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
                        hintText: 'Muassasa nomi yoki hudud bo‘yicha qidiruv...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String?>(
                      value: _filterDistrict,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Hudud / Tuman',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
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
                      value: _filterType,
                      decoration: InputDecoration(
                        labelText: 'Muassasa turi',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
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

              final schoolStudents = allStudents
                  .where((st) =>
                      st.institutionName.toLowerCase() == name.toLowerCase())
                  .toList();
              final schoolStaff = allUsers
                  .where((u) =>
                      (u.institutionName ?? '').toLowerCase() ==
                      name.toLowerCase())
                  .toList();

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          color: Color(0xFF0F766E),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 10),
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
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '📍 $district • Namangan viloyati',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              children: [
                                Text(
                                  '🧒 O‘quvchilar: $studentsCount nafar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: studentsCount > 0
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                  ),
                                ),
                                Text(
                                  '👩‍🏫 Kadrlar: $specialistsCount ta',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: specialistsCount > 0
                                        ? const Color(0xFF7C3AED)
                                        : AppColors.textMuted,
                                  ),
                                ),
                                Text(
                                  '📋 Faol ITR: $iepCount ta',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: iepCount > 0
                                        ? const Color(0xFF12803A)
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF8FAFC),
                          foregroundColor: AppColors.textPrimary,
                          elevation: 0,
                          side: const BorderSide(color: AppColors.border),
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
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('Tarkibini ko‘rish'),
                      ),
                    ],
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
      builder: (ctx) => AlertDialog(
        title: Text(
          name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 560,
          height: 440,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hudud: $district • Turi: $type',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const Divider(height: 20),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        tabs: [
                          Tab(text: 'ATEB O‘quvchilar (${students.length})'),
                          Tab(text: 'Pedagog-kadrlar (${staff.length})'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // O'quvchilar
                            students.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Bu muassasada hozircha o‘quvchi ro‘yxatga olinmagan',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: students.length,
                                    separatorBuilder: (_, _) =>
                                        const Divider(height: 1),
                                    itemBuilder: (c, idx) {
                                      final st = students[idx];
                                      return ListTile(
                                        dense: true,
                                        title: Text(
                                          st.fullName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${st.grade} • ${st.primaryNeed}',
                                        ),
                                        trailing: Text(
                                          st.supportLevel,
                                          style: const TextStyle(
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
                                ? const Center(
                                    child: Text(
                                      'Bu muassasaga hozircha kadr biriktirilmagan',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: staff.length,
                                    separatorBuilder: (_, _) =>
                                        const Divider(height: 1),
                                    itemBuilder: (c, idx) {
                                      final u = staff[idx];
                                      return ListTile(
                                        dense: true,
                                        title: Text(
                                          u.fullName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${u.role.label} • ${u.phone ?? ''}',
                                        ),
                                        trailing: Text(
                                          u.qualificationCategory ??
                                              'Mutaxassis',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF7C3AED),
                                            fontWeight: FontWeight.w600,
                                          ),
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
