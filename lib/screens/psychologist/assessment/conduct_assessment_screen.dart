import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/assessment_templates.dart';
import '../../../models/assessment_model.dart';
import '../../../models/assessment_question_model.dart';
import '../../../models/assessment_response_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';
import 'assessment_result_screen.dart';

class ConductAssessmentScreen extends StatefulWidget {
  final AssessmentModel assessment;
  final List<AssessmentQuestionModel> selectedQuestions;
  final bool isNew;

  const ConductAssessmentScreen({
    super.key,
    required this.assessment,
    required this.selectedQuestions,
    this.isNew = false,
  });

  @override
  State<ConductAssessmentScreen> createState() =>
      _ConductAssessmentScreenState();
}

class _ConductAssessmentScreenState extends State<ConductAssessmentScreen> {
  int _currentIndex = 0;
  late List<AssessmentQuestionModel> _questions;
  late List<AssessmentResponseModel> _responses;

  late TextEditingController _notesCtrl;
  late TextEditingController _openTextCtrl;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.selectedQuestions);

    // Agar savollar ro'yxati berilmagan bo'lsa (draft re-open qilinganda),
    // provider savollar kutubxonasidan tiklaymiz
    if (_questions.isEmpty && widget.assessment.questionIds.isNotEmpty) {
      final app = context.read<AppProvider>();
      for (final qId in widget.assessment.questionIds) {
        final found = app.getQuestionById(qId);
        if (found != null) {
          _questions.add(found);
        }
      }
    }

    // Javoblarni tiklash yoki dastlabki holatda yaratish
    if (widget.assessment.responses.isNotEmpty) {
      _responses = List.from(widget.assessment.responses);
    } else {
      _responses = _questions.map((q) {
        return AssessmentResponseModel(
          questionId: q.id,
          questionTitle: q.title,
          questionText: q.questionText,
          domain: q.domain,
          questionType: q.questionType,
          maxScore: q.maxScore,
          isEvaluated: false,
        );
      }).toList();
    }

    // Agar savollar soni responses dan ko'p bo'lsa, moslashtirish
    while (_responses.length < _questions.length) {
      final q = _questions[_responses.length];
      _responses.add(
        AssessmentResponseModel(
          questionId: q.id,
          questionTitle: q.title,
          questionText: q.questionText,
          domain: q.domain,
          questionType: q.questionType,
          maxScore: q.maxScore,
          isEvaluated: false,
        ),
      );
    }

    _notesCtrl = TextEditingController();
    _openTextCtrl = TextEditingController();
    _syncCurrentControllers();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _openTextCtrl.dispose();
    super.dispose();
  }

  void _syncCurrentControllers() {
    if (_responses.isEmpty || _currentIndex >= _responses.length) return;
    final r = _responses[_currentIndex];
    _notesCtrl.text = r.psychologistNotes ?? '';
    _openTextCtrl.text = r.answer != null ? r.answer.toString() : '';
  }

  void _saveCurrentQuestionData() {
    if (_responses.isEmpty || _currentIndex >= _responses.length) return;
    final r = _responses[_currentIndex];
    r.psychologistNotes = _notesCtrl.text.trim();
    if (r.questionType == 'open_text') {
      r.answer = _openTextCtrl.text.trim();
      r.isEvaluated = _openTextCtrl.text.trim().isNotEmpty;
    }
  }

  void _goToIndex(int index) {
    if (index < 0 || index >= _questions.length) return;
    _saveCurrentQuestionData();
    setState(() {
      _currentIndex = index;
      _syncCurrentControllers();
    });
  }

  Future<void> _saveAsDraftAndExit() async {
    _saveCurrentQuestionData();
    final app = context.read<AppProvider>();
    final auth = context.read<AuthProvider>();

    final updated = widget.assessment.copyWith(
      responses: _responses,
      status: 'draft',
      updatedAt: DateTime.now(),
    );

    if (widget.isNew) {
      await app.addAssessment(updated, byUser: auth.currentUser);
    } else {
      await app.updateAssessment(updated);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Baholash qoralamasi muvaffaqiyatli saqlandi.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showReviewAndFinalizeModal() {
    _saveCurrentQuestionData();

    final evaluatedResponses = _responses.where((r) => r.isEvaluated).toList();
    final skippedResponses = _responses.where((r) => !r.isEvaluated).toList();

    // Faqat scorable savollarning ballari
    double totalEarned = 0.0;
    double totalMax = 0.0;
    final Map<String, List<double>> domainScoresMap = {};

    for (final r in evaluatedResponses) {
      if (r.questionType != 'open_text') {
        final sc = r.score ?? 0.0;
        final mx = r.maxScore ?? 0.0;
        totalEarned += sc;
        totalMax += mx;

        domainScoresMap.putIfAbsent(r.domain, () => [0.0, 0.0]);
        domainScoresMap[r.domain]![0] += sc;
        domainScoresMap[r.domain]![1] += mx;
      }
    }

    final double percent = totalMax > 0 ? (totalEarned / totalMax) * 100.0 : 0.0;

    final conclusionCtrl = TextEditingController(
      text: widget.assessment.generalConclusion?.isNotEmpty == true
          ? widget.assessment.generalConclusion!
          : 'Diagnostika jarayonida o‘quvchining psixologik holati va individual xususiyatlari me’yoriy ko‘rsatkichlar doirasida qayd etildi.',
    );
    final recCtrl = TextEditingController(
      text: widget.assessment.recommendations.isNotEmpty
          ? widget.assessment.recommendations
          : 'Pedagog va ota-onalar bilan hamkorlikda individual yordam rejasini davom ettirish tavsiya etiladi.',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.task_alt_rounded,
                          color: Color(0xFF059669),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Natijalarni Tekshirish va Yakunlash',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Xulosani tasdiqlashdan oldin kiritilgan ma’lumotlarni ko‘rib chiqing',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ballar va javoblar statistikasi
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMetricBox(
                                  'Javob berildi',
                                  '${evaluatedResponses.length} / ${_responses.length}',
                                  const Color(0xFF059669),
                                ),
                                _buildMetricBox(
                                  'O‘tkazib yuborildi',
                                  '${skippedResponses.length} ta',
                                  skippedResponses.isEmpty
                                      ? Colors.grey
                                      : const Color(0xFFD97706),
                                ),
                                if (totalMax > 0)
                                  _buildMetricBox(
                                    'Jami ball',
                                    '${totalEarned.toStringAsFixed(1)} / ${totalMax.toStringAsFixed(0)} (${percent.toStringAsFixed(0)}%)',
                                    const Color(0xFF4F46E5),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Sohalar bo'yicha taqsimot
                          if (domainScoresMap.isNotEmpty) ...[
                            const Text(
                              'Yo‘nalishlar kesimida natijalar:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...domainScoresMap.entries.map((e) {
                              final dName = e.key;
                              final dEarned = e.value[0];
                              final dMax = e.value[1];
                              final dPct = dMax > 0 ? (dEarned / dMax) : 0.0;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          dName,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          '${dEarned.toStringAsFixed(1)} / ${dMax.toStringAsFixed(0)} ball (${(dPct * 100).toStringAsFixed(0)}%)',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4F46E5),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: dPct.clamp(0.0, 1.0),
                                        minHeight: 6,
                                        backgroundColor: const Color(0xFFE2E8F0),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF4F46E5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                          ],

                          // Umumiy psixologik xulosa
                          TextFormField(
                            controller: conclusionCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Umumiy psixologik xulosa *',
                              hintText:
                                  'O‘quvchining diagnostika davridagi umumiy holati va xulosasi...',
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Korreksion tavsiyalar
                          TextFormField(
                            controller: recCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText:
                                  'Korreksion-rivojlantiruvchi tavsiyalar *',
                              hintText:
                                  'Tavsiya etilayotgan mashg‘ulotlar, ota-onalar va o‘qituvchilar uchun tavsiyalar...',
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Rasmiy ogohlantirish
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: Color(0xFFD97706),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AssessmentTemplates.disclaimerNotice,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Savollarga qaytish'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('Baholashni to‘liq yakunlash'),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _finalizeAssessment(
                            totalScore: totalEarned,
                            maxScore: totalMax > 0
                                ? totalMax
                                : widget.assessment.maxScore,
                            generalConclusion: conclusionCtrl.text.trim(),
                            recommendations: recCtrl.text.trim(),
                            domainScores: domainScoresMap.map(
                              (k, v) => MapEntry(
                                k,
                                v[1] > 0 ? (v[0] / v[1]) * 100.0 : 0.0,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _finalizeAssessment({
    required double totalScore,
    required double maxScore,
    required String generalConclusion,
    required String recommendations,
    required Map<String, double> domainScores,
  }) async {
    final app = context.read<AppProvider>();
    final auth = context.read<AuthProvider>();

    // Mezonlar ro'yxatini shakllantirish
    final criteria = domainScores.entries.map((e) {
      return AssessmentCriterionResult(
        criterionName: e.key,
        score: e.value,
        maxScore: 100.0,
      );
    }).toList();

    final completed = widget.assessment.copyWith(
      responses: _responses,
      totalScore: totalScore,
      maxScore: maxScore,
      generalConclusion: generalConclusion,
      notes: generalConclusion,
      recommendations: recommendations,
      domainScores: domainScores,
      criteria: criteria,
      status: 'completed',
      assessmentDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.isNew) {
      await app.addAssessment(completed, byUser: auth.currentUser);
    } else {
      await app.updateAssessment(completed);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Psixologik baholash muvaffaqiyatli yakunlandi!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Natijalar ekraniga o'tish
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AssessmentResultScreen(assessment: completed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Baholash jarayoni')),
        body: const Center(
          child: Text('Baholash uchun savollar topilmadi.'),
        ),
      );
    }

    final currentQuestion = _questions[_currentIndex];
    final currentResponse = _responses[_currentIndex];
    final answeredCount = _responses.where((r) => r.isEvaluated).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.assessment.studentName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.assessment.title} • Savol ${_currentIndex + 1} / ${_questions.length}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.bookmark_outline_rounded, size: 18),
            label: const Text('Qoralama saqlash'),
            onPressed: _saveAsDraftAndExit,
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
            ),
            icon: const Icon(Icons.checklist_rounded, size: 18),
            label: const Text('Yakunlash'),
            onPressed: _showReviewAndFinalizeModal,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tezkor navigatsiya paneli (Pill buttons)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Javob berildi: $answeredCount / ${_questions.length} ta',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    // Savollar raqamlari qatori
                    Wrap(
                      spacing: 6,
                      children: List.generate(_questions.length, (idx) {
                        final isCur = idx == _currentIndex;
                        final isAns = _responses[idx].isEvaluated;

                        return InkWell(
                          onTap: () => _goToIndex(idx),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isCur
                                  ? const Color(0xFF4F46E5)
                                  : isAns
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isCur
                                    ? const Color(0xFF4F46E5)
                                    : isAns
                                        ? const Color(0xFF059669)
                                        : AppColors.border,
                              ),
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isCur
                                    ? Colors.white
                                    : isAns
                                        ? const Color(0xFF059669)
                                        : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Asosiy Savol Kartasi
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Yo'nalish va yosh teglari
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                currentQuestion.domain,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                currentQuestion.safeAgeRange,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            const Spacer(),
                            // O'tkazib yuborish / Baholanmadi tugmasi
                            Row(
                              children: [
                                const Text(
                                  'Baholanmadi:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                Switch(
                                  value: !currentResponse.isEvaluated,
                                  activeColor: const Color(0xFFD97706),
                                  onChanged: (val) {
                                    setState(() {
                                      currentResponse.isEvaluated = !val;
                                      if (val) {
                                        currentResponse.answer = null;
                                        currentResponse.score = 0.0;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Savol nomi va matni
                        Text(
                          currentQuestion.questionTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentQuestion.questionText,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 20),

                        // Savol turiga mos interaktiv javob kiritish
                        if (!currentResponse.isEvaluated)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFFD97706),
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Ushbu savol o‘tkazib yuborildi ("Baholanmadi"). '
                                    'U umumiy ball hisobiga nol deb olinmaydi va natijalarga salbiy ta’sir ko‘rsatmaydi.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          _buildInteractiveAnswerInput(
                            currentQuestion,
                            currentResponse,
                          ),

                        const SizedBox(height: 24),

                        // Psixolog kuzatuv izohi (Har bir savol uchun)
                        TextFormField(
                          controller: _notesCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText:
                                'Psixolog kuzatuv qaydi (ushbu savol bo‘yicha)',
                            hintText:
                                'Bolaning topshiriqqa munosabati, mimikasi, ikkilanishlari yoki xatti-harakati...',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 24),
                              child: Icon(Icons.comment_outlined, size: 20),
                            ),
                          ),
                        ),

                        // Agar metodik ko'rsatma bo'lsa
                        if (currentQuestion.safeNotes.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.tips_and_updates_outlined,
                                  size: 16,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Metodik ko‘rsatma: ${currentQuestion.safeNotes}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Pastki Tugmalar (Oldingi / Keyingi)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _currentIndex > 0
                          ? () => _goToIndex(_currentIndex - 1)
                          : null,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Oldingi savol'),
                    ),
                    if (_currentIndex < _questions.length - 1)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => _goToIndex(_currentIndex + 1),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Keyingi savol'),
                      )
                    else
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: _showReviewAndFinalizeModal,
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('Ko‘rib chiqish & Yakunlash'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveAnswerInput(
    AssessmentQuestionModel q,
    AssessmentResponseModel r,
  ) {
    if (q.questionType == 'yes_no') {
      return Row(
        children: q.options.map((opt) {
          final isSelected = r.answer == opt.text;
          final isYes = opt.text.toLowerCase().contains('ha');

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: InkWell(
                onTap: () {
                  setState(() {
                    r.answer = opt.text;
                    r.score = opt.score;
                    r.isEvaluated = true;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isYes
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF2F2))
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? (isYes
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626))
                          : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isYes
                            ? Icons.check_circle_outline_rounded
                            : Icons.cancel_outlined,
                        size: 28,
                        color: isSelected
                            ? (isYes
                                ? const Color(0xFF059669)
                                : const Color(0xFFDC2626))
                            : Colors.grey,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        opt.text,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isSelected
                              ? (isYes
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFDC2626))
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${opt.score.toStringAsFixed(0)} ball',
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? (isYes
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFDC2626))
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    } else if (q.questionType == 'single_choice') {
      return Column(
        children: q.options.map((opt) {
          final isSelected = r.answer == opt.text;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? const Color(0xFF4F46E5) : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: RadioListTile<String>(
              value: opt.text,
              groupValue: r.answer,
              activeColor: const Color(0xFF4F46E5),
              title: Text(
                opt.text,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              secondary: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${opt.score.toStringAsFixed(opt.score.truncateToDouble() == opt.score ? 0 : 1)} b',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    r.answer = val;
                    r.score = opt.score;
                    r.isEvaluated = true;
                  });
                }
              },
            ),
          );
        }).toList(),
      );
    } else if (q.questionType == 'multiple_choice') {
      final selectedList =
          (r.answer ?? '').split(';').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bir nechta mos keluvchi variantlarni belgilang:',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          ...q.options.map((opt) {
            final isChecked = selectedList.contains(opt.text);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isChecked ? const Color(0xFFEEF2FF) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isChecked ? const Color(0xFF4F46E5) : AppColors.border,
                  width: isChecked ? 1.5 : 1,
                ),
              ),
              child: CheckboxListTile(
                value: isChecked,
                activeColor: const Color(0xFF4F46E5),
                title: Text(
                  opt.text,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                secondary: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isChecked
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${opt.score.toStringAsFixed(0)} b',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isChecked ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      if (!selectedList.contains(opt.text)) {
                        selectedList.add(opt.text);
                      }
                    } else {
                      selectedList.remove(opt.text);
                    }

                    r.answer = selectedList.join('; ');
                    double sum = 0.0;
                    for (final o in q.options) {
                      if (selectedList.contains(o.text)) {
                        sum += o.score;
                      }
                    }
                    r.score = sum;
                    r.isEvaluated = selectedList.isNotEmpty;
                  });
                },
              ),
            );
          }),
        ],
      );
    } else if (q.questionType == 'scale_1_5') {
      final currentVal = (r.score != null && r.score! > 0) ? r.score!.round() : 3;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '1 dan 5 gacha bo‘lgan shkala bo‘yicha baholang:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$currentVal ball',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (i) {
              final val = i + 1;
              final isSel = r.isEvaluated && currentVal == val;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        r.score = val.toDouble();
                        r.answer = '$val ball';
                        r.isEvaluated = true;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSel
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSel
                              ? const Color(0xFF4F46E5)
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        '$val',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 — Minimal / Namoyon bo‘lmadi',
                style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              ),
              Text(
                '5 — Maksimal / Mustaqil bajaradi',
                style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      );
    } else {
      // open_text
      return TextFormField(
        controller: _openTextCtrl,
        maxLines: 4,
        onChanged: (v) {
          r.answer = v.trim();
          r.isEvaluated = v.trim().isNotEmpty;
        },
        decoration: const InputDecoration(
          labelText: 'Psixologik kuzatuv yoki bolaning erkin javobi *',
          hintText:
              'Topshiriq yechimi, bolaning nutqiy izohi, qiyinchiliklar va natija xususiyatlari...',
          alignLabelWithHint: true,
        ),
      );
    }
  }

  Widget _buildMetricBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
