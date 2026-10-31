import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/student_model.dart';
import '../../providers/app_provider.dart';
import 'add_student_screen.dart';
import 'student_detail_screen.dart';

class StudentsListScreen extends StatelessWidget {
  const StudentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final students = app.students;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: canPop ? AppColors.background : Colors.transparent,
      appBar: canPop
          ? AppBar(
              title: const Text('Bolalar elektron reyestri'),
            )
          : null,
      body: ResponsivePageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdaptivePageHeader(
              icon: LucideIcons.users,
              title: 'Bolalar elektron reyestri',
              subtitle:
                  'Jami ${students.length} nafar inklyuziv ta’limdagi o‘quvchi ro‘yxatda',
              action: FilledButton.icon(
                icon: const Icon(LucideIcons.userPlus, size: 16),
                label: const Text('Yangi o‘quvchi'),
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
            const SizedBox(height: 16),

            // Qidiruv va Sinf filtri paneli
            SurfaceCard(
              elevated: false,
              borderRadius: 16,
              padding: const EdgeInsets.all(10),
              backgroundColor: Colors.white.withValues(alpha: 0.86),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'F.I.Sh. yoki ta’lim ehtiyoji bo‘yicha qidirish...',
                        prefixIcon: const Icon(
                          LucideIcons.search,
                          size: 17,
                          color: AppColors.textMuted,
                        ),
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        suffixIcon: app.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 15),
                                onPressed: () => app.setSearchQuery(''),
                              )
                            : null,
                      ),
                      onChanged: (val) => app.setSearchQuery(val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: AppColors.hairlineBorder),
                      ),
                      child: DropdownButton<String?>(
                        value: app.selectedGrade,
                        borderRadius: BorderRadius.circular(14),
                        icon: const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            LucideIcons.chevronDown,
                            size: 15,
                            color: AppColors.textMuted,
                          ),
                        ),
                        hint: const Text(
                          'Sinf',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text(
                              'Barcha sinflar',
                              style: TextStyle(fontSize: 12.5),
                            ),
                          ),
                          ...['1-A', '2-A', '2-B', '3-A', '3-B', '4-A'].map(
                            (g) => DropdownMenuItem(
                              value: g,
                              child: Text(
                                '$g sinf',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) => app.setFilterGrade(val),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Bolalar ro'yxati
            Expanded(
              child: students.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: AppColors.hairlineBorder),
                            ),
                            child: const Icon(
                              LucideIcons.userSearch,
                              size: 26,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'O‘quvchilar topilmadi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Qidiruv so‘zini yoki sinf filtrini o‘zgartirib ko‘ring',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: students.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return _buildStudentCard(context, student);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, StudentModel s) {
    final guardianText = s.guardians.isNotEmpty
        ? '${s.guardians.first.relationship}: ${s.guardians.first.fullName}'
        : 'Vasiy kiritilmagan';

    return SurfaceCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentDetailScreen(studentId: s.id),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryLight, AppColors.primaryTint],
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.14),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              s.firstName.isNotEmpty ? s.firstName.substring(0, 1) : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(
                      label: '${s.grade}-sinf',
                      color: AppColors.textSecondary,
                      backgroundColor: AppColors.background,
                      borderColor: AppColors.border,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  s.primaryNeed,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusPill(
                      label: s.supportLevel,
                      color: AppColors.info,
                      backgroundColor: AppColors.infoBg,
                      borderColor: AppColors.infoBorder,
                    ),
                    Text(
                      '${s.age} yosh • $guardianText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            LucideIcons.chevronRight,
            size: 18,
            color: AppColors.textSubtle,
          ),
        ],
      ),
    );
  }
}
