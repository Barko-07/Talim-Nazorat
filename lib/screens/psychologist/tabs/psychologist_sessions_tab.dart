import 'package:lucide_icons_flutter/lucide_icons.dart';
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
import '../../../core/widgets/glass_widgets.dart';

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

    final width = MediaQuery.sizeOf(context).width;
    final horizontalPad = width < 600 ? 12.0 : 18.0;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          horizontalPad,
          MediaQuery.paddingOf(context).top + (width >= 920 ? 82 : 74),
          horizontalPad,
          width < 920 ? (84 + MediaQuery.paddingOf(context).bottom) : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sarlavha va yangi mashg'ulot tugmasi (Minimalist Glassy Header)
            SurfaceCard(
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: LayoutBuilder(
                builder: (context, c) {
                  final isCompact = c.maxWidth < 600;
                  final actionBtn = HeaderActionButton(
                    label: 'Mashg‘ulot rejalashtirish',
                    compactLabel: 'Yangi mashg‘ulot',
                    icon: LucideIcons.plus,
                    onPressed:
                        () => _showScheduleSessionDialog(
                          context,
                          students,
                          currentUser,
                        ),
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: StatusPill(
                              label: 'Korreksion jadval',
                              color: AppColors.primary,
                              backgroundColor: AppColors.primaryLight,
                              icon: LucideIcons.calendarDays,
                            ),
                          ),
                          if (!isCompact) ...[
                            const SizedBox(width: 12),
                            actionBtn,
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Psixologik mashg‘ulotlar va korreksion uchrashuvlar',
                        style: TextStyle(
                          fontSize: isCompact ? 18.5 : 21,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'O‘quvchilar bilan individual va kichik guruhdagi psixologik korreksiya, suhbat va mashg‘ulotlar jadvali.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                      if (isCompact) ...[
                        const SizedBox(height: 12),
                        actionBtn,
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Statistika kartalari — bir xil balandlik va kenglikda
            ResponsiveGlassGrid(
              mobileColumns: 2,
              tabletColumns: 2,
              desktopColumns: 4,
              spacing: 10,
              children: [
                _buildMetricCard(
                  title: 'Bugungi mashg‘ulotlar',
                  value: '$todayCount ta',
                  subtitle: 'Kun tartibida',
                  icon: LucideIcons.calendar,
                  color: AppColors.primary,
                ),
                _buildMetricCard(
                  title: 'Rejalashtirilgan',
                  value: '$scheduledCount ta',
                  subtitle: 'Kelgusi uchrashuvlar',
                  icon: LucideIcons.clock,
                  color: AppColors.info,
                ),
                _buildMetricCard(
                  title: 'Bajarilgan seanslar',
                  value: '$completedCount ta',
                  subtitle: 'Muvaffaqiyatli yakunlangan',
                  icon: LucideIcons.circleCheck,
                  color: AppColors.success,
                ),
                _buildMetricCard(
                  title: 'Qatnashmadi / Bekor',
                  value: '$missedCount ta',
                  subtitle: 'Qayta rejalashtirish talab',
                  icon: LucideIcons.circleX,
                  color: AppColors.error,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Qidiruv va filtrlash paneli
            SurfaceCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        LucideIcons.search,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon:
                          _searchQuery.isNotEmpty
                              ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 18),
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
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ModernPillFilterBar(
                        items: _statuses,
                        selectedItem: _selectedStatus,
                        onSelected:
                            (st) => setState(() => _selectedStatus = st),
                      ),
                      ModernPillFilterBar(
                        items: _types,
                        selectedItem: _selectedType,
                        onSelected: (tp) => setState(() => _selectedType = tp),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Mashg'ulotlar ro'yxati
            if (filteredSessions.isEmpty)
              SurfaceCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.calendarX,
                        size: 46,
                        color: AppColors.textSubtle,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bunday parametr bo‘yicha mashg‘ulotlar topilmadi',
                        style: TextStyle(
                          fontSize: 15.5,
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
                      HeaderActionButton(
                        label: 'Mashg‘ulot rejalashtirish',
                        icon: LucideIcons.plus,
                        onPressed:
                            () => _showScheduleSessionDialog(
                              context,
                              students,
                              currentUser,
                            ),
                      ),
                    ],
                  ),
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
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return SurfaceCard(
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: color,
              fontWeight: FontWeight.w600,
            ),
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
        statusIcon = LucideIcons.circleCheck;
        break;
      case 'Rejalashtirilgan':
        statusColor = AppColors.primary;
        statusBgColor = AppColors.primaryLight;
        statusIcon = LucideIcons.clock;
        break;
      case 'Qatnashmadi':
        statusColor = AppColors.warning;
        statusBgColor = AppColors.warningBg;
        statusIcon = LucideIcons.userX;
        break;
      case 'Bekor qilindi':
        statusColor = AppColors.error;
        statusBgColor = AppColors.errorBg;
        statusIcon = LucideIcons.circleX;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusBgColor = AppColors.surfaceMuted;
        statusIcon = LucideIcons.info;
    }

    return SurfaceCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yuqori qator: Vaqt, O‘quvchi, Holat
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border, width: 0.85),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.calendar,
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
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          LucideIcons.clock,
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
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: '${session.durationMinutes} daq',
                    color: AppColors.textSecondary,
                    backgroundColor: AppColors.surfaceMuted,
                  ),
                  StatusPill(
                    label: session.sessionType,
                    color:
                        session.sessionType == 'Individual'
                            ? AppColors.primary
                            : AppColors.purple,
                    backgroundColor:
                        session.sessionType == 'Individual'
                            ? AppColors.primaryLight
                            : AppColors.purpleBg,
                  ),
                ],
              ),
              StatusPill(
                label: session.status,
                color: statusColor,
                backgroundColor: statusBgColor,
                icon: statusIcon,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // O'quvchi va Mavzu
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  session.studentName.isNotEmpty ? session.studentName[0] : 'O',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Mutaxassis: ${session.specialistName} (${session.specialistRole})',
                      style: TextStyle(
                        fontSize: 11.5,
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
          GlassWell(
            padding: const EdgeInsets.all(12),
            borderRadius: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.brain, size: 15, color: AppColors.primary),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.successBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.notebookText,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Kuzatuv va natija qaydlari:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
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
          const SizedBox(height: 12),

          // Harakat tugmalari
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (session.isScheduled) ...[
                HeaderActionButton(
                  label: 'Holat',
                  icon: LucideIcons.calendarCog,
                  variant: HeaderActionVariant.secondary,
                  onPressed: () => _showStatusChangeDialog(context, session),
                ),
                HeaderActionButton(
                  label: 'Natijani qayd etish',
                  compactLabel: 'Natija',
                  icon: LucideIcons.check,
                  onPressed: () => _showCompleteSessionDialog(context, session),
                ),
              ],
              IconButton(
                icon: Icon(
                  LucideIcons.trash2,
                  size: 17,
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
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              LucideIcons.calendarCheck,
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
                            icon: const Icon(LucideIcons.x),
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
                        initialValue: selectedStudent,
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
                                  initialValue: sessionType,
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
                                    if (val != null) {
                                      setDialogState(() => sessionType = val);
                                    }
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
                                  initialValue: duration,
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
                                    if (val != null) {
                                      setDialogState(() => duration = val);
                                    }
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
                              icon: const Icon(
                                LucideIcons.calendarDays,
                                size: 16,
                              ),
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
                              icon: const Icon(LucideIcons.clock, size: 16),
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

                              final sm = ScaffoldMessenger.of(context);
                              final nav = Navigator.of(ctx);
                              final res = await context
                                  .read<AppProvider>()
                                  .addSession(newSession, byUser: currentUser);
                              if (!ctx.mounted || !context.mounted) return;

                              if (res['success'] == true) {
                                nav.pop();
                                sm.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Mashg‘ulot muvaffaqiyatli rejalashtirildi.',
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              } else {
                                sm.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      res['message'] ?? 'Xatolik yuz berdi',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(LucideIcons.check),
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
                          LucideIcons.circleCheckBig,
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
                        icon: const Icon(LucideIcons.x),
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
                          LucideIcons.circleCheck,
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

                          final sm = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(ctx);
                          await context.read<AppProvider>().completeSession(
                            session.id,
                            observations: obs,
                            nextSteps:
                                nextStepsController.text.trim().isNotEmpty
                                    ? nextStepsController.text.trim()
                                    : null,
                          );
                          if (!ctx.mounted || !context.mounted) return;

                          nav.pop();
                          sm.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Mashg‘ulot natijasi muvaffaqiyatli saqlandi.',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.check),
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
                    initialValue: selectedStatus,
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
                      if (val != null) {
                        setDialogState(() => selectedStatus = val);
                      }
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
                    final nav = Navigator.of(ctx);
                    await context.read<AppProvider>().updateSessionStatus(
                      session.id,
                      selectedStatus,
                      notes:
                          notesController.text.trim().isNotEmpty
                              ? notesController.text.trim()
                              : null,
                    );
                    nav.pop();
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
                final nav = Navigator.of(ctx);
                final sm = ScaffoldMessenger.of(context);
                await context.read<AppProvider>().deleteSession(session.id);
                nav.pop();
                sm.showSnackBar(
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
