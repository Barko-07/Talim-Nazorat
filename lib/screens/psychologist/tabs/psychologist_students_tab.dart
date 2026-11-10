import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/student_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/child_status_service.dart';
import '../../students/student_detail_screen.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/glass_widgets.dart';

class PsychologistStudentsTab extends StatefulWidget {
  final Function(StudentModel student)? onSelectStudentForObservation;
  final Function(StudentModel student)? onSelectStudentForAssessment;
  final Function(StudentModel student)? onSelectStudentForSession;

  const PsychologistStudentsTab({
    super.key,
    this.onSelectStudentForObservation,
    this.onSelectStudentForAssessment,
    this.onSelectStudentForSession,
  });

  @override
  State<PsychologistStudentsTab> createState() =>
      _PsychologistStudentsTabState();
}

class _PsychologistStudentsTabState extends State<PsychologistStudentsTab> {
  String _search = '';
  String? _gradeFilter;
  String? _levelFilter;
  bool _onlyAssignedToMe = false;
  StatusColor? _statusColorFilter;

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
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final currentUser = auth.currentUser;
    final allAllowedStudents = app.students;
    final summary = app.monitoringSummary;
    final statusByStudentId = <String, ChildStatus>{
      if (summary != null)
        for (final st in summary.statuses) st.student.id: st,
    };

