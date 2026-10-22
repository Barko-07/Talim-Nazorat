import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/iep_model.dart';
import '../../models/student_model.dart';

class IepPrintScreen extends StatelessWidget {
  final IndividualEducationPlanModel plan;
  final StudentModel student;

  const IepPrintScreen({
    super.key,
    required this.plan,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd.MM.yyyy');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Rasmiy ITR Blanki (Chop etish formati)', style: TextStyle(fontSize: 15)),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, color: AppColors.primary),
            tooltip: 'Hujjatni chop etish',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hujjat printerga yuborildi (A4 formati)'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black26),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Vazirlik va Muassasa
                  const Text(
                    'O‘ZBEKISTON RESPUBLIKASI MAKTABGACHA VA MAKTAB TA’LIMI VAZIRLIGI',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.institutionName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  const Divider(thickness: 2, color: Colors.black),
                  const SizedBox(height: 12),

                  const Text(
                    'INDIVIDUAL TA’LIM REJASI (ITR)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                  Text(
                    '${plan.academicYear} o‘quv yili uchun',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 24),

                  // 1. O'quvchi haqida ma'lumotlar jadvali
                  _buildSectionHeader('1. O‘QUVCHI HAQIDA UMUMIY MA’LUMOT'),
                  const SizedBox(height: 8),
                  _buildInfoRow('O‘quvchining to‘liq F.I.Sh.:', student.fullName),
                  _buildInfoRow('Tug‘ilgan sanasi:', '${df.format(student.dateOfBirth)} (${student.age} yosh)'),
                  _buildInfoRow('Sinfi / Guruhi:', student.grade),
                  _buildInfoRow('Asosiy ta’limiy ehtiyoj:', student.primaryNeed),
                  _buildInfoRow('Yordam darajasi:', student.supportLevel),
                  _buildInfoRow(
                    'Qonuniy vasiysi:',
                    student.guardians.isNotEmpty
                        ? '${student.guardians.first.fullName} (${student.guardians.first.relationship}), Tel: ${student.guardians.first.phone}'
                        : 'Mavjud emas',
                  ),
                  const SizedBox(height: 16),

                  // 2. Boshlang'ich daraja
                  _buildSectionHeader('2. BOSHLANG‘ICH RIVOJLANISH DARAJASI (BASELINE)'),
                  const SizedBox(height: 8),
                  Text(
                    plan.baselineSummary,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // 3. Uzoq muddatli maqsadlar
                  _buildSectionHeader('3. UZOQ MUDDATLI PEDAGOGIK MAQSADLAR'),
                  const SizedBox(height: 8),
                  Text(
                    plan.longTermGoals,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // 4. Maqsadlar jadvali
                  _buildSectionHeader('4. REJALASHTIRILGAN O‘LCHANADIGAN MAQSADLAR VA IJRO MEZONLARI'),
                  const SizedBox(height: 8),
                  Table(
                    border: TableBorder.all(color: Colors.black54),
                    columnWidths: const {
                      0: FixedColumnWidth(30),
                      1: FlexColumnWidth(4),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(2),
                      4: FlexColumnWidth(2),
                    },
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: Color(0xFFEEEEEE)),
                        children: [
                          Padding(padding: EdgeInsets.all(6), child: Text('№', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: EdgeInsets.all(6), child: Text('Maqsad mazmuni', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: EdgeInsets.all(6), child: Text('Soha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: EdgeInsets.all(6), child: Text('Muddat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          Padding(padding: EdgeInsets.all(6), child: Text('Ijro (%)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        ],
                      ),
                      ...List.generate(plan.objectives.length, (idx) {
                        final obj = plan.objectives[idx];
                        return TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(6), child: Text('${idx + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(6), child: Text('${obj.title}\n(${obj.successCriteria ?? ''})', style: const TextStyle(fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(6), child: Text(obj.domain, style: const TextStyle(fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(6), child: Text(df.format(obj.targetDate), style: const TextStyle(fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(6), child: Text('${obj.progressPercent}% (${obj.status})', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          ],
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Imzo bloklari
                  const Text('TASDIQLAYMAN:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mas’ul o‘qituvchi: ${plan.responsibleTeacherName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Imzo: ___________________', style: TextStyle(fontSize: 11)),
                          const SizedBox(height: 4),
                          Text('Sana: ${df.format(DateTime.now())}', style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Maktab direktori / O‘IBDO‘:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Imzo: ___________________', style: TextStyle(fontSize: 11)),
                          SizedBox(height: 4),
                          Text('M.O‘. (Muhr o‘rni)', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Ota-ona (Qonuniy vasiy) ITR bilan tanishdi va rozi bo‘ldi: _____________________ (Imzo)',
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: const Color(0xFFE2E8F0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
