import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/student_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/access_control_service.dart';
import '../../services/child_status_service.dart';
import 'add_student_screen.dart';
import 'student_detail_screen.dart';

/// "Bolalar": foydalanuvchi ko'ra oladigan bolalar ro'yxati. Holat (svetofor)
/// har bolada bitta nuqta va qisqa nom bilan; filtr va ro'yxat bitta ramkada.
class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  StatusColor? _status;

  /// Sinflar ro'yxati — bolalarga kiritilgan haqiqiy sinflardan ("3-B", "5-A"…).
  static List<String> _gradesOf(List<StudentModel> all) {
    final set = {
      for (final s in all)
        if (s.status != 'Arxivlangan' && s.grade.trim().isNotEmpty)
          s.grade.trim(),
    };
    int num(String g) =>
        int.tryParse(RegExp(r'\d+').stringMatch(g) ?? '') ?? 99;
    return set.toList()..sort((a, b) {
      final c = num(a).compareTo(num(b));
      return c != 0 ? c : a.compareTo(b);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final summary = app.monitoringSummary;
    final statusById = <String, ChildStatus>{
      if (summary != null)
        for (final st in summary.statuses) st.student.id: st,
    };
    final found = app.students;
    final students =
        _status == null
            ? found
            : found.where((s) => statusById[s.id]?.color == _status).toList();
    final grades = _gradesOf(app.allStudentsIncludingArchived);

    final canPop = Navigator.canPop(context);
    final width = MediaQuery.sizeOf(context).width;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final me = context.watch<AuthProvider>().currentUser;
    final canAdd =
        me != null && AccessControlService().canEditStudent(me, null);

    int count(StatusColor? c) =>
        c == null
            ? found.length
            : found.where((s) => statusById[s.id]?.color == c).length;

    String chipName(StatusColor? c) => c == null ? 'Hammasi' : c.short;

    // Ramka telefondagi pastki menyu ustida tugaydi: oxiri yashirinmaydi.
    final body = ResponsivePageContainer(
      bottomPadding: width < 920 ? 92 + bottomInset : 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdaptivePageHeader(
            title: 'Bolalar',
            icon: LucideIcons.users,
            subtitle: '${found.length} nafar',
            action:
                !canAdd
                    ? null
                    : HeaderActionButton(
                      icon: LucideIcons.userPlus,
                      label: 'Bola qo‘shish',
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddStudentScreen(),
                            ),
                          ),
                    ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SurfaceCard(
              borderRadius: 20,
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final narrow = c.maxWidth < 520;
                        final search = TextField(
                          onChanged: app.setSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Ism yoki familiya',
                            isDense: true,
                            prefixIcon: Icon(
                              LucideIcons.search,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            suffixIcon:
                                app.searchQuery.isEmpty
                                    ? null
                                    : IconButton(
                                      tooltip: 'Tozalash',
                                      icon: const Icon(LucideIcons.x, size: 16),
                                      onPressed: () => app.setSearchQuery(''),
                                    ),
                          ),
                        );
                        final grade = SizedBox(
                          width: narrow ? double.infinity : 180,
                          child: DropdownButtonFormField<String?>(
                            initialValue:
                                grades.contains(app.selectedGrade)
                                    ? app.selectedGrade
                                    : null,
                            isExpanded: true,
                            isDense: true,
                            decoration: const InputDecoration(isDense: true),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Barcha sinflar'),
                              ),
                              for (final g in grades)
                                DropdownMenuItem(
                                  value: g,
                                  child: Text('$g sinf'),
                                ),
                            ],
                            onChanged: app.setFilterGrade,
                          ),
                        );
                        return narrow
                            ? Column(
                              children: [
                                search,
                                const SizedBox(height: 8),
                                grade,
                              ],
                            )
                            : Row(
                              children: [
                                Expanded(child: search),
                                const SizedBox(width: 12),
                                grade,
                              ],
                            );
                      },
                    ),
                  ),
                  if (summary != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in <StatusColor?>[
                            null,
                            StatusColor.red,
                            StatusColor.yellow,
                            StatusColor.green,
                          ])
                            _StatusChip(
                              label: chipName(c),
                              dot:
                                  c == null
                                      ? null
                                      : ChildStatusLabel.dotColor(c),
                              count: count(c),
                              selected: _status == c,
                              onTap: () => setState(() => _status = c),
                            ),
                        ],
                      ),
                    ),
                  Divider(height: 1, color: AppColors.border),
                  Expanded(
                    child:
                        students.isEmpty
                            ? _Empty(
                              searching:
                                  app.searchQuery.isNotEmpty ||
                                  app.selectedGrade != null ||
                                  _status != null,
                            )
                            : ListView.separated(
                              padding: EdgeInsets.only(bottom: 8),
                              itemCount: students.length,
                              separatorBuilder:
                                  (_, _) => Divider(
                                    height: 1,
                                    indent: 72,
                                    color: AppColors.border,
                                  ),
                              itemBuilder:
                                  (context, i) => _ChildRow(
                                    student: students[i],
                                    status: statusById[students[i].id],
                                    wide: width >= 720,
                                  ),
                            ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: width < 920 ? 0 : 16),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: canPop ? AppColors.background : Colors.transparent,
      appBar: canPop ? AppBar(title: const Text('Bolalar')) : null,
      body: canPop ? AmbientMeshBackground(child: body) : body,
    );
  }
}

/// Holat filtri: tanlanganda faqat chegara va matn qalinlashadi —
/// rang o'zgarmaydi (rang faqat nuqtada).
class _StatusChip extends StatelessWidget {
  final String label;
  final Color? dot;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.dot,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildRow extends StatelessWidget {
  final StudentModel student;
  final ChildStatus? status;
  final bool wide;

  const _ChildRow({
    required this.student,
    required this.status,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    final s = student;
    final initials =
        s.fullName
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0])
            .join()
            .toUpperCase();
    return InkWell(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentDetailScreen(studentId: s.id),
            ),
          ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      '${s.grade} sinf',
                      '${s.age} yosh',
                      if (s.primaryNeed.isNotEmpty) s.primaryNeed,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (status != null) ...[
              const SizedBox(width: 12),
              ChildStatusLabel(
                status!.color,
                reason:
                    wide && status!.reasons.isNotEmpty
                        ? status!.reasons.first
                        : null,
                align: CrossAxisAlignment.end,
              ),
            ],
            const SizedBox(width: 8),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.textSubtle,
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final bool searching;
  const _Empty({required this.searching});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.userSearch, size: 32, color: AppColors.textSubtle),
            const SizedBox(height: 12),
            Text(
              searching ? 'Bola topilmadi' : 'Hali bola qo‘shilmagan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              searching
                  ? 'Boshqa ism yoki sinfni tanlang'
                  : 'Bolalar shu yerda ko‘rinadi',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
