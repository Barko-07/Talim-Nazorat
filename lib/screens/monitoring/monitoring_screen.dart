import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/monitoring_alert_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../services/child_status_service.dart';
import '../students/student_detail_screen.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  bool _showOnlyUnresolved = true;
  StatusColor? _selectedSvetoforFilter;

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

  void _showResolveDialog(BuildContext context, MonitoringAlertModel alert) {
    final notesCtrl = TextEditingController(
      text:
          'Chora ko‘rildi: mutaxassislar konsiliumi chaqirildi va reja moslashtirildi.',
    );
    String selectedStatus = 'Hal qilindi';
    final app = context.read<AppProvider>();

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setModalState) {
              return AlertDialog(
                title: const Text('Signalni ko‘rib chiqish va yechim kiritish'),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'O‘quvchi: ${alert.studentName} (${alert.studentGrade})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert.ruleTitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          alert.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Yangi holati *',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Ko‘rib chiqilmoqda',
                              child: Text('Ko‘rib chiqilmoqda'),
                            ),
                            DropdownMenuItem(
                              value: 'Hal qilindi',
                              child: Text('Hal qilindi (Yopish)'),
                            ),
                            DropdownMenuItem(
                              value: 'Rad etildi',
                              child: Text('Rad etildi (Asossiz deb topildi)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedStatus = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: notesCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Qabul qilingan chora va xulosalar *',
                            hintText:
                                'Ushbu muammo bo‘yicha qanday pedagogik qaror qabul qilindi...',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Bekor qilish'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await app.resolveAlert(alert.id, notesCtrl.text.trim());
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Signal muvaffaqiyatli saqlandi.'),
                          ),
                        );
                      }
                    },
                    child: const Text('Saqlash'),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final alerts = app.getAlerts(onlyUnresolved: _showOnlyUnresolved);
    final allAlertsCount = app.getAlerts(onlyUnresolved: false).length;
    final unresolvedCount = app.unresolvedAlerts.length;
    final canPop = Navigator.canPop(context);

    const rules = [
      (
        'Qoida 1',
        'O‘tkazib yuborilgan mashg‘ulotlar',
        'Ketma-ket 2+ marta qoldirilgan yoki bekor qilingan darslar',
      ),
      (
        'Qoida 2',
        'Kechikkan davriy baholashlar',
        'Davriy nazorat muddati 60 kundan oshib ketganda',
      ),
      (
        'Qoida 3',
        'Rivojlanish turg‘unligi (Stagnatsiya)',
        'Oxirgi 3 ta qiyosiy baholashda siljish kuzatilmasa',
      ),
      (
        'Qoida 4',
        'Ko‘rsatkichlar pasayishi (Regressiya)',
        'O‘xshash mezonlar bo‘yicha >15% ko‘rsatkich tushishi',
      ),
      (
        'Qoida 5',
        'Muddati o‘tgan ITR maqsadlari',
        'Belgilangan muddatda bajarilmagan ta’limiy maqsadlar',
      ),
      (
        'Qoida 6',
        'Dars kuzatuvi kiritilmaganligi',
        'Bajarilgan mashg‘ulotda pedagogik xulosa qoldirilmagan',
      ),
    ];

    final summary = app.monitoringSummary;
    final filteredStatuses =
        summary == null
            ? const <ChildStatus>[]
            : (_selectedSvetoforFilter == null
                ? summary.statuses
                : summary.byColor(_selectedSvetoforFilter!));

    final scrollBody = SingleChildScrollView(
      child: ResponsivePageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdaptivePageHeader(
              title: 'Monitoring tizimi',
              subtitle:
                  'Xavfli tendensiyalarni erta aniqlash va nazorat qilish',
              inlineActionOnMobile: false,
              action: ModernPillFilterBar(
                items: const ['Faqat ochiqlar', 'Barcha signallar'],
                selectedItem:
                    _showOnlyUnresolved ? 'Faqat ochiqlar' : 'Barcha signallar',
                counts: {
                  'Faqat ochiqlar': unresolvedCount,
                  'Barcha signallar': allAlertsCount,
                },
                onSelected:
                    (v) => setState(
                      () => _showOnlyUnresolved = v == 'Faqat ochiqlar',
                    ),
              ),
            ),
            const SizedBox(height: 18),

            // SVETOFOR: QIZIL / SARIQ / YASHIL MONITORING PANELI
            if (summary != null) ...[
              SurfaceCard(
                borderRadius: 26,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bolalar bilan ishlash holati (Svetofor monitoringi)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qizil: bola bilan ishlanmagan yoki 30+ kun yozuv kiritilmagan • Sariq: pasayish/samarasiz yoki to‘liq ishlanmagan • Yashil: ijobiy dinamika',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ModernPillFilterBar(
                      items: const [
                        'Barchasi',
                        'Qizil (Ishlanmagan)',
                        'Sariq (E’tibor talab)',
                        'Yashil (Ijobiy)',
                      ],
                      selectedItem:
                          _selectedSvetoforFilter == StatusColor.red
                              ? 'Qizil (Ishlanmagan)'
                              : _selectedSvetoforFilter == StatusColor.yellow
                              ? 'Sariq (E’tibor talab)'
                              : _selectedSvetoforFilter == StatusColor.green
                              ? 'Yashil (Ijobiy)'
                              : 'Barchasi',
                      counts: {
                        'Barchasi': summary.total,
                        'Qizil (Ishlanmagan)': summary.count(StatusColor.red),
                        'Sariq (E’tibor talab)': summary.count(
                          StatusColor.yellow,
                        ),
                        'Yashil (Ijobiy)': summary.count(StatusColor.green),
                      },
                      itemColors: {
                        'Qizil (Ishlanmagan)': AppColors.error,
                        'Sariq (E’tibor talab)': AppColors.warning,
                        'Yashil (Ijobiy)': AppColors.success,
                      },
                      onSelected: (v) {
                        setState(() {
                          if (v == 'Qizil (Ishlanmagan)') {
                            _selectedSvetoforFilter = StatusColor.red;
                          } else if (v == 'Sariq (E’tibor talab)') {
                            _selectedSvetoforFilter = StatusColor.yellow;
                          } else if (v == 'Yashil (Ijobiy)') {
                            _selectedSvetoforFilter = StatusColor.green;
                          } else {
                            _selectedSvetoforFilter = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ...filteredStatuses.map(
                      (st) => _buildChildStatusTile(context, st),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // 6 ta nazorat qoidalari bloki (Responsive 2-col desktop/tablet, 1-col mobile)
            SurfaceCard(
              borderRadius: 26,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '6 ta doimiy ishlovchi avtomatik nazorat algoritmi',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ResponsiveGlassGrid(
                    mobileColumns: 1,
                    tabletColumns: 2,
                    desktopColumns: 2,
                    spacing: 12,
                    children:
                        rules
                            .map((r) => _buildRuleTile(r.$1, r.$2, r.$3))
                            .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Aniqlangan signallar (${alerts.length} ta)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            if (alerts.isEmpty)
              SurfaceCard(
                borderRadius: 26,
                padding: const EdgeInsets.symmetric(
                  vertical: 38,
                  horizontal: 24,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.shieldCheck,
                        size: 38,
                        color: AppColors.success,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Ochiq monitoring signallari yo‘q',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Barcha o‘quvchilar ko‘rsatkichlari me’yorida ketmoqda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...alerts.map((alt) => _buildAlertCard(context, alt)),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: canPop ? AppColors.background : Colors.transparent,
      appBar: canPop ? AppBar(title: const Text('Monitoring')) : null,
      body: canPop ? AmbientMeshBackground(child: scrollBody) : scrollBody,
    );
  }

  Widget _buildChildStatusTile(BuildContext context, ChildStatus st) {
    final c = _colorFor(st.color);
    final bg = _bgFor(st.color);
    final df = DateFormat('dd.MM.yyyy');
    final isRed = st.color == StatusColor.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentDetailScreen(studentId: st.student.id),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRed ? AppColors.errorBg : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: c.withValues(alpha: isRed ? 0.55 : 0.3),
              width: isRed ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: bg,
                child: Text(
                  st.student.firstName.isNotEmpty
                      ? st.student.firstName[0]
                      : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: c,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          st.student.fullName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        StatusPill(
                          label: '${st.student.grade}-sinf',
                          color: AppColors.primary,
                          backgroundColor: AppColors.primaryLight,
                        ),
                        StatusPill(
                          label: '${st.color.label} — ${st.color.meaning}',
                          color: c,
                          backgroundColor: bg,
                          showDot: true,
                        ),
                      ],
                    ),
                    if (st.reasons.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ...st.reasons.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '• $r',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (st.specialistsNotStarted.isNotEmpty ||
                        st.lastWorkAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (st.lastWorkAt != null)
                            'Oxirgi ish: ${df.format(st.lastWorkAt!)}'
                          else
                            'Oxirgi ish: kiritilmagan',
                          if (st.specialistsNotStarted.isNotEmpty)
                            'Ish boshlamagan: ${st.specialistsNotStarted.join(", ")}',
                        ].join(' • '),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (st.specialistWorkStatuses.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Mutaxassislar bo‘yicha ish holati',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children:
                            st.specialistWorkStatuses.map((work) {
                              final color = _colorFor(work.color);
                              final bg = _bgFor(work.color);
                              final stateLabel =
                                  work.lastWorkAt == null
                                      ? 'Ish boshlanmagan'
                                      : work.color == StatusColor.yellow
                                      ? '30 kundan ortiq'
                                      : 'Faol';
                              return Tooltip(
                                message:
                                    work.lastWorkAt == null
                                        ? '${work.specialist.fullName}: ish qayd etilmagan'
                                        : '${work.specialist.fullName}: oxirgi ish ${df.format(work.lastWorkAt!)}',
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 240,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: color.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '${work.specialist.role.label}: $stateLabel',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: AppColors.textSubtle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleTile(String code, String title, String condition) {
    return GlassWell(
      borderRadius: 12,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(
            label: code,
            color: AppColors.primary,
            backgroundColor: AppColors.primaryLight,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  condition,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, MonitoringAlertModel alt) {
    final isDanger = alt.severity == 'XAVF';
    final accent = isDanger ? AppColors.error : AppColors.warning;
    final accentBg = isDanger ? AppColors.errorBg : AppColors.warningBg;
    final df = DateFormat('dd.MM.yyyy HH:mm');

    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 14),
      borderRadius: 26,
      padding: const EdgeInsets.all(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentDetailScreen(studentId: alt.studentId),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 10,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusPill(
                  label: alt.severity,
                  color: accent,
                  backgroundColor: accentBg,
                  icon: LucideIcons.triangleAlert,
                ),
                Text(
                  df.format(alt.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            alt.ruleTitle,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
              color: AppColors.textPrimary,
              letterSpacing: -0.25,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              Text(
                'O‘quvchi: ${alt.studentName} (${alt.studentGrade})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (alt.responsiblePersonName != null)
                Text(
                  'Mas’ul: ${alt.responsiblePersonName!}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alt.message,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          GlassWell(
            borderRadius: 12,
            padding: const EdgeInsets.all(14),
            tintColor: AppColors.primaryLight,
            borderColor: AppColors.primaryTint,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    LucideIcons.lightbulb,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Tavsiya: ${alt.suggestedAction}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusPill(
                  label: 'Holati: ${alt.status}',
                  color: alt.isResolved ? AppColors.success : AppColors.info,
                  backgroundColor:
                      alt.isResolved ? AppColors.successBg : AppColors.infoBg,
                  showDot: true,
                ),
                if (!alt.isResolved)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(LucideIcons.circleCheck, size: 15),
                    label: const Text('Yechim kiritish'),
                    onPressed: () => _showResolveDialog(context, alt),
                  ),
              ],
            ),
          ),
          if (alt.resolvedNotes != null && alt.resolvedNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            GlassWell(
              borderRadius: 12,
              padding: const EdgeInsets.all(13),
              tintColor: AppColors.successBg,
              borderColor: AppColors.successBorder,
              child: Text(
                'Yechim bayonnomasi: ${alt.resolvedNotes!}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
