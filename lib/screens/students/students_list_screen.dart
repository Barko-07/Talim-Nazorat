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

    final bodyContent = ResponsivePageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdaptivePageHeader(
            title: 'Bolalar reyestri',
            subtitle:
                'Ro‘yxatda ${students.length} nafar inklyuziv ta’lim o‘quvchisi',
            action: HeaderActionButton(
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
          const SizedBox(height: 16),

          // Kesib olingan shisha qidiruv va sinf filtri paneli (Mobil va desktopga mos)
          SurfaceCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 520;

                final searchField = TextField(
                  decoration: InputDecoration(
                    hintText:
                        'F.I.Sh. yoki ta’lim ehtiyoji bo‘yicha qidirish...',
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    fillColor: const Color(0xFFF9FAFC),
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
                      color: const Color(0xFFF9FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: DropdownButton<String?>(
                      value: app.selectedGrade,
                      isExpanded: isCompact,
                      borderRadius: BorderRadius.circular(14),
                      dropdownColor: Colors.white,
                      icon: const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(
                          LucideIcons.chevronDown,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ),
                      hint: const Text(
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
                        ...['1-A', '2-A', '2-B', '3-A', '3-B', '4-A'].map(
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

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchField,
                      const SizedBox(height: 10),
                      gradeFilter,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: 12),
                    gradeFilter,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // Bolalar ro'yxati
          Expanded(
            child: students.isEmpty
                ? Center(
                    child: SurfaceCard(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 34,
                      ),
                      child: const Column(
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
                              fontWeight: FontWeight.w800,
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
                    itemCount: students.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return _buildStudentCard(context, student);
                    },
                  ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: canPop ? AppColors.background : Colors.transparent,
      appBar: canPop
          ? AppBar(
              title: const Text('Bolalar elektron reyestri'),
            )
          : null,
      body: canPop ? AmbientMeshBackground(child: bodyContent) : bodyContent,
    );
  }

  Widget _buildStudentCard(BuildContext context, StudentModel s) {
    final guardianText = s.guardians.isNotEmpty
        ? '${s.guardians.first.relationship}: ${s.guardians.first.fullName}'
        : 'Vasiy kiritilmagan';

    return SurfaceCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(18),
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
            backgroundColor: AppColors.primaryLight,
            child: Text(
              s.firstName.isNotEmpty ? s.firstName.substring(0, 1) : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
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
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
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
                      style: const TextStyle(
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
          const Padding(
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
