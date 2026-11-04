import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/session_model.dart';
import '../../../models/student_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';

class PsychologistSessionsTab extends StatefulWidget {
  final VoidCallback? onScheduleNew;

  const PsychologistSessionsTab({super.key, this.onScheduleNew});

  @override
  State<PsychologistSessionsTab> createState() =>
      _PsychologistSessionsTabState();
}

class _PsychologistSessionsTabState extends State<PsychologistSessionsTab> {
  String _searchQuery = '';
  String _selectedStatus = 'Barchasi';
  String _selectedType = 'Barchasi';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statuses = [
    'Barchasi',
    'Rejalashtirilgan',
    'Bajarildi',
    'Qatnashmadi',
    'Bekor qilindi',
  ];

  final List<String> _types = ['Barchasi', 'Individual', 'Kichik guruhda'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    final allSessions = app.sessions;
    final students = app.students;

    final now = DateTime.now();

    // Filtrlash
    final filteredSessions =
        allSessions.where((s) {
          final matchesStatus =
              _selectedStatus == 'Barchasi' || s.status == _selectedStatus;
          final matchesType =
              _selectedType == 'Barchasi' || s.sessionType == _selectedType;
          final q = _searchQuery.toLowerCase().trim();
          final matchesSearch =
              q.isEmpty ||
              s.studentName.toLowerCase().contains(q) ||
              s.topic.toLowerCase().contains(q) ||
              (s.goalDescription != null &&
                  s.goalDescription!.toLowerCase().contains(q));
          return matchesStatus && matchesType && matchesSearch;
        }).toList();

    // Statistika
    final scheduledCount = allSessions.where((s) => s.isScheduled).length;
    final completedCount = allSessions.where((s) => s.isCompleted).length;
    final todayCount =
        allSessions.where((s) {
          return s.scheduledAt.year == now.year &&
              s.scheduledAt.month == now.month &&
              s.scheduledAt.day == now.day;
        }).length;
    final missedCount =
        allSessions.where((s) => s.isMissed || s.isCancelled).length;

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sarlavha va yangi mashg'ulot tugmasi
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, c) {
                  final icon = Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  );
                  final texts = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Psixologik mashg‘ulotlar va korreksion uchrashuvlar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'O‘quvchilar bilan individual va kichik guruhdagi psixologik korreksiya, suhbat va mashg‘ulotlar jadvali.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withOpacity(0.9),
                        ),
                      ),
                    ],
                  );
                  final button = ElevatedButton.icon(
                    onPressed:
                        () => _showScheduleSessionDialog(
                          context,
                          students,
                          currentUser,
                        ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Mashg‘ulot rejalashtirish'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  if (c.maxWidth < 640) {
                    // Telefon: tugma matn ostida, butun kenglikda
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            icon,
                            const SizedBox(width: 14),
                            Expanded(child: texts),
                          ],
                        ),
                        const SizedBox(height: 14),
                        button,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      icon,
                      const SizedBox(width: 16),
                      Expanded(child: texts),
                      const SizedBox(width: 12),
                      button,
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Statistika kartalari — telefonda 2 tadan, kengroq ekranda 4 tasi bir qatorda
            LayoutBuilder(
              builder: (context, c) {
                final columns = c.maxWidth >= 760 ? 4 : 2;
                const gap = 14.0;
                final w = (c.maxWidth - gap * (columns - 1)) / columns;
                final cards = [
                  _buildMetricCard(
                    title: 'Bugungi mashg‘ulotlar',
                    value: '$todayCount',
                    icon: Icons.today_rounded,
                    color: AppColors.primaryDark,
                    bgColor: AppColors.primaryLight,
                  ),
                  _buildMetricCard(
                    title: 'Rejalashtirilgan',
                    value: '$scheduledCount',
                    icon: Icons.schedule_rounded,
                    color: AppColors.brandTeal,
                    bgColor: AppColors.infoBg,
                  ),
                  _buildMetricCard(
                    title: 'Bajarilgan seanslar',
                    value: '$completedCount',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    bgColor: AppColors.successBg,
                  ),
                  _buildMetricCard(
                    title: 'Qatnashmadi / Bekor',
                    value: '$missedCount',
                    icon: Icons.cancel_outlined,
                    color: AppColors.error,
                    bgColor: AppColors.errorBg,
                  ),
                ];
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final card in cards) SizedBox(width: w, child: card),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Qidiruv va filtrlash paneli
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Qidiruv
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText:
                          'O‘quvchi ismi, mashg‘ulot mavzusi yoki ITR maqsadi bo‘yicha qidiring...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon:
                          _searchQuery.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                              : null,
                      filled: true,
                      fillColor: AppColors.surfaceMuted,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filtrlash qatori: Holat va Tur
                  Row(
                    children: [
                      Text(
                        'Holat: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Wrap(
                        spacing: 6,
                        children:
                            _statuses.map((st) {
                              final isSelected = _selectedStatus == st;
                              return ChoiceChip(
                                label: Text(st),
                                selected: isSelected,
                                onSelected: (val) {
                                  if (val) setState(() => _selectedStatus = st);
                                },
                                selectedColor: AppColors.primary.withOpacity(
                                  0.12,
                                ),
                                backgroundColor: AppColors.surfaceMuted,
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                  color:
                                      isSelected
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                ),
                                side: BorderSide(
                                  color:
                                      isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                ),
                              );
                            }).toList(),
                      ),
                      const Spacer(),
                      Text(
                        'Turi: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Wrap(
                        spacing: 6,
                        children:
                            _types.map((tp) {
                              final isSelected = _selectedType == tp;
                              return ChoiceChip(
                                label: Text(tp),
                                selected: isSelected,
                                onSelected: (val) {
                                  if (val) setState(() => _selectedType = tp);
                                },
                                selectedColor: AppColors.primary.withOpacity(
                                  0.12,
                                ),
                                backgroundColor: AppColors.surfaceMuted,
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                  color:
                                      isSelected
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                ),
                                side: BorderSide(
                                  color:
                                      isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mashg'ulotlar ro'yxati
            if (filteredSessions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy_rounded,
                      size: 54,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bunday parametr bo‘yicha mashg‘ulotlar topilmadi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Yangi mashg‘ulot rejalashtiring yoki filtrlarni tozalang.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed:
                          () => _showScheduleSessionDialog(
                            context,
                            students,
                            currentUser,
                          ),
                      icon: const Icon(Icons.add),
                      label: const Text('Mashg‘ulot rejalashtirish'),
                    ),
                  ],
                ),
              )
            else
              Column(
                children:
                    filteredSessions.map((session) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: _buildSessionCard(context, session, currentUser),
                      );
                    }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    SessionModel session,
    UserModel? currentUser,
  ) {
    final df = DateFormat('dd.MM.yyyy');
    final tf = DateFormat('HH:mm');

    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    switch (session.status) {
      case 'Bajarildi':
        statusColor = AppColors.success;
        statusBgColor = AppColors.successBg;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Rejalashtirilgan':
        statusColor = AppColors.primaryDark;
        statusBgColor = AppColors.primaryLight;
        statusIcon = Icons.schedule_rounded;
        break;
      case 'Qatnashmadi':
        statusColor = AppColors.warning;
        statusBgColor = AppColors.warningBg;
        statusIcon = Icons.person_off_outlined;
        break;
      case 'Bekor qilindi':
        statusColor = AppColors.error;
        statusBgColor = AppColors.errorBg;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusBgColor = AppColors.surfaceMuted;
        statusIcon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yuqori qator: Vaqt, O‘quvchi, Holat
          Row(
            children: [
              // Sana va soat
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      df.format(session.scheduledAt),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tf.format(session.scheduledAt),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Davomiylik
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${session.durationMinutes} daq',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Turi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      session.sessionType == 'Individual'
                          ? AppColors.primaryLight
                          : AppColors.purpleBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  session.sessionType,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color:
                        session.sessionType == 'Individual'
                            ? AppColors.primaryDark
                            : AppColors.purple,
                  ),
                ),
              ),
              const Spacer(),

              // Holat badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: statusColor),
                    const SizedBox(width: 5),
                    Text(
                      session.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // O'quvchi va Mavzu
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                child: Text(
                  session.studentName.isNotEmpty ? session.studentName[0] : 'O',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.studentName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Mutaxassis: ${session.specialistName} (${session.specialistRole})',
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
          const SizedBox(height: 10),

          // Mavzu
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Mavzu: ${session.topic}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (session.goalDescription != null &&
                    session.goalDescription!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'ITR maqsadi: ${session.goalDescription}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Agar bajarilgan bo'lsa natija va kuzatuvlar
          if (session.isCompleted &&
              session.observations != null &&
              session.observations!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.successBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kuzatuv va natija qaydlari:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.observations!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      height: 1.4,
                    ),
                  ),
                  if (session.nextSteps != null &&
                      session.nextSteps!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Tavsiya / Keyingi qadam: ${session.nextSteps}',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Harakat tugmalari
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (session.isScheduled) ...[
                OutlinedButton.icon(
                  onPressed: () => _showStatusChangeDialog(context, session),
                  icon: const Icon(Icons.edit_calendar_outlined, size: 14),
                  label: const Text('Holat'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showCompleteSessionDialog(context, session),
                  icon: const Icon(Icons.check_rounded, size: 14),
                  label: const Text('Natijani qayd etish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.textSubtle,
                ),
                tooltip: 'Mashg‘ulotni o‘chirish',
                onPressed: () => _confirmDeleteSession(context, session),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== DIALOGLAR ====================

  void _showScheduleSessionDialog(
    BuildContext context,
    List<StudentModel> students,
    UserModel? currentUser,
  ) {
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mashg‘ulot rejalashtirish uchun biriktirilgan o‘quvchilar mavjud emas.',
          ),
        ),
      );
      return;
    }

    final topicController = TextEditingController();
    final goalController = TextEditingController();
    StudentModel selectedStudent = students.first;
    String sessionType = 'Individual';
    int duration = 45;
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 2));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 550,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.event_available_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Yangi psixologik mashg‘ulot rejalashtirish',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // O'quvchini tanlash
                      Text(
                        'O‘quvchi *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<StudentModel>(
                        value: selectedStudent,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceMuted,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items:
                            students.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text('${s.fullName} (${s.grade}-sinf)'),
                              );
                            }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedStudent = val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Mavzu
                      Text(
                        'Mashg‘ulot mavzusi / Yo‘nalishi *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: topicController,
                        decoration: InputDecoration(
                          hintText:
                              'Masalan: Xavotir darajasini pasaytirish mashg‘uloti',
                          filled: true,
                          fillColor: AppColors.surfaceMuted,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ITR maqsadi
                      Text(
                        'Aloqador ITR maqsadi (ixtiyoriy)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: goalController,
                        decoration: InputDecoration(
                          hintText:
                              'Masalan: O‘z-o‘zini nazorat qilish va irodaviy zo‘riqishni bartaraf etish',
                          filled: true,
                          fillColor: AppColors.surfaceMuted,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Mashg'ulot turi va davomiyligi
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mashg‘ulot shakli',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: sessionType,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.surfaceMuted,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  items:
                                      ['Individual', 'Kichik guruhda'].map((t) {
                                        return DropdownMenuItem(
                                          value: t,
                                          child: Text(t),
                                        );
                                      }).toList(),
                                  onChanged: (val) {
                                    if (val != null)
                                      setDialogState(() => sessionType = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Davomiyligi (daqiqa)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<int>(
                                  value: duration,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.surfaceMuted,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  items:
                                      [30, 45, 60].map((d) {
                                        return DropdownMenuItem(
                                          value: d,
                                          child: Text('$d daqiqa'),
                                        );
                                      }).toList(),
                                  onChanged: (val) {
                                    if (val != null)
                                      setDialogState(() => duration = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Sana va Vaqt
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 7),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 60),
                                  ),
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    selectedDate = DateTime(
                                      picked.year,
                                      picked.month,
                                      picked.day,
                                      selectedTime.hour,
                                      selectedTime.minute,
                                    );
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_month, size: 16),
                              label: Text(
                                DateFormat('dd.MM.yyyy').format(selectedDate),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    selectedTime = picked;
                                    selectedDate = DateTime(
                                      selectedDate.year,
                                      selectedDate.month,
                                      selectedDate.day,
                                      picked.hour,
                                      picked.minute,
                                    );
                                  });
                                }
                              },
                              icon: const Icon(Icons.access_time, size: 16),
                              label: Text(selectedTime.format(context)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Saqlash tugmasi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Bekor qilish'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final topic = topicController.text.trim();
                              if (topic.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Mashg‘ulot mavzusini kiriting.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final newSession = SessionModel(
                                id: 'sess_${const Uuid().v4().substring(0, 8)}',
                                studentId: selectedStudent.id,
                                studentName: selectedStudent.fullName,
                                specialistId: currentUser?.id ?? 'spec_user',
                                specialistName: currentUser?.fullName ?? '',
                                specialistRole: currentUser?.role.label ?? '',
                                scheduledAt: selectedDate,
                                durationMinutes: duration,
                                status: 'Rejalashtirilgan',
                                topic: topic,
                                sessionType: sessionType,
                                goalDescription:
                                    goalController.text.trim().isNotEmpty
                                        ? goalController.text.trim()
                                        : null,
                              );

                              final res = await context
                                  .read<AppProvider>()
                                  .addSession(newSession, byUser: currentUser);

                              if (res['success'] == true) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Mashg‘ulot muvaffaqiyatli rejalashtirildi.',
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      res['message'] ?? 'Xatolik yuz berdi',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Rejalashtirish'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCompleteSessionDialog(BuildContext context, SessionModel session) {
    final obsController = TextEditingController();
    final nextStepsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 550,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.task_alt_rounded,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mashg‘ulot natijasini qayd etish',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${session.studentName} • ${session.topic}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Davomat
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.successBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'O‘quvchining davomati tasdiqlandi (Ishtirok etdi)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Psixologik kuzatuv va natijalar
                  Text(
                    'Mashg‘ulot jarayoni va o‘quvchining psixoemotsional holati *',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: obsController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'O‘quvchining reaksiyasi, mashqlarni bajarishi, xulq-atvori va dinamikasini tavsiflang...',
                      filled: true,
                      fillColor: AppColors.surfaceMuted,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tavsiya va keyingi qadamlar
                  Text(
                    'Keyingi qadamlar va tavsiyalar (pedagog va ota-onaga)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nextStepsController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText:
                          'Navbatdagi uchrashuv rejasi, uyga mashqlar yoki tavsiyalar...',
                      filled: true,
                      fillColor: AppColors.surfaceMuted,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Saqlash
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Bekor qilish'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final obs = obsController.text.trim();
                          if (obs.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Iltimos, mashg‘ulot natijasi va kuzatuvini kiriting.',
                                ),
                              ),
                            );
                            return;
                          }

                          await context.read<AppProvider>().completeSession(
                            session.id,
                            observations: obs,
                            nextSteps:
                                nextStepsController.text.trim().isNotEmpty
                                    ? nextStepsController.text.trim()
                                    : null,
                          );

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Mashg‘ulot natijasi muvaffaqiyatli saqlandi.',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Bajarildi deb qayd etish'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showStatusChangeDialog(BuildContext context, SessionModel session) {
    String selectedStatus = session.status;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Mashg‘ulot holatini o‘zgartirish'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('O‘quvchi: ${session.studentName}'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceMuted,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items:
                        [
                          'Rejalashtirilgan',
                          'Qatnashmadi',
                          'Bekor qilindi',
                        ].map((st) {
                          return DropdownMenuItem(value: st, child: Text(st));
                        }).toList(),
                    onChanged: (val) {
                      if (val != null)
                        setDialogState(() => selectedStatus = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      hintText: 'Sababi / Izoh (ixtiyoriy)',
                      border: OutlineInputBorder(),
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
                  onPressed: () async {
                    await context.read<AppProvider>().updateSessionStatus(
                      session.id,
                      selectedStatus,
                      notes:
                          notesController.text.trim().isNotEmpty
                              ? notesController.text.trim()
                              : null,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Saqlash'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteSession(BuildContext context, SessionModel session) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Mashg‘ulotni o‘chirish'),
          content: Text(
            '${session.studentName} bilan rejalashtirilgan "${session.topic}" mashg‘ulotini o‘chirmoqchimisiz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: AppColors.onPrimary,
              ),
              onPressed: () async {
                await context.read<AppProvider>().deleteSession(session.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mashg‘ulot o‘chirildi.')),
                );
              },
              child: const Text('O‘chirish'),
            ),
          ],
        );
      },
    );
  }
}
