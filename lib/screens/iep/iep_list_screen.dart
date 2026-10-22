import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/iep_model.dart';
import '../../providers/app_provider.dart';
import 'iep_print_screen.dart';

class IepListScreen extends StatelessWidget {
  const IepListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final plans = app.iepPlans;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Individual Ta’lim Rejalari (ITR)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Alohida ta’lim ehtiyoji bo‘lgan o‘quvchilarning shaxsiy ta’limiy rejalari (${plans.length} ta)',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: plans.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.menu_book_outlined, size: 48, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text('Hozircha ITR rejalari mavjud emas', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: plans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final p = plans[index];
                        final student = app.students.firstWhere(
                          (s) => s.id == p.studentId,
                          orElse: () => app.students.first,
                        );
                        return _buildIepCard(context, p, student);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIepCard(BuildContext context, IndividualEducationPlanModel p, dynamic student) {
    final app = context.watch<AppProvider>();
    final df = DateFormat('dd.MM.yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'O‘quvchi: ${p.studentName} (${p.studentGrade}) • O‘quv yili: ${p.academicYear}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        'Mas’ul o‘qituvchi: ${p.responsibleTeacherName} • Muddat: ${df.format(p.startDate)} — ${df.format(p.reviewDate)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text('Rasmiy Blank'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IepPrintScreen(plan: p, student: student),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Boshlang'ich daraja va Maqsadlar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Boshlang‘ich daraja (Baseline): ${p.baselineSummary}', style: const TextStyle(fontSize: 12, height: 1.3)),
                  const SizedBox(height: 4),
                  Text('Uzoq muddatli maqsad: ${p.longTermGoals}', style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Maqsadlar ro'yxati
            const Text('O‘lchanadigan oraliq maqsadlar ijrosi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),

            ...p.objectives.map((obj) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(obj.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${obj.domain} • ${obj.status}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Slider(
                        value: obj.progressPercent.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        activeColor: AppColors.primary,
                        label: '${obj.progressPercent}%',
                        onChanged: (val) {
                          app.updateObjectiveProgress(p.id, obj.id, val.toInt());
                        },
                      ),
                    ),
                    Text('${obj.progressPercent}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
