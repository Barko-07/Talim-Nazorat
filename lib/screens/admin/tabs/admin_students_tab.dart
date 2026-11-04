import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../models/student_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/child_status_service.dart';
import '../../students/student_detail_screen.dart';
import '../../students/add_student_screen.dart';

class AdminStudentsTab extends StatefulWidget {
  const AdminStudentsTab({super.key});

  @override
  State<AdminStudentsTab> createState() => _AdminStudentsTabState();
}

class _AdminStudentsTabState extends State<AdminStudentsTab> {
  String _search = '';
  String? _filterGrade;
  String? _filterStatus;
  String? _filterLevel;
  StatusColor? _filterColor;

  static Color _colorFor(StatusColor c) {
    switch (c) {
      case StatusColor.red:
        return AppColors.error;
      case StatusColor.yellow:
        return AppColors.warning;
      case StatusColor.green:
        return AppColors.success;
    }
  }

  static Color _bgFor(StatusColor c) {
    switch (c) {
      case StatusColor.red:
        return AppColors.errorBg;
      case StatusColor.yellow:
        return AppColors.warningBg;
      case StatusColor.green:
        return AppColors.successBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    final allStudents = app.allStudentsIncludingArchived;
    final summary = app.monitoringSummary;
    final statusByStudentId = <String, ChildStatus>{
      if (summary != null)
        for (final st in summary.statuses) st.student.id: st,
    };
    final df = DateFormat('dd.MM.yyyy');

    final filtered =
        allStudents.where((s) {
          if (_filterColor != null &&
              statusByStudentId[s.id]?.color != _filterColor) {
            return false;
          }
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            final matchName = s.fullName.toLowerCase().contains(q);
            final matchNeed = s.primaryNeed.toLowerCase().contains(q);
            final matchInst = s.institutionName.toLowerCase().contains(q);
            if (!matchName && !matchNeed && !matchInst) return false;
          }
          if (_filterGrade != null && s.grade != _filterGrade) return false;
          if (_filterStatus != null && s.status != _filterStatus) return false;
          if (_filterLevel != null && !s.supportLevel.contains(_filterLevel!)) {
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Alohida Ehtiyojli Bolalar Reyestri',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
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
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            '${filtered.length} nafar o‘quvchi',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Viloyat va muassasalar kesimida ATEB bolalar hisobi, ta’limiy ehtiyojlari va individual profillari',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddStudentScreen()),
                  );
                },
                icon: const Icon(LucideIcons.userPlus, size: 18),
                label: const Text('Yangi O‘quvchi Qo‘shish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. FILTRLAR
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.border),
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
                        hintText: 'F.I.SH, ehtiyoj toifasi yoki maktab...',
                        prefixIcon: const Icon(LucideIcons.search, size: 20),
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
                      isExpanded: true,
                      value: _filterStatus,
                      decoration: InputDecoration(
                        labelText: 'Holati',
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
                          child: Text('Barcha holatlar'),
                        ),
                        DropdownMenuItem(
                          value: 'Faol',
                          child: Text('Faol o‘quvchilar'),
                        ),
                        DropdownMenuItem(
                          value: 'Arxivlangan',
                          child: Text('Arxivlangan'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _filterStatus = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String?>(
                      isExpanded: true,
                      value: _filterLevel,
                      decoration: InputDecoration(
                        labelText: 'Yordam darajasi',
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
                          child: Text('Barcha darajalar'),
                        ),
                        DropdownMenuItem(
                          value: '1-daraja',
                          child: Text('1-daraja (Yengil)'),
                        ),
                        DropdownMenuItem(
                          value: '2-daraja',
                          child: Text('2-daraja (O‘rta)'),
                        ),
                        DropdownMenuItem(
                          value: '3-daraja',
                          child: Text('3-daraja (Intensiv)'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _filterLevel = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (summary != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  selected: _filterColor == null,
                  label: Text('Barchasi (${allStudents.length})'),
                  onSelected: (_) => setState(() => _filterColor = null),
                ),
                FilterChip(
                  selected: _filterColor == StatusColor.red,
                  label: Text(
                    'Qizil — Ishlanmagan (${summary.count(StatusColor.red)})',
                  ),
                  selectedColor: AppColors.error,
                  backgroundColor: AppColors.errorBg,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color:
                        _filterColor == StatusColor.red
                            ? Colors.white
                            : AppColors.error,
                  ),
                  onSelected:
                      (v) => setState(
                        () => _filterColor = v ? StatusColor.red : null,
                      ),
                ),
                FilterChip(
                  selected: _filterColor == StatusColor.yellow,
                  label: Text(
                    'Sariq — E’tibor (${summary.count(StatusColor.yellow)})',
                  ),
                  selectedColor: AppColors.warning,
                  backgroundColor: AppColors.warningBg,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color:
                        _filterColor == StatusColor.yellow
                            ? Colors.white
                            : AppColors.warning,
                  ),
                  onSelected:
                      (v) => setState(
                        () => _filterColor = v ? StatusColor.yellow : null,
                      ),
                ),
                FilterChip(
                  selected: _filterColor == StatusColor.green,
                  label: Text(
                    'Yashil — Ijobiy (${summary.count(StatusColor.green)})',
                  ),
                  selectedColor: AppColors.success,
                  backgroundColor: AppColors.successBg,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color:
                        _filterColor == StatusColor.green
                            ? Colors.white
                            : AppColors.success,
                  ),
                  onSelected:
                      (v) => setState(
                        () => _filterColor = v ? StatusColor.green : null,
                      ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // 3. BOLALAR RO'YXATI
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final s = filtered[i];
              final isArchived = s.status == 'Arxivlangan';
              final st = statusByStudentId[s.id];
              final isRed = !isArchived && st?.color == StatusColor.red;
              final stColor = st != null ? _colorFor(st.color) : null;
              final stBg = st != null ? _bgFor(st.color) : null;

              return Card(
                elevation: 0,
                color: isRed ? AppColors.errorBg : AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color:
                        !isArchived && stColor != null
                            ? stColor.withValues(alpha: isRed ? 0.55 : 0.35)
                            : AppColors.border,
                    width: isRed ? 1.5 : 1.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            isArchived
                                ? Colors.grey.shade200
                                : (stBg ?? AppColors.primaryLight),
                        child: Text(
                          s.firstName.isNotEmpty ? s.firstName[0] : 'B',
                          style: TextStyle(
                            color:
                                isArchived
                                    ? AppColors.textMuted
                                    : (stColor ?? AppColors.primary),
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  s.fullName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color:
                                        isArchived
                                            ? AppColors.textMuted
                                            : AppColors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    s.grade,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                _buildStatusPill(s.status),
                                if (!isArchived && st != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: stBg,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: stColor!.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Text(
                                      '${st.color.label}: ${st.color == StatusColor.red
                                          ? "Ishlanmagan"
                                          : st.color == StatusColor.yellow
                                          ? "E’tibor talab"
                                          : "Ijobiy"}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: stColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ehtiyoj toifasi: ${s.primaryNeed} • Qo‘llab-quvvatlash: ${s.supportLevel}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (!isArchived &&
                                st != null &&
                                st.reasons.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                'Svetofor sababi: ${st.reasons.first}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: stColor,
                                ),
                              ),
                            ],
                            const SizedBox(height: 3),
                            Text(
                              '${s.institutionName} • Tug‘ilgan: ${df.format(s.dateOfBirth)} (${s.age} yosh)',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.badge,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${s.assignedSpecialistIds.length} mutaxassis',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryLight,
                                foregroundColor: AppColors.primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => StudentDetailScreen(
                                          studentId: s.id,
                                        ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Profilni ochish',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (!isArchived) ...[
                              const SizedBox(width: 6),
                              IconButton(
                                icon: Icon(
                                  LucideIcons.archive,
                                  size: 18,
                                  color: AppColors.warning,
                                ),
                                tooltip: 'Arxivlash',
                                onPressed:
                                    () => _confirmArchiveStudent(
                                      context,
                                      s,
                                      currentUser,
                                    ),
                              ),
                            ],
                          ],
                        ),
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

  Widget _buildStatusPill(String status) {
    final isArchived = status == 'Arxivlangan';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isArchived ? AppColors.errorBg : AppColors.successBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isArchived ? AppColors.errorBorder : AppColors.successBorder,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isArchived ? AppColors.error : AppColors.success,
        ),
      ),
    );
  }

  void _confirmArchiveStudent(
    BuildContext context,
    StudentModel student,
    UserModel? byUser,
  ) {
    final app = context.read<AppProvider>();
    final reasonCtrl = TextEditingController(
      text:
          'Tibbiy-pedagogik komissiya xulosasiga binoan boshqa muassasaga o‘tkazildi',
    );

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('O‘quvchini arxivlash'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${student.fullName} anketasini arxivlash sababini kiriting:',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Arxivlash sababi *',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Bekor qilish'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: AppColors.onPrimary,
                ),
                onPressed: () async {
                  if (reasonCtrl.text.trim().isNotEmpty) {
                    Navigator.pop(ctx);
                    await app.deactivateStudent(
                      student.id,
                      reasonCtrl.text.trim(),
                      byUser: byUser,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${student.fullName} arxivlandi.'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Arxivlash'),
              ),
            ],
          ),
    );
  }
}
