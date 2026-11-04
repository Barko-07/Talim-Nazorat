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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sarlavha va vakolat eslatmasi
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Psixologik hisobdagi o‘quvchilar',
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
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${filtered.length} nafar bola',
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
                    'Kasbiy psixologik diagnostika va korreksiya uchun biriktirilgan o‘quvchilar reyestri',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              // Maxfiylik nishoni
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.lock,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Maxfiy psixologik ma’lumot',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // FILTRLAR PANELI
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, c) {
                      final search = TextField(
                        onChanged: (v) => setState(() => _search = v.trim()),
                        decoration: InputDecoration(
                          hintText: 'Ism-familiya yoki ehtiyoj toifasi...',
                          prefixIcon: const Icon(LucideIcons.search, size: 20),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                      final grade = DropdownButtonFormField<String?>(
                        value: _gradeFilter,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Sinfi',
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
                        value: _levelFilter,
                        isExpanded: true,
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
                        onChanged: (v) => setState(() => _levelFilter = v),
                      );
                      if (c.maxWidth < 560) {
                        // Telefon: qidiruv to'liq kenglikda, filtrlar ostida
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
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilterChip(
                        selected: _onlyAssignedToMe,
                        label: const Text('Faqat menga biriktirilgan bolalar'),
                        avatar: Icon(
                          _onlyAssignedToMe
                              ? LucideIcons.circleCheck
                              : LucideIcons.circleUser,
                          size: 16,
                          color:
                              _onlyAssignedToMe
                                  ? Colors.white
                                  : AppColors.primary,
                        ),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color:
                              _onlyAssignedToMe
                                  ? Colors.white
                                  : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected:
                            (val) => setState(() => _onlyAssignedToMe = val),
                      ),
                      if (summary != null) ...[
                        FilterChip(
                          selected: _statusColorFilter == StatusColor.red,
                          label: Text(
                            'Qizil — Ishlanmagan (${summary.count(StatusColor.red)})',
                          ),
                          selectedColor: AppColors.error,
                          backgroundColor: AppColors.errorBg,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color:
                                _statusColorFilter == StatusColor.red
                                    ? Colors.white
                                    : AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected:
                              (val) => setState(
                                () =>
                                    _statusColorFilter =
                                        val ? StatusColor.red : null,
                              ),
                        ),
                        FilterChip(
                          selected: _statusColorFilter == StatusColor.yellow,
                          label: Text(
                            'Sariq (${summary.count(StatusColor.yellow)})',
                          ),
                          selectedColor: AppColors.warning,
                          backgroundColor: AppColors.warningBg,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color:
                                _statusColorFilter == StatusColor.yellow
                                    ? Colors.white
                                    : AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected:
                              (val) => setState(
                                () =>
                                    _statusColorFilter =
                                        val ? StatusColor.yellow : null,
                              ),
                        ),
                        FilterChip(
                          selected: _statusColorFilter == StatusColor.green,
                          label: Text(
                            'Yashil (${summary.count(StatusColor.green)})',
                          ),
                          selectedColor: AppColors.success,
                          backgroundColor: AppColors.successBg,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color:
                                _statusColorFilter == StatusColor.green
                                    ? Colors.white
                                    : AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected:
                              (val) => setState(
                                () =>
                                    _statusColorFilter =
                                        val ? StatusColor.green : null,
                              ),
                        ),
                      ],
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
          ),
          const SizedBox(height: 16),

          // BOLALAR RO'YXATI
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    LucideIcons.searchX,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Mos keluvchi o‘quvchilar topilmadi',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Qidiruv so‘zini o‘zgartiring yoki filtrlarni tozalang',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
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

                return Card(
                  elevation: 0,
                  color: isRed ? AppColors.errorBg : AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color:
                          stColor != null
                              ? stColor.withValues(alpha: isRed ? 0.55 : 0.35)
                              : AppColors.border,
                      width: isRed ? 1.5 : 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: stBg ?? AppColors.primaryLight,
                              child: Text(
                                s.firstName.isNotEmpty ? s.firstName[0] : 'O',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
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
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        s.fullName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15.5,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceMuted,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          '${s.grade} • ${s.age} yosh',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
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
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ehtiyoj: ${s.primaryNeed} • ${s.supportLevel}',
                                    style: TextStyle(
                                      fontSize: 12,
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
                        // Harakatlar — telefonda ham sig'ishi uchun alohida qatorda
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.end,
                          children: [
                            IconButton.outlined(
                              tooltip: 'Kuzatuv qayd etish',
                              icon: const Icon(
                                LucideIcons.notebookPen,
                                size: 18,
                              ),
                              onPressed:
                                  () => widget.onSelectStudentForObservation
                                      ?.call(s),
                            ),
                            const SizedBox(width: 6),
                            IconButton.outlined(
                              tooltip: 'Diagnostika o‘tkazish',
                              icon: const Icon(LucideIcons.brain, size: 18),
                              onPressed:
                                  () => widget.onSelectStudentForAssessment
                                      ?.call(s),
                            ),
                            const SizedBox(width: 6),
                            IconButton.outlined(
                              tooltip: 'Mashg‘ulot rejalashtirish',
                              icon: const Icon(
                                LucideIcons.alarmClockPlus,
                                size: 18,
                              ),
                              onPressed:
                                  () =>
                                      widget.onSelectStudentForSession?.call(s),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
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
                                'Profil',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
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
}