    // Filtrlash (Psixolog vakolati doirasida)
    final filtered =
        allAllowedStudents.where((s) {
          if (_onlyAssignedToMe && currentUser != null) {
            final isAssigned =
                s.assignedSpecialistIds.contains(currentUser.id) ||
                currentUser.assignedStudentIds.contains(s.id);
            if (!isAssigned) return false;
          }
          if (_statusColorFilter != null &&
              statusByStudentId[s.id]?.color != _statusColorFilter) {
            return false;
          }
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            final mName = s.fullName.toLowerCase().contains(q);
            final mNeed = s.primaryNeed.toLowerCase().contains(q);
            if (!mName && !mNeed) return false;
          }
          if (_gradeFilter != null && s.grade != _gradeFilter) return false;
          if (_levelFilter != null && !s.supportLevel.contains(_levelFilter!)) {
            return false;
          }
          return true;
        }).toList();

    final width = MediaQuery.sizeOf(context).width;
    final horizontalPad = width < 600 ? 12.0 : 18.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPad,
        MediaQuery.paddingOf(context).top + (width >= 920 ? 82 : 74),
        horizontalPad,
        width < 920 ? (84 + MediaQuery.paddingOf(context).bottom) : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sarlavha va vakolat eslatmasi (Minimalist Glassy Header)
          SurfaceCard(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusPill(
                      label: '${filtered.length} nafar bola',
                      color: AppColors.primary,
                      backgroundColor: AppColors.primaryLight,
                      icon: LucideIcons.users,
                    ),
                    StatusPill(
                      label: 'Maxfiy psixologik ma’lumot',
                      color: AppColors.textSecondary,
                      backgroundColor: AppColors.surfaceMuted,
                      icon: LucideIcons.lock,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Psixologik hisobdagi o‘quvchilar',
                  style: TextStyle(
                    fontSize: width < 600 ? 18.5 : 21,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kasbiy psixologik diagnostika va korreksiya uchun biriktirilgan o‘quvchilar reyestri',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // FILTRLAR PANELI
          SurfaceCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, c) {
                    InputDecoration inputDeco({
                      String? label,
                      String? hint,
                      Widget? prefixIcon,
                    }) {
                      return InputDecoration(
                        labelText: label,
                        hintText: hint,
                        prefixIcon: prefixIcon,
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
                      );
                    }

                    final search = TextField(
                      onChanged: (v) => setState(() => _search = v.trim()),
                      decoration: inputDeco(
                        hint: 'Ism-familiya yoki ehtiyoj toifasi...',
                        prefixIcon: const Icon(LucideIcons.search, size: 18),
                      ),
                    );
                    final grade = DropdownButtonFormField<String?>(
                      initialValue: _gradeFilter,
                      isExpanded: true,
                      decoration: inputDeco(label: 'Sinfi'),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Barcha sinflar'),
                        ),
                        DropdownMenuItem(
                          value: '1-A',
                          child: Text('1-A sinf'),
                        ),
                        DropdownMenuItem(
                          value: '2-B',
                          child: Text('2-B sinf'),
                        ),
                        DropdownMenuItem(
                          value: '3-A',
                          child: Text('3-A sinf'),
                        ),
                        DropdownMenuItem(
                          value: '4-A',
                          child: Text('4-A sinf'),
                        ),
                        DropdownMenuItem(
                          value: '5-A',
                          child: Text('5-A sinf'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _gradeFilter = v),
                    );
                    final support = DropdownButtonFormField<String?>(
                      initialValue: _levelFilter,
                      isExpanded: true,
                      decoration: inputDeco(label: 'Yordam darajasi'),
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
                      onChanged: (v) => setState(() => _levelFilter = v),
                    );
                    if (c.maxWidth < 560) {
                      return Column(
                        children: [
                          search,
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: grade),
                              const SizedBox(width: 10),
                              Expanded(child: support),
                            ],
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(flex: 3, child: search),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: grade),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: support),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ModernPillFilterBar(
                      items: const [
                        'Barcha bolalar',
                        'Menga biriktirilganlar',
                      ],
                      selectedItem:
                          _onlyAssignedToMe
                              ? 'Menga biriktirilganlar'
                              : 'Barcha bolalar',
                      onSelected:
                          (v) => setState(
                            () =>
                                _onlyAssignedToMe =
                                    v == 'Menga biriktirilganlar',
                          ),
                    ),
                    if (summary != null)
                      ModernPillFilterBar(
                        items: const ['Barchasi', 'Qizil', 'Sariq', 'Yashil'],
                        selectedItem:
                            _statusColorFilter == StatusColor.red
                                ? 'Qizil'
                                : _statusColorFilter == StatusColor.yellow
                                ? 'Sariq'
                                : _statusColorFilter == StatusColor.green
                                ? 'Yashil'
                                : 'Barchasi',
                        counts: {
                          'Barchasi': summary.total,
                          'Qizil': summary.count(StatusColor.red),
                          'Sariq': summary.count(StatusColor.yellow),
                          'Yashil': summary.count(StatusColor.green),
                        },
                        itemColors: {
                          'Qizil': AppColors.error,
                          'Sariq': AppColors.warning,
                          'Yashil': AppColors.success,
                        },
                        onSelected: (v) {
                          setState(() {
                            if (v == 'Qizil') {
                              _statusColorFilter = StatusColor.red;
                            } else if (v == 'Sariq') {
                              _statusColorFilter = StatusColor.yellow;
                            } else if (v == 'Yashil') {
                              _statusColorFilter = StatusColor.green;
                            } else {
                              _statusColorFilter = null;
                            }
                          });
                        },
                      ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _search = '';
                          _gradeFilter = null;
                          _levelFilter = null;
                          _onlyAssignedToMe = false;
                          _statusColorFilter = null;
                        });
                      },
                      child: const Text(
                        'Filtrlarni tozalash',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // BOLALAR RO'YXATI
          if (filtered.isEmpty)
            SurfaceCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.searchX,
                      size: 44,
                      color: AppColors.textSubtle,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Mos keluvchi o‘quvchilar topilmadi',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qidiruv so‘zini o‘zgartiring yoki filtrlarni tozalang',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final s = filtered[i];
                final st = statusByStudentId[s.id];
                final isRed = st?.color == StatusColor.red;
                final stColor = st != null ? _colorFor(st.color) : null;
                final stBg = st != null ? _bgFor(st.color) : null;
                final isAssigned =
                    currentUser != null &&
                    (s.assignedSpecialistIds.contains(currentUser.id) ||
                        currentUser.assignedStudentIds.contains(s.id));

                return SurfaceCard(
                  borderRadius: 22,
                  padding: const EdgeInsets.all(18),
                  backgroundColor:
                      isRed ? AppColors.errorBg.withValues(alpha: 0.72) : null,
                  borderColor:
                      stColor != null
                          ? stColor.withValues(alpha: isRed ? 0.55 : 0.35)
                          : AppColors.cardGlassBorder,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: stBg ?? AppColors.primaryLight,
                            child: Text(
                              s.firstName.isNotEmpty ? s.firstName[0] : 'O',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: stColor ?? AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      s.fullName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15.5,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    StatusPill(
                                      label: '${s.grade} • ${s.age} yosh',
                                      color: AppColors.textSecondary,
                                      backgroundColor: AppColors.surfaceMuted,
                                    ),
                                    if (st != null)
                                      StatusBadge.child(
                                        st.color,
                                        '${st.color.label}: ${st.color == StatusColor.red
                                            ? "Ishlanmagan"
                                            : st.color == StatusColor.yellow
                                            ? "E’tibor talab"
                                            : "Ijobiy"}',
                                      ),
                                    if (isAssigned)
                                      const StatusBadge(
                                        'Sizga biriktirilgan',
                                        tone: StatusTone.primary,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Ehtiyoj: ${s.primaryNeed} • ${s.supportLevel}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (st != null && st.reasons.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Holat sababi: ${st.reasons.first}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: stColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          IconButton.outlined(
                            tooltip: 'Kuzatuv qayd etish',
                            icon: const Icon(
                              LucideIcons.notebookPen,
                              size: 17,
                            ),
                            onPressed:
                                () => widget.onSelectStudentForObservation
                                    ?.call(s),
                          ),
                          IconButton.outlined(
                            tooltip: 'Diagnostika o‘tkazish',
                            icon: const Icon(LucideIcons.brain, size: 17),
                            onPressed:
                                () => widget.onSelectStudentForAssessment
                                    ?.call(s),
                          ),
                          IconButton.outlined(
                            tooltip: 'Mashg‘ulot rejalashtirish',
                            icon: const Icon(
                              LucideIcons.alarmClockPlus,
                              size: 17,
                            ),
                            onPressed:
                                () =>
                                    widget.onSelectStudentForSession?.call(s),
                          ),
                          HeaderActionButton(
                            label: 'Profil',
                            icon: LucideIcons.user,
                            variant: HeaderActionVariant.secondary,
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
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
