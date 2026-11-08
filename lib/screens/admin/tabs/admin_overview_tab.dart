import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/namangan_data.dart';
import '../../../models/user_model.dart';
import '../../../models/student_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/child_status_service.dart';
import '../../../services/dynamics_service.dart';
import '../../students/student_detail_screen.dart';
import '../../../core/widgets/status_badge.dart';
import 'admin_home_blocks.dart';

class _AttentionItem {
  final StudentModel student;
  final ChildStatus status;
  final int delayDays;
  final String delayLabel;
  final String specialistName;
  final String missingActivity;

  const _AttentionItem({
    required this.student,
    required this.status,
    required this.delayDays,
    required this.delayLabel,
    required this.specialistName,
    required this.missingActivity,
  });
}

class AdminOverviewTab extends StatefulWidget {
  final Function(int) onNavigateTab;

  const AdminOverviewTab({super.key, required this.onNavigateTab});

  @override
  State<AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends State<AdminOverviewTab> {
  String _selectedDistrict = 'Barchasi';
  String _selectedInstitution = 'Barchasi';
  String _selectedSpecialistId = 'Barchasi';
  String _selectedPeriod = 'Barcha davr';
  String _selectedDomain = 'Barchasi';

  bool _initializedUserScope = false;
  bool _showAllAttentionCases = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedUserScope) {
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;
      if (user != null && user.role == UserRole.institutionAdmin) {
        if (user.district != null && user.district!.isNotEmpty) {
          _selectedDistrict = user.district!;
        }
        if (user.institutionName != null && user.institutionName!.isNotEmpty) {
          _selectedInstitution = user.institutionName!;
        }
      }
      _initializedUserScope = true;
    }
  }

  void _resetFilters(UserModel? user) {
    setState(() {
      if (user?.role == UserRole.institutionAdmin) {
        _selectedDistrict = user?.district ?? 'Chortoq tumani';
        _selectedInstitution = user?.institutionName ?? 'Barchasi';
      } else {
        _selectedDistrict = 'Barchasi';
        _selectedInstitution = 'Barchasi';
      }
      _selectedSpecialistId = 'Barchasi';
      _selectedPeriod = 'Barcha davr';
      _selectedDomain = 'Barchasi';
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final df = DateFormat('dd.MM.yyyy HH:mm');
    final dateOnlyDf = DateFormat('dd.MM.yyyy');

    final isInstitutionAdmin = user?.role == UserRole.institutionAdmin;

    // 1. FILTRLAR RO'YXATI
    final districtOptions = ['Barchasi', ...NamanganData.districts];
    final List<String> institutionOptions = ['Barchasi'];
    if (_selectedDistrict != 'Barchasi') {
      final districtSchools =
          NamanganData.districtSchools[_selectedDistrict] ?? [];
      institutionOptions.addAll(districtSchools);
      // bazadagi ushbu tumanga tegishli boshqa muassasalar
      for (final inst in app.institutionsSummary) {
        final name = inst['name'] as String? ?? '';
        final dist = inst['district'] as String? ?? '';
        if (dist == _selectedDistrict &&
            !institutionOptions.contains(name) &&
            name.isNotEmpty) {
          institutionOptions.add(name);
        }
      }
    } else {
      for (final inst in app.institutionsSummary) {
        final name = inst['name'] as String? ?? '';
        if (name.isNotEmpty && !institutionOptions.contains(name)) {
          institutionOptions.add(name);
        }
      }
    }

    final specialistOptions = <Map<String, String>>[
      {'id': 'Barchasi', 'name': 'Barcha mutaxassislar'},
    ];
    for (final sp in app.specialists) {
      if (_selectedDistrict != 'Barchasi' && sp.district != _selectedDistrict)
        continue;
      if (_selectedInstitution != 'Barchasi' &&
          sp.institutionName != _selectedInstitution)
        continue;
      specialistOptions.add({
        'id': sp.id,
        'name': '${sp.fullName} (${sp.role.label})',
      });
    }

    // 2. O'QUVCHILARNI FILTRLASH
    final baseStudents = app.students;
    final filteredStudents =
        baseStudents.where((s) {
          if (_selectedDistrict != 'Barchasi') {
            final inst = app.institutionsSummary.firstWhere(
              (i) =>
                  i['name'] == s.institutionName || i['id'] == s.institutionId,
              orElse: () => {},
            );
            final inDistrict =
                (inst.isNotEmpty && inst['district'] == _selectedDistrict) ||
                (NamanganData.districtSchools[_selectedDistrict]?.contains(
                      s.institutionName,
                    ) ??
                    false);
            if (!inDistrict) return false;
          }

          if (_selectedInstitution != 'Barchasi') {
            if (s.institutionName != _selectedInstitution &&
                s.institutionId != _selectedInstitution) {
              return false;
            }
          }

          if (_selectedSpecialistId != 'Barchasi') {
            if (!s.assignedSpecialistIds.contains(_selectedSpecialistId)) {
              return false;
            }
          }

          return true;
        }).toList();

    final filteredStudentIds = filteredStudents.map((s) => s.id).toSet();

    // 3. MUTAXASSISLARNI FILTRLASH
    final filteredSpecialists =
        app.specialists.where((sp) {
          if (_selectedDistrict != 'Barchasi' &&
              sp.district != _selectedDistrict)
            return false;
          if (_selectedInstitution != 'Barchasi' &&
              sp.institutionName != _selectedInstitution)
            return false;
          if (_selectedSpecialistId != 'Barchasi' &&
              sp.id != _selectedSpecialistId)
            return false;
          return true;
        }).toList();

    // 4. E'TIBOR TALAB ETILADIGAN HOLATLARNI HISOBLASH
    final attentionCases = <_AttentionItem>[];
    for (final s in filteredStudents) {
      final st = app.childStatus(s);
      if (st.color == StatusColor.red || st.color == StatusColor.yellow) {
        final int delayDays;
        final String delayLabel;
        if (st.lastWorkAt != null) {
          delayDays = DateTime.now().difference(st.lastWorkAt!).inDays;
          delayLabel = '$delayDays kundan buyon faoliyat yo‘q';
        } else {
          delayDays = DateTime.now().difference(s.createdAt).inDays;
          delayLabel = 'Ro‘yxatga olingandan buyon $delayDays kun o‘tdi';
        }

        final assignedNames =
            app.specialists
                .where((sp) => s.assignedSpecialistIds.contains(sp.id))
                .map((sp) => sp.fullName)
                .toList();
        final specName =
            assignedNames.isNotEmpty
                ? assignedNames.join(', ')
                : (st.specialistsNotStarted.isNotEmpty
                    ? 'Hali ish boshlamagan: ${st.specialistsNotStarted.join(', ')}'
                    : 'Biriktirilmagan');

        attentionCases.add(
          _AttentionItem(
            student: s,
            status: st,
            delayDays: delayDays,
            delayLabel: delayLabel,
            specialistName: specName,
            missingActivity:
                st.reasons.isNotEmpty
                    ? st.reasons.join(' • ')
                    : (st.color == StatusColor.red
                        ? 'Mutaxassis biriktirilmagan yoki ish boshlanmagan'
                        : 'Qo‘shimcha monitoring va kuzatuv talab qilinadi'),
          ),
        );
      }
    }
    // Tartiblash: qizillar oldinda, keyin kechikish kunlari bo'yicha
    attentionCases.sort((a, b) {
      if (a.status.color == StatusColor.red &&
          b.status.color != StatusColor.red)
        return -1;
      if (a.status.color != StatusColor.red &&
          b.status.color == StatusColor.red)
        return 1;
      return b.delayDays.compareTo(a.delayDays);
    });

    // 5. KPI STATISTIKASI (HAQIQIY MA'LUMOTLAR)
    final totalChildren = filteredStudents.length;
    final activeSpecialistsCount =
        filteredSpecialists.where((u) => u.isActive).length;
    final unworkedRedCount =
        attentionCases.where((a) => a.status.color == StatusColor.red).length;
    final yellowAttentionCount =
        attentionCases
            .where((a) => a.status.color == StatusColor.yellow)
            .length;
    final greenSuccessCount = (totalChildren -
            unworkedRedCount -
            yellowAttentionCount)
        .clamp(0, totalChildren);

    final incompleteAssessmentsCount =
        filteredStudents.where((s) {
          final childAssessments = app.assessments.where(
            (a) => a.studentId == s.id,
          );
          return childAssessments.isEmpty ||
              childAssessments.any(
                (a) => a.isDraft || a.status != 'Yakunlandi',
              );
        }).length;

    final activeIepPlansCount =
        app.iepPlans.where((p) {
          return p.status == 'Faol' && filteredStudentIds.contains(p.studentId);
        }).length;

    final pendingReferralsCount =
        app.referrals.where((r) {
          final isPending =
              r.status == 'Ko‘rib chiqilmoqda' || r.status == 'Yangi';
          return isPending &&
              (filteredStudentIds.contains(r.studentId) ||
                  r.toSpecialistId == _selectedSpecialistId);
        }).length;

    // 6. MONITORING MARKAZI INDIKATORLARI (6 TA ASOSIY SOHA)
    final report = app.buildReport();
    final regressionCount = report.dynamicsCounts[DynamicsStatus.decline] ?? 0;
    final stagnantCount =
        (report.dynamicsCounts[DynamicsStatus.stable] ?? 0) +
        (report.dynamicsCounts[DynamicsStatus.ineffective] ?? 0);
    final missingAssessmentsCount =
        filteredStudents
            .where(
              (s) =>
                  app.assessments
                      .where((a) => a.studentId == s.id && !a.isDraft)
                      .isEmpty,
            )
            .length;
    final overdue30DaysActivitiesCount =
        filteredStudents.where((s) {
          final st = app.childStatus(s);
          return st.lastWorkAt != null &&
              DateTime.now().difference(st.lastWorkAt!).inDays > 30;
        }).length;
    final incompleteIepObjectivesCount =
        app.iepPlans.where((p) {
          return p.status == 'Faol' &&
              p.objectives.any((o) => o.status != 'Bajarildi') &&
              filteredStudentIds.contains(p.studentId);
        }).length;

    // 7. RIVOJLANISH SOHALARI TAHLILI
    final speechSounds = app.speechSounds;
    final totalTrackedSounds = speechSounds.length;
    final speechAssessmentsCount =
        app.assessments.where((a) {
          final inScope = filteredStudentIds.contains(a.studentId);
          final isSpeech =
              a.title.toLowerCase().contains('nutq') ||
              a.category.toLowerCase().contains('speech');
          return inScope && isSpeech;
        }).length;

    final cognitiveAssessmentsCount =
        app.assessments.where((a) {
          final inScope = filteredStudentIds.contains(a.studentId);
          final isCog =
              a.title.toLowerCase().contains('kognitiv') ||
              a.category.toLowerCase().contains('cognitive');
          return inScope && isCog;
        }).length;

    final attentionMeasurementsCount = filteredStudents.fold<int>(0, (sum, s) {
      final m1 =
          app
              .measurementsFor(s.id, metricId: 'metric_attention_minutes')
              .length;
      final m2 =
          app.measurementsFor(s.id, metricId: 'metric_words_recalled').length;
      return sum + m1 + m2;
    });

    final socialMeasurementsCount = filteredStudents.fold<int>(0, (sum, s) {
      return sum +
          app.measurementsFor(s.id, metricId: 'metric_peer_initiations').length;
    });

    final educationalTasksCount = filteredStudents.fold<int>(0, (sum, s) {
      return sum + app.subjectTasksFor(s.id).where((t) => t.isCompleted).length;
    });

    final observationsCount =
        app.observations
            .where((o) => filteredStudentIds.contains(o.studentId))
            .length;

    // Tarixiy taqqoslash (oxirgi 30 kun va oldingi 30 kun)
    final growthDynamicsCount =
        report.dynamicsCounts[DynamicsStatus.growth] ?? 0;
    final totalDynamicsCount = report.dynamicsCounts.values.fold(
      0,
      (a, b) => a + b,
    );
    final growthPercent =
        totalDynamicsCount == 0
            ? 0
            : ((growthDynamicsCount / totalDynamicsCount) * 100).round();

    // Faol filtrlar soni
    int activeFiltersCount = 0;
    if (_selectedDistrict != 'Barchasi') activeFiltersCount++;
    if (_selectedInstitution != 'Barchasi') activeFiltersCount++;
    if (_selectedSpecialistId != 'Barchasi') activeFiltersCount++;
    if (_selectedPeriod != 'Barcha davr') activeFiltersCount++;
    if (_selectedDomain != 'Barchasi') activeFiltersCount++;

    final narrow = MediaQuery.sizeOf(context).width < 600;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Salomlashuv va ism (my.gov.uz uslubida)
          AdminWelcome(
            user: user,
            scope:
                isInstitutionAdmin
                    ? (user?.institutionName ?? 'Ta’lim muassasasi')
                    : 'Namangan viloyati',
          ),
          const SizedBox(height: 16),

          // 2. Eng muhim topilma va uni hal qiladigan amal
          AdminAttentionCard(
            unworked: unworkedRedCount,
            pendingReferrals: pendingReferralsCount,
            incompleteAssessments: incompleteAssessmentsCount,
            onOpen: () => widget.onNavigateTab(8), // Monitoring
          ),
          const SizedBox(height: 24),

          // 3. Ko'rsatkichlar — bitta bo'lingan karta
          const AdminSectionTitle('Ko‘rsatkichlar'),
          AdminMetricsCard(
            metrics: [
              AdminMetric(
                'Ro‘yxatdagi bolalar',
                totalChildren,
                'nafar',
                icon: LucideIcons.users,
                tone: AdminTone.blue,
                onTap: () => widget.onNavigateTab(3),
              ),
              AdminMetric(
                'Faol mutaxassislar',
                activeSpecialistsCount,
                'nafar',
                icon: LucideIcons.stethoscope,
                tone: AdminTone.green,
                onTap: () => widget.onNavigateTab(2),
              ),
              AdminMetric(
                'Ishlanmagan bolalar',
                unworkedRedCount,
                'nafar',
                icon: LucideIcons.graduationCap,
                tone: AdminTone.purple,
                alert: true,
                onTap: () => widget.onNavigateTab(8),
              ),
              AdminMetric(
                'Tugallanmagan baholashlar',
                incompleteAssessmentsCount,
                'ta',
                icon: LucideIcons.clipboardList,
                tone: AdminTone.orange,
                onTap: () => widget.onNavigateTab(8),
              ),
              AdminMetric(
                'Faol ITR rejalari',
                activeIepPlansCount,
                'ta',
                icon: LucideIcons.fileText,
                tone: AdminTone.blue,
                onTap: () => widget.onNavigateTab(7),
              ),
              AdminMetric(
                'Kutilayotgan yo‘naltirishlar',
                pendingReferralsCount,
                'ta',
                icon: LucideIcons.arrowLeftRight,
                tone: AdminTone.purple,
                onTap: () => widget.onNavigateTab(11),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Svetofor holati
          _buildSvetoforStrip(
            redCount: unworkedRedCount,
            yellowCount: yellowAttentionCount,
            greenCount: greenSuccessCount,
            unassignedCount:
                filteredStudents
                    .where((s) => s.assignedSpecialistIds.isEmpty)
                    .length,
          ),
          const SizedBox(height: 24),

          // 4. Bo'limlar — my.gov.uz "Sohalar" plitkalari kabi
          const AdminSectionTitle('Bo‘limlar'),
          AdminSectionsGrid(
            sections: [
              AdminSection(
                'Foydalanuvchilar',
                LucideIcons.userCog,
                () => widget.onNavigateTab(1),
              ),
              AdminSection(
                'Ta’lim muassasalari',
                LucideIcons.building2,
                () => widget.onNavigateTab(4),
              ),
              AdminSection(
                'O‘quvchilar reyestri',
                LucideIcons.users,
                () => widget.onNavigateTab(3),
              ),
              AdminSection(
                'Mutaxassislar',
                LucideIcons.contact,
                () => widget.onNavigateTab(2),
              ),
              AdminSection(
                'Monitoring',
                LucideIcons.activity,
                () => widget.onNavigateTab(8),
              ),
              AdminSection(
                'Yo‘naltirishlar',
                LucideIcons.route,
                () => widget.onNavigateTab(11),
              ),
              AdminSection(
                'Hisobotlar',
                LucideIcons.chartColumn,
                () => widget.onNavigateTab(7),
              ),
              AdminSection(
                'Audit jurnali',
                LucideIcons.scrollText,
                () => widget.onNavigateTab(10),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 5. Filtrlar (telefonda yig'ilgan holda)
          LayoutBuilder(
            builder: (context, c) {
              final card = _buildGlobalFiltersCard(
                districtOptions: districtOptions,
                institutionOptions: institutionOptions,
                specialistOptions: specialistOptions,
                activeFiltersCount: activeFiltersCount,
                user: user,
                isInstitutionAdmin: isInstitutionAdmin,
              );
              if (c.maxWidth >= 700) return card;
              return Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Icon(
                    LucideIcons.listFilter,
                    color: AppColors.textSecondary,
                  ),
                  title: Text(
                    'Filtrlar',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    activeFiltersCount == 0
                        ? 'Hamma hudud va muassasalar'
                        : '$activeFiltersCount ta filtr tanlangan',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  children: [card],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // 4. E'TIBOR TALAB ETILADIGAN HOLATLAR BO'LIMI (HAQIQIY BOLALAR, MAS'UL VA KECHIKISH MUDDATI BILAN)
          _buildAttentionRequiredSection(
            context,
            attentionCases: attentionCases,
            dateOnlyDf: dateOnlyDf,
          ),
          const SizedBox(height: 24),

          // 5. MONITORING MARKAZI (6 TA MUHIM MONITORING INDIKATORI)
          _buildMonitoringCenterSection(
            regressionCount: regressionCount,
            stagnantCount: stagnantCount,
            missingAssessmentsCount: missingAssessmentsCount,
            overdue30DaysActivitiesCount: overdue30DaysActivitiesCount,
            incompleteIepObjectivesCount: incompleteIepObjectivesCount,
            pendingReferralsCount: pendingReferralsCount,
          ),
          const SizedBox(height: 24),

          // 6. RIVOJLANISH SOHALARI TAHLILI VA TARIXIY TAQQOSLASH
          _buildDevelopmentAnalyticsSection(
            totalTrackedSounds: totalTrackedSounds,
            speechAssessmentsCount: speechAssessmentsCount,
            cognitiveAssessmentsCount: cognitiveAssessmentsCount,
            attentionMeasurementsCount: attentionMeasurementsCount,
            socialMeasurementsCount: socialMeasurementsCount,
            educationalTasksCount: educationalTasksCount,
            observationsCount: observationsCount,
            growthPercent: growthPercent,
            growthCount: growthDynamicsCount,
            declineCount: regressionCount,
            stableCount: stagnantCount,
          ),
          const SizedBox(height: 24),

          // 7. MUTAXASSISLAR ISH YUKLAMASI VA FAOLLIGI TAHLILI
          _buildSpecialistWorkloadSection(
            filteredSpecialists: filteredSpecialists,
            filteredStudents: filteredStudents,
            app: app,
            dateOnlyDf: dateOnlyDf,
          ),
          const SizedBox(height: 24),

          // 9. SO'NGGI TIZIM FAOLLIGI VA AUDIT JURNALI
          _buildRecentActivitySection(app: app, df: df),
        ],
      ),
    );
  }

  // ==================== 2. GLOBAL FILTRLAR PANELI ====================
  Widget _buildGlobalFiltersCard({
    required List<String> districtOptions,
    required List<String> institutionOptions,
    required List<Map<String, String>> specialistOptions,
    required int activeFiltersCount,
    required UserModel? user,
    required bool isInstitutionAdmin,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.listFilter,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Global Boshqaruv Filtrlari',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (activeFiltersCount > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$activeFiltersCount ta filtr faol',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed:
                      activeFiltersCount > 0 ? () => _resetFilters(user) : null,
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Tozalash', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        activeFiltersCount > 0
                            ? AppColors.error
                            : AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                // 1. Tuman filtri
                SizedBox(
                  width: 210,
                  child: DropdownButtonFormField<String>(
                    value:
                        districtOptions.contains(_selectedDistrict)
                            ? _selectedDistrict
                            : 'Barchasi',
                    isExpanded: true,
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: 'Tuman / Shahar',
                      labelStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items:
                        districtOptions.map((d) {
                          return DropdownMenuItem(
                            value: d,
                            child: Text(
                              d,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                    onChanged:
                        isInstitutionAdmin
                            ? null
                            : (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedDistrict = val;
                                  _selectedInstitution = 'Barchasi';
                                });
                              }
                            },
                  ),
                ),

                // 2. Muassasa filtri
                SizedBox(
                  width: 250,
                  child: DropdownButtonFormField<String>(
                    value:
                        institutionOptions.contains(_selectedInstitution)
                            ? _selectedInstitution
                            : 'Barchasi',
                    isExpanded: true,
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: 'Ta’lim muassasasi',
                      labelStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(LucideIcons.building2, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items:
                        institutionOptions.map((inst) {
                          return DropdownMenuItem(
                            value: inst,
                            child: Text(
                              inst,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                    onChanged:
                        isInstitutionAdmin
                            ? null
                            : (val) {
                              if (val != null)
                                setState(() => _selectedInstitution = val);
                            },
                  ),
                ),

                // 3. Mutaxassis filtri
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    value:
                        specialistOptions.any(
                              (s) => s['id'] == _selectedSpecialistId,
                            )
                            ? _selectedSpecialistId
                            : 'Barchasi',
                    isExpanded: true,
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: 'Pedagog-mutaxassis',
                      labelStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(LucideIcons.brain, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items:
                        specialistOptions.map((sp) {
                          return DropdownMenuItem(
                            value: sp['id']!,
                            child: Text(
                              sp['name']!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                    onChanged: (val) {
                      if (val != null)
                        setState(() => _selectedSpecialistId = val);
                    },
                  ),
                ),

                // 4. Davr filtri
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    isExpanded: true,
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: 'Hisobot davri',
                      labelStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(LucideIcons.calendar, size: 16),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Barcha davr',
                        child: Text(
                          'Barcha davr',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'So‘nggi 7 kun',
                        child: Text(
                          'So‘nggi 7 kun',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'So‘nggi 30 kun',
                        child: Text(
                          'So‘nggi 30 kun',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Joriy chorak',
                        child: Text(
                          'Joriy chorak',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPeriod = val);
                    },
                  ),
                ),

                // 5. Rivojlanish sohasi filtri
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    value: _selectedDomain,
                    isExpanded: true,
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: 'Rivojlanish sohasi',
                      labelStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(LucideIcons.shapes, size: 16),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Barchasi',
                        child: Text(
                          'Barcha sohalar',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Nutq va muloqot',
                        child: Text(
                          'Nutq va muloqot',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Kognitiv va intellekt',
                        child: Text(
                          'Kognitiv va intellekt',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Diqqat va xotira',
                        child: Text(
                          'Diqqat va xotira',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Xulq-atvor va ijtimoiy',
                        child: Text(
                          'Xulq-atvor va ijtimoiy',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'O‘quv va DTS fanlari',
                        child: Text(
                          'O‘quv va DTS fanlari',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDomain = val);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SVETOFOR TASMASI ====================
  Widget _buildSvetoforStrip({
    required int redCount,
    required int yellowCount,
    required int greenCount,
    required int unassignedCount,
  }) {
    // Bolalar holati: o'quvchilar filtridagi Qizil / Sariq / Yashil ranglari
    // belgilar ko'rinishida, ostida barcha o'quvchilarga havola.
    return AdminPanelCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  'Bolalar holati',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              AdminStatusChip(
                'Qizil $redCount',
                AppColors.error,
                AppColors.errorBg,
              ),
              AdminStatusChip(
                'Sariq $yellowCount',
                AppColors.warning,
                AppColors.warningBg,
              ),
              AdminStatusChip(
                'Yashil $greenCount',
                AppColors.success,
                AppColors.successBg,
              ),
              if (unassignedCount > 0)
                AdminStatusChip(
                  'Mutaxassissiz $unassignedCount',
                  AppColors.textSecondary,
                  AppColors.surfaceMuted,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 4),
          AdminLinkRow(
            icon: LucideIcons.users,
            label: 'Barcha o‘quvchilar',
            onTap: () => widget.onNavigateTab(3),
          ),
        ],
      ),
    );
  }

  // ==================== 4. E'TIBOR TALAB ETILADIGAN HOLATLAR ====================
  Widget _buildAttentionRequiredSection(
    BuildContext context, {
    required List<_AttentionItem> attentionCases,
    required DateFormat dateOnlyDf,
  }) {
    final displayCases =
        _showAllAttentionCases
            ? attentionCases
            : attentionCases.take(5).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.circleAlert,
                          color: AppColors.error,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'E’tibor Talab Etiladigan O‘quvchilar va Kechikkan Amallar',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${attentionCases.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Faoliyat kiritilmagan, 30 kundan ortiq kechikkan yoki testlari to‘liq bo‘lmagan bolalar',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (attentionCases.length > 5)
                  TextButton(
                    onPressed: () {
                      setState(
                        () => _showAllAttentionCases = !_showAllAttentionCases,
                      );
                    },
                    child: Text(
                      _showAllAttentionCases
                          ? 'Qisqartirish'
                          : 'Barchasini ko‘rish (${attentionCases.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            if (attentionCases.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.brandGreen.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.circleCheck,
                      color: AppColors.brandGreen,
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Ajoyib natija! Tanlangan filtr bo‘yicha e’tibor talab qiluvchi kechikkan holatlar mavjud emas.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayCases.length,
                separatorBuilder: (_, _) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final item = displayCases[index];
                  final isRed = item.status.color == StatusColor.red;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isRed ? AppColors.errorBg : AppColors.warningBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isRed
                                ? AppColors.error.withValues(alpha: 0.2)
                                : AppColors.warning.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              isRed ? AppColors.errorBg : AppColors.warningBg,
                          child: Icon(
                            isRed ? LucideIcons.circleAlert : LucideIcons.clock,
                            color: isRed ? AppColors.error : AppColors.warning,
                            size: 18,
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
                                    item.student.fullName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      '${item.student.grade} • ${item.student.institutionName}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  _buildBadge(
                                    label: item.delayLabel,
                                    color:
                                        isRed
                                            ? AppColors.error
                                            : AppColors.warning,
                                    bgColor: Colors.white,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Yetishmayotgan faoliyat: ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item.missingActivity,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isRed
                                                ? AppColors.error
                                                : AppColors.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.userRound,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Mas’ul mutaxassis: ${item.specialistName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor:
                                isRed ? AppColors.error : AppColors.warning,
                            elevation: 0,
                            side: BorderSide(
                              color:
                                  isRed
                                      ? AppColors.error.withValues(alpha: 0.4)
                                      : AppColors.warning.withValues(
                                        alpha: 0.4,
                                      ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => StudentDetailScreen(
                                      studentId: item.student.id,
                                    ),
                              ),
                            );
                          },
                          icon: const Icon(LucideIcons.arrowRight, size: 14),
                          label: const Text(
                            'Bolani ochish',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ==================== 5. MONITORING MARKAZI (6 TA INDIKATOR) ====================
  Widget _buildMonitoringCenterSection({
    required int regressionCount,
    required int stagnantCount,
    required int missingAssessmentsCount,
    required int overdue30DaysActivitiesCount,
    required int incompleteIepObjectivesCount,
    required int pendingReferralsCount,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.shield, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Avtomatlashtirilgan Monitoring Markazi',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateTab(8), // Monitoring tabi
                  child: const Text(
                    'To‘liq monitoring paneli →',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount =
                    constraints.maxWidth >= 1000
                        ? 3
                        : constraints.maxWidth >= 600
                        ? 2
                        : 1;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.0,
                  children: [
                    _buildMonitoringTile(
                      title: 'Rivojlanishda Pasayish',
                      value: '$regressionCount nafar',
                      description:
                          'Oldingi davrga nisbatan orqaga ketish qayd etilgan',
                      color: AppColors.error,
                      bgColor: AppColors.errorBg,
                      icon: LucideIcons.trendingDown,
                      onTap: () => widget.onNavigateTab(8),
                    ),
                    _buildMonitoringTile(
                      title: 'O‘sish Yo‘q / To‘xtagan',
                      value: '$stagnantCount nafar',
                      description:
                          'Kamida 30 kun davomida ko‘rsatkichlar o‘zgarmagan',
                      color: AppColors.warning,
                      bgColor: AppColors.warningBg,
                      icon: LucideIcons.circlePause,
                      onTap: () => widget.onNavigateTab(8),
                    ),
                    _buildMonitoringTile(
                      title: 'Baholash O‘tkazilmagan',
                      value: '$missingAssessmentsCount nafar',
                      description:
                          'Boshlang‘ich yoki diagnostik test topshirmagan',
                      color: AppColors.purple,
                      bgColor: AppColors.purpleBg,
                      icon: LucideIcons.circleHelp,
                      onTap: () => widget.onNavigateTab(8),
                    ),
                    _buildMonitoringTile(
                      title: 'Muddati O‘tgan Faoliyat (>30 kun)',
                      value: '$overdue30DaysActivitiesCount nafar',
                      description:
                          'Oxirgi 30 kunda birorta ham mashg‘ulot o‘tkazilmagan',
                      color: AppColors.error,
                      bgColor: AppColors.errorBg,
                      icon: LucideIcons.history,
                      onTap: () => widget.onNavigateTab(8),
                    ),
                    _buildMonitoringTile(
                      title: 'Yakunlanmagan ITR Rejalari',
                      value: '$incompleteIepObjectivesCount ta',
                      description:
                          'Belgilangan muddatda erishilmagan reja maqsadlari',
                      color: AppColors.info,
                      bgColor: AppColors.infoBg,
                      icon: LucideIcons.clipboardCheck,
                      onTap: () => widget.onNavigateTab(7),
                    ),
                    _buildMonitoringTile(
                      title: 'Kutilayotgan Yo‘naltirishlar',
                      value: '$pendingReferralsCount ta',
                      description:
                          'Mutaxassis tomonidan javob berilmagan yo‘llanmalar',
                      color: AppColors.brandTeal,
                      bgColor: AppColors.infoBg,
                      icon: LucideIcons.route,
                      onTap: () => widget.onNavigateTab(11),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 6. RIVOJLANISH SOHALARI TAHLILI ====================
  Widget _buildDevelopmentAnalyticsSection({
    required int totalTrackedSounds,
    required int speechAssessmentsCount,
    required int cognitiveAssessmentsCount,
    required int attentionMeasurementsCount,
    required int socialMeasurementsCount,
    required int educationalTasksCount,
    required int observationsCount,
    required int growthPercent,
    required int growthCount,
    required int declineCount,
    required int stableCount,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.chartColumn,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Rivojlanish Yo‘nalishlari Tahlili va Tarixiy Qiyoslash',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateTab(7), // Hisobotlar
                  child: const Text(
                    'Batafsil tahlil →',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // TARIXIY TAQQOSLASH TASMASI
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Davrlararo Rivojlanish Dinamikasi (Oxirgi 30 kun oldingi davr bilan solishtirilganda):',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Ijobiy o‘sish: $growthPercent%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: (growthCount * 10).clamp(1, 100),
                          child: Container(
                            height: 8,
                            color: AppColors.brandGreen,
                          ),
                        ),
                        Expanded(
                          flex: (stableCount * 10).clamp(1, 100),
                          child: Container(height: 8, color: AppColors.warning),
                        ),
                        Expanded(
                          flex: (declineCount * 10).clamp(1, 100),
                          child: Container(height: 8, color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      Text(
                        'O‘sish: $growthCount ta ko‘rsatkich',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        'Barqaror: $stableCount ta ko‘rsatkich',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        'Pasayish: $declineCount ta ko‘rsatkich',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 6 TA SOHA BO'YICHA HAQIQIY METRIKALAR
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount =
                    constraints.maxWidth >= 1000
                        ? 3
                        : constraints.maxWidth >= 600
                        ? 2
                        : 1;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.1,
                  children: [
                    _buildDomainCard(
                      title: 'Nutq va Muloqot',
                      metric: '$totalTrackedSounds ta maqsadli tovush',
                      sub:
                          '$speechAssessmentsCount ta nutq tekshiruvi o‘tkazilgan',
                      icon: LucideIcons.mic,
                      color: AppColors.info,
                    ),
                    _buildDomainCard(
                      title: 'Kognitiv va Intellekt',
                      metric: '$cognitiveAssessmentsCount ta kognitiv test',
                      sub: 'Fikrlash, idrok va analiz ko‘nikmalari',
                      icon: LucideIcons.lightbulb,
                      color: AppColors.purple,
                    ),
                    _buildDomainCard(
                      title: 'Diqqat va Xotira',
                      metric:
                          '$attentionMeasurementsCount ta qayd etilgan o‘lchov',
                      sub: 'Diqqat barqarorligi va so‘z eslab qolish',
                      icon: LucideIcons.brain,
                      color: AppColors.brandTeal,
                    ),
                    _buildDomainCard(
                      title: 'Ijtimoiy-Hissiy Moslashuv',
                      metric: '$socialMeasurementsCount ta ijtimoiy ko‘nikma',
                      sub: 'Tengdoshlar muloqoti va ijtimoiy faollik',
                      icon: LucideIcons.users,
                      color: AppColors.success,
                    ),
                    _buildDomainCard(
                      title: 'O‘quv va DTS Standartlari',
                      metric: '$educationalTasksCount ta bajarilgan topshiriq',
                      sub: 'Matematika va Ona tili individual darajalari',
                      icon: LucideIcons.bookOpen,
                      color: AppColors.warning,
                    ),
                    _buildDomainCard(
                      title: 'Psixologik Kuzatuvlar',
                      metric: '$observationsCount ta kuzatuv jurnali qaydi',
                      sub: 'Emotsional holat, xavotir va xulq-atvor',
                      icon: LucideIcons.eye,
                      color: AppColors.textSecondary,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 7. MUTAXASSISLAR ISH YUKLAMASI VA FAOLLIGI ====================
  Widget _buildSpecialistWorkloadSection({
    required List<UserModel> filteredSpecialists,
    required List<StudentModel> filteredStudents,
    required AppProvider app,
    required DateFormat dateOnlyDf,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final heading = Row(
                  children: [
                    Icon(LucideIcons.badge, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Text(
                                'Pedagog-Mutaxassislar Ish Yuklamasi va Faolligi',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${filteredSpecialists.length} nafar',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Biriktirilgan bolalar, o‘tkazilgan mashg‘ulotlar, ochiq yo‘llanmalar va qamrov ko‘rsatkichi',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final action = TextButton(
                  onPressed: () => widget.onNavigateTab(2),
                  child: const Text(
                    'Barcha mutaxassislar →',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                );
                if (constraints.maxWidth < 720) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      heading,
                      Align(alignment: Alignment.centerRight, child: action),
                    ],
                  );
                }
                return Row(children: [Expanded(child: heading), action]);
              },
            ),
            const Divider(height: 20),
            if (filteredSpecialists.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Tanlangan filtr bo‘yicha pedagog-mutaxassislar topilmadi.',
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.surfaceMuted,
                  ),
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 56,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Mutaxassis F.I.Sh.',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Lavozimi / Ixtisosligi',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Muassasasi',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Biriktirilgan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Bajarilgan ishlar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Kutilayotgan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Qamrov %',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Holati',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  rows:
                      filteredSpecialists.map((sp) {
                        final assignedCount =
                            filteredStudents
                                .where(
                                  (s) =>
                                      s.assignedSpecialistIds.contains(sp.id),
                                )
                                .length;
                        final completedSessions =
                            app.sessions
                                .where((sess) => sess.specialistId == sp.id)
                                .length;
                        final completedAssessments =
                            app.assessments
                                .where(
                                  (a) => a.specialistId == sp.id && !a.isDraft,
                                )
                                .length;
                        final completedTasks =
                            app
                                .subjectTasksFor('')
                                .where(
                                  (t) =>
                                      t.assignedById == sp.id && t.isCompleted,
                                )
                                .length;
                        final totalCompleted =
                            completedSessions +
                            completedAssessments +
                            completedTasks;

                        final pendingReferrals =
                            app.referrals
                                .where(
                                  (r) =>
                                      r.toSpecialistId == sp.id &&
                                      (r.status == 'Ko‘rib chiqilmoqda' ||
                                          r.status == 'Yangi'),
                                )
                                .length;

                        // Ishlanmagan bolalar
                        final unworkedWithThisSpec =
                            filteredStudents.where((s) {
                              if (!s.assignedSpecialistIds.contains(sp.id))
                                return false;
                              final st = app.childStatus(s);
                              return st.specialistsNotStarted.contains(
                                sp.fullName,
                              );
                            }).length;

                        final coveragePercent =
                            assignedCount == 0
                                ? 0
                                : (((assignedCount - unworkedWithThisSpec)
                                                .clamp(0, assignedCount) /
                                            assignedCount) *
                                        100)
                                    .round();

                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.primaryLight,
                                    child: Text(
                                      sp.fullName.isNotEmpty
                                          ? sp.fullName.substring(0, 1)
                                          : 'M',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    sp.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                sp.role.label,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            DataCell(
                              Text(
                                sp.institutionName ?? 'Muassasa ko‘rsatilmagan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '$assignedCount nafar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '$totalCompleted ta',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '$pendingReferrals ta yo‘llanma',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color:
                                      pendingReferrals > 0
                                          ? AppColors.warning
                                          : AppColors.textMuted,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 44,
                                    child: Text(
                                      '$coveragePercent%',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color:
                                            coveragePercent >= 80
                                                ? AppColors.success
                                                : coveragePercent >= 50
                                                ? AppColors.warning
                                                : AppColors.error,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                    width: 50,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: coveragePercent / 100,
                                        minHeight: 5,
                                        backgroundColor: AppColors.border,
                                        valueColor: AlwaysStoppedAnimation(
                                          coveragePercent >= 80
                                              ? AppColors.success
                                              : coveragePercent >= 50
                                              ? AppColors.warning
                                              : AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              StatusBadge.active(
                                sp.isActive,
                                inactiveLabel: 'Nofaol',
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== 9. SO'NGGI TIZIM FAOLLIGI VA AUDIT ====================
  Widget _buildRecentActivitySection({
    required AppProvider app,
    required DateFormat df,
  }) {
    final recentLogs = app.auditLogs.take(5).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.history,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'So‘nggi Tizim Faolligi va Audit Qaydlari',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateTab(10), // Audit jurnali
                  child: const Text(
                    'Barcha yozuvlar →',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            if (recentLogs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('Hozircha audit yozuvlari mavjud emas'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentLogs.length,
                separatorBuilder: (_, _) => const Divider(height: 12),
                itemBuilder: (context, i) {
                  final log = recentLogs[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            log.action,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      log.userFullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      df.format(log.timestamp),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                log.details,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ==================== YORDAMCHI WIDGETLAR ====================

  Widget _buildMonitoringTile({
    required String title,
    required String value,
    required String description,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainCard({
    required String title,
    required String metric,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
