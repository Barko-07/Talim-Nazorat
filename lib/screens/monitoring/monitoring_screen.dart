import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/monitoring_alert_model.dart';
import '../../providers/app_provider.dart';
import '../../services/child_changes.dart';
import '../../core/widgets/status_badge.dart';
import '../../services/dynamics_service.dart';
import '../students/student_detail_screen.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  DynamicsStatus? _filter;

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
    final alerts = app.getAlerts(onlyUnresolved: true);
    final canPop = Navigator.canPop(context);
    final changes = childChanges(app.assessments);
    final shown =
        _filter == null
            ? changes
            : changes.where((c) => c.result.status == _filter).toList();
    int count(DynamicsStatus? s) =>
        s == null ? changes.length : changes.where((c) => c.result.status == s).length;

    Widget sectionTitle(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Text(
        t,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );

    final scrollBody = SingleChildScrollView(
      child: ResponsivePageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AdaptivePageHeader(
              title: 'Monitoring',
              icon: LucideIcons.activity,
              subtitle: 'Oxirgi natija oldingisiga nisbatan',
            ),
            const SizedBox(height: 12),
            SurfaceCard(
              borderRadius: 20,
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionTitle('O‘sish va pasayish'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final f in <DynamicsStatus?>[
                          null,
                          DynamicsStatus.decline,
                          DynamicsStatus.ineffective,
                          DynamicsStatus.growth,
                          DynamicsStatus.stable,
                        ])
                          _FilterChip(
                            label: f == null ? 'Hammasi' : _label(f),
                            status: f,
                            count: count(f),
                            selected: _filter == f,
                            onTap: () => setState(() => _filter = f),
                          ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppColors.border),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        changes.isEmpty
                            ? 'Baholashlar bo‘lgach, o‘zgarishlar shu yerda ko‘rinadi'
                            : 'Bu toifada bola yo‘q',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    )
                  else
                    for (var i = 0; i < shown.length; i++) ...[
                      if (i > 0) Divider(height: 1, indent: 20, color: AppColors.border),
                      _changeRow(context, shown[i]),
                    ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SurfaceCard(
              borderRadius: 20,
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionTitle(
                    alerts.isEmpty ? 'Ogohlantirishlar' : 'Ogohlantirishlar · ${alerts.length}',
                  ),
                  if (alerts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Text(
                        'Hozircha ogohlantirish yo‘q',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: Column(
                        children: [for (final alt in alerts) _buildAlertCard(context, alt)],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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

  static String _label(DynamicsStatus s) => switch (s) {
    DynamicsStatus.growth => 'O‘sish',
    DynamicsStatus.decline => 'Pasayish',
    DynamicsStatus.stable => 'Barqaror',
    DynamicsStatus.ineffective => 'Samarasiz',
    DynamicsStatus.insufficientData => 'Bitta natija',
  };

  Widget _changeRow(BuildContext context, ChildChange c) {
    final r = c.result;
    final pct = r.changePercent;
    final significant =
        r.status == DynamicsStatus.growth || r.status == DynamicsStatus.decline;
    final deltaColor =
        r.status == DynamicsStatus.growth
            ? const Color(0xFF1F8A55)
            : r.status == DynamicsStatus.decline
            ? const Color(0xFFD23C41)
            : AppColors.textMuted;
    final df = DateFormat('dd.MM');
    final detail = [
      c.last.category,
      if (r.previous != null)
        '${r.previous!.value.round()}% → ${r.latest!.value.round()}%'
      else
        '${(c.last.totalScore / c.last.maxScore * 100).round()}%',
      df.format(c.last.assessmentDate),
    ].join(' · ');
    return InkWell(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentDetailScreen(studentId: c.last.studentId),
            ),
          ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: c.last.studentName),
                        if (pct != null)
                          TextSpan(
                            text: '   ${pct >= 0 ? '▲' : '▼'} ${pct.abs().round()}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: significant ? deltaColor : AppColors.textMuted,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                      ],
                    ),
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
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DynamicsIcon(r.status),
                const SizedBox(width: 6),
                Text(
                  _label(r.status),
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(width: 6),
            Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSubtle),
          ],
        ),
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

/// Filtr: tanlanganda faqat chegara qalinlashadi, rang o'zgarmaydi.
class _FilterChip extends StatelessWidget {
  final String label;
  final DynamicsStatus? status;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.status,
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
              if (status != null) ...[
                DynamicsIcon(status!, size: 14),
                const SizedBox(width: 6),
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
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

