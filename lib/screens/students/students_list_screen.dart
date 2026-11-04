import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/student_model.dart';
import '../../providers/app_provider.dart';
import '../../services/access_control_service.dart';
import '../../services/child_status_service.dart';
import '../../providers/auth_provider.dart';
import 'add_student_screen.dart';
import 'student_detail_screen.dart';

// Sinf filtri variantlari. Tanlangan qiymat ro'yxatda bo'lmasa, DropdownButton xato beradi —
// shuning uchun qiymat shu ro'yxat bo'yicha tekshiriladi.
const _gradeOptions = [
  '1-A',
  '1-B',
  '2-A',
  '2-B',
  '3-A',
  '3-B',
  '4-A',
  '4-B',
  '5-A',
  '6-A',
  '7-A',
  '8-A',
  '9-A',
];

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  StatusColor? _selectedStatusColor;

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
    final rawStudents = app.students;
    final summary = app.monitoringSummary;
    final statusByStudentId = <String, ChildStatus>{
      if (summary != null)
        for (final st in summary.statuses) st.student.id: st,
    };

    final students = _selectedStatusColor == null
        ? rawStudents
        : rawStudents
              .where(
                (s) => statusByStudentId[s.id]?.color == _selectedStatusColor,
              )
              .toList();

    final canPop = Navigator.canPop(context);
    final width = MediaQuery.sizeOf(context).width;
    final mediaPadding = MediaQuery.paddingOf(context);
    final currentUser = context.watch<AuthProvider>().currentUser;
    final canAddStudent =
        currentUser != null &&
        AccessControlService().canEditStudent(currentUser, null);

    final bodyContent = ResponsivePageContainer(
      bottomPadding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdaptivePageHeader(
            title: 'Bolalar reyestri',
            subtitle:
                'Ro‘yxatda ${students.length} nafar inklyuziv ta’lim o‘quvchisi',
            // Yangi o'quvchini faqat koordinator va rahbariyat ro'yxatga oladi
            action: !canAddStudent
                ? null
                : HeaderActionButton(
                    icon: LucideIcons.userPlus,
                    label: 'Yangi o‘quvchi',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddStudentScreen(),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 9),

          // Kesib olingan shisha qidiruv va sinf filtri paneli (Mobil va desktopga mos)
          SurfaceCard(
            borderRadius: 22,
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 520;

                final searchField = TextField(
                  decoration: InputDecoration(
                    hintText:
                        'F.I.Sh. yoki ta’lim ehtiyoji bo‘yicha qidirish...',
                    prefixIcon: Icon(
                      LucideIcons.search,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    fillColor: AppColors.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 13,
                    ),
                    suffixIcon: app.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () => app.setSearchQuery(''),
                          )
                        : null,
                  ),
                  onChanged: (val) => app.setSearchQuery(val),
                );

                final gradeFilter = DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    height: 45,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: DropdownButton<String?>(
                      value: _gradeOptions.contains(app.selectedGrade)
                          ? app.selectedGrade
                          : null,
                      isExpanded: isCompact,
                      borderRadius: BorderRadius.circular(14),
                      dropdownColor: Colors.white,
                      icon: Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(
                          LucideIcons.chevronDown,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ),
                      hint: Text(
                        'Barcha sinflar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(
                            'Barcha sinflar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ..._gradeOptions.map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(
                              '$g sinf',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) => app.setFilterGrade(val),
                    ),
                  ),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isCompact) ...[
                      searchField,
                      const SizedBox(height: 10),
                      gradeFilter,
                    ] else
                      Row(
                        children: [
                          Expanded(child: searchField),
                          const SizedBox(width: 12),
                          gradeFilter,
                        ],
                      ),
                    if (summary != null) ...[
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatusFilterChip(
                              label: 'Barchasi (${rawStudents.length})',
                              color: AppColors.primary,
                              bg: AppColors.primaryLight,
                              selected: _selectedStatusColor == null,
                              onTap: () =>
                                  setState(() => _selectedStatusColor = null),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusFilterChip(
                              label:
                                  '🔴 Qizil — Ishlanmagan (${summary.count(StatusColor.red)})',
                              color: AppColors.error,
                              bg: AppColors.errorBg,
                              selected:
                                  _selectedStatusColor == StatusColor.red,
                              onTap: () => setState(
                                () => _selectedStatusColor =
                                    _selectedStatusColor == StatusColor.red
                                    ? null
                                    : StatusColor.red,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusFilterChip(
                              label:
                                  '🟡 Sariq — E’tibor (${summary.count(StatusColor.yellow)})',
                              color: AppColors.warning,
                              bg: AppColors.warningBg,
                              selected:
                                  _selectedStatusColor == StatusColor.yellow,
                              onTap: () => setState(
                                () => _selectedStatusColor =
                                    _selectedStatusColor == StatusColor.yellow
                                    ? null
                                    : StatusColor.yellow,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusFilterChip(
                              label:
                                  '🟢 Yashil — Ijobiy (${summary.count(StatusColor.green)})',
                              color: AppColors.success,
                              bg: AppColors.successBg,
                              selected:
                                  _selectedStatusColor == StatusColor.green,
                              onTap: () => setState(
                                () => _selectedStatusColor =
                                    _selectedStatusColor == StatusColor.green
                                    ? null
                                    : StatusColor.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 9),

          // Bolalar ro'yxati
          Expanded(
            child: students.isEmpty
                ? Center(
                    child: SurfaceCard(
                      borderRadius: 26,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 34,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.userSearch,
                            size: 36,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 14),
                          Text(
                            'O‘quvchilar topilmadi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Qidiruv so‘zini yoki sinf filtrini o‘zgartirib ko‘ring',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      0,
                      0,
                      width < 920 ? (84.0 + mediaPadding.bottom) : 24.0,
                    ),
                    itemCount: students.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return _buildStudentCard(
                        context,
                        student,
                        statusByStudentId[student.id],
                      );
                    },
                  ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: canPop ? AppColors.background : Colors.transparent,
      appBar: canPop
          ? AppBar(title: const Text('Bolalar elektron reyestri'))
          : null,
      body: canPop ? AmbientMeshBackground(child: bodyContent) : bodyContent,
    );
  }

  Widget _buildStatusFilterChip({
    required String label,
    required Color color,
    required Color bg,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    StudentModel s,
    ChildStatus? status,
  ) {
    final guardianText = s.guardians.isNotEmpty
        ? '${s.guardians.first.relationship}: ${s.guardians.first.fullName}'
        : 'Vasiy kiritilmagan';
    final statusColor = status != null ? _colorFor(status.color) : null;
    final statusBg = status != null ? _bgFor(status.color) : null;
    final isRed = status?.color == StatusColor.red;

    return SurfaceCard(
      borderRadius: 26,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      backgroundColor: isRed ? AppColors.errorBg : null,
      borderColor: statusColor != null
          ? statusColor.withValues(alpha: isRed ? 0.55 : 0.32)
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentDetailScreen(studentId: s.id),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: statusBg ?? AppColors.primaryLight,
            child: Text(
              s.firstName.isNotEmpty ? s.firstName.substring(0, 1) : '?',
              style: TextStyle(
                color: statusColor ?? AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        s.fullName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (status != null) ...[
                      StatusPill(
                        label: '${status.color.label}: ${status.color == StatusColor.red ? "Ishlanmagan" : status.color == StatusColor.yellow ? "E’tibor talab" : "Ijobiy"}',
                        color: statusColor!,
                        backgroundColor: statusBg!,
                        showDot: true,
                      ),
                      const SizedBox(width: 6),
                    ],
                    StatusPill(
                      label: '${s.grade}-sinf',
                      color: AppColors.primary,
                      backgroundColor: AppColors.primaryLight,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  s.primaryNeed,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                if (status != null && status.reasons.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor!.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isRed
                              ? LucideIcons.circleAlert
                              : status.color == StatusColor.yellow
                              ? LucideIcons.triangleAlert
                              : LucideIcons.circleCheck,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            status.reasons.first,
                            style: TextStyle(
                              fontSize: 11.8,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusPill(
                      label: s.supportLevel,
                      color: AppColors.info,
                      backgroundColor: AppColors.infoBg,
                      maxWidth: 230,
                    ),
                    Text(
                      '${s.age} yosh • $guardianText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.textSubtle,
            ),
          ),
        ],
      ),
    );
  }
}
