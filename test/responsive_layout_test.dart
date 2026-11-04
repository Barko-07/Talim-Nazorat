// Responsive layout check: opens every main screen for each role at phone,
// tablet and desktop widths and collects layout overflow errors ("A RenderFlex
// overflowed by N pixels"), with the source line of the widget that overflowed.
//
// The report is written to build/overflow_report.txt; the test fails when any
// overflow is found. Text is measured with a real proportional font (Segoe UI,
// close to Golos Text metrics) instead of the square test glyphs, which would
// report text as much wider than it is.
@Tags(['layout'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talim_nazorat/core/constants/app_colors.dart';
import 'package:talim_nazorat/core/theme/app_theme.dart';
import 'package:talim_nazorat/providers/app_provider.dart';
import 'package:talim_nazorat/providers/auth_provider.dart';
import 'package:talim_nazorat/providers/theme_provider.dart';
import 'package:talim_nazorat/screens/admin/admin_portal_screen.dart';
import 'package:talim_nazorat/screens/admin/tabs/admin_audit_tab.dart';
import 'package:talim_nazorat/screens/admin/tabs/admin_classes_tab.dart';
import 'package:talim_nazorat/screens/admin/tabs/admin_institutions_tab.dart';
import 'package:talim_nazorat/screens/admin/tabs/admin_monitoring_tab.dart';
import 'package:talim_nazorat/screens/admin/tabs/admin_overview_tab.dart';
import 'package:talim_nazorat/screens/admin/tabs/admin_reports_tab.dart';
import 'package:talim_nazorat/screens/admin/tabs/admin_roles_tab.dart';
import 'package:talim_nazorat/screens/admin/tabs/admin_settings_tab.dart';
import 'package:talim_nazorat/screens/admin/tabs/admin_specialists_tab.dart';
import 'package:talim_nazorat/screens/admin/tabs/admin_students_tab.dart';
import 'package:talim_nazorat/screens/admin/tabs/admin_users_tab.dart';
import 'package:talim_nazorat/screens/assessments/assessments_list_screen.dart';
import 'package:talim_nazorat/screens/auth/login_screen.dart';
import 'package:talim_nazorat/screens/dashboard/dashboard_screen.dart';
import 'package:talim_nazorat/screens/entry/landing_screen.dart';
import 'package:talim_nazorat/screens/entry/welcome_screen.dart';
import 'package:talim_nazorat/screens/iep/iep_list_screen.dart';
import 'package:talim_nazorat/screens/main_navigation_screen.dart';
import 'package:talim_nazorat/screens/monitoring/monitoring_screen.dart';
import 'package:talim_nazorat/screens/psychologist/tabs/psychologist_assessments_tab.dart';
import 'package:talim_nazorat/screens/psychologist/tabs/psychologist_dashboard_tab.dart';
import 'package:talim_nazorat/screens/psychologist/tabs/psychologist_development_map_tab.dart';
import 'package:talim_nazorat/screens/psychologist/tabs/psychologist_methods_tab.dart';
import 'package:talim_nazorat/screens/psychologist/tabs/psychologist_observations_tab.dart';
import 'package:talim_nazorat/screens/psychologist/tabs/psychologist_reports_tab.dart';
import 'package:talim_nazorat/screens/psychologist/tabs/psychologist_sessions_tab.dart';
import 'package:talim_nazorat/screens/psychologist/tabs/psychologist_students_tab.dart';
import 'package:talim_nazorat/screens/psychologist/tabs/psychologist_support_plans_tab.dart';
import 'package:talim_nazorat/screens/referrals/referrals_screen.dart';
import 'package:talim_nazorat/screens/reports/reports_screen.dart';
import 'package:talim_nazorat/screens/sessions/sessions_screen.dart';
import 'package:talim_nazorat/screens/settings/settings_screen.dart';
import 'package:talim_nazorat/screens/specialists/specialists_screen.dart';
import 'package:talim_nazorat/screens/students/student_detail_screen.dart';
import 'package:talim_nazorat/screens/students/students_list_screen.dart';
import 'package:talim_nazorat/services/local_db_service.dart';
import 'package:talim_nazorat/services/seed_data.dart';

const widths = <double>[375, 390, 430, 800, 1280];

Future<void> _loadRealFonts() async {
  final regular = File(r'C:\Windows\Fonts\segoeui.ttf');
  final semibold = File(r'C:\Windows\Fonts\seguisb.ttf');
  final bold = File(r'C:\Windows\Fonts\segoeuib.ttf');
  if (!regular.existsSync()) return; // other OS: square test font
  ByteData data(File f) =>
      ByteData.view(Uint8List.fromList(f.readAsBytesSync()).buffer);
  for (final family in [
    'GolosText_regular',
    'GolosText_500',
    'GolosText_600',
    'GolosText_700',
    'Roboto',
  ]) {
    final loader = FontLoader(family)..addFont(Future.value(data(regular)));
    if (semibold.existsSync()) loader.addFont(Future.value(data(semibold)));
    if (bold.existsSync()) loader.addFont(Future.value(data(bold)));
    await loader.load();
  }
}

class _Screen {
  final String name;
  final String login; // seed account email, or '' for signed-out screens
  final Widget Function() build;
  const _Screen(this.name, this.login, this.build);
}

String _firstStudentId() => LocalDbService().getStudents().first.id;

final _screens = <_Screen>[
  _Screen('Landing', '', () => const LandingScreen()),
  _Screen('Welcome', '', () => const WelcomeScreen()),
  _Screen('Login', '', () => const LoginScreen()),
  _Screen('SignUp', '', () => const LoginScreen(initialIsSignUp: true)),
  // Psychologist workspace
  _Screen('Psy main', 'psixolog@talim.uz', () => const MainNavigationScreen()),
  _Screen(
    'Psy dashboard',
    'psixolog@talim.uz',
    () => const PsychologistDashboardTab(),
  ),
  _Screen(
    'Psy students',
    'psixolog@talim.uz',
    () => const PsychologistStudentsTab(),
  ),
  _Screen(
    'Psy assessments',
    'psixolog@talim.uz',
    () => const PsychologistAssessmentsTab(),
  ),
  _Screen(
    'Psy sessions',
    'psixolog@talim.uz',
    () => const PsychologistSessionsTab(),
  ),
  _Screen(
    'Psy plans',
    'psixolog@talim.uz',
    () => const PsychologistSupportPlansTab(),
  ),
  _Screen(
    'Psy reports',
    'psixolog@talim.uz',
    () => const PsychologistReportsTab(),
  ),
  _Screen(
    'Psy observations',
    'psixolog@talim.uz',
    () => const PsychologistObservationsTab(),
  ),
  _Screen(
    'Psy dev map',
    'psixolog@talim.uz',
    () => const PsychologistDevelopmentMapTab(),
  ),
  _Screen(
    'Psy methods',
    'psixolog@talim.uz',
    () => const PsychologistMethodsTab(),
  ),
  _Screen('Psy settings', 'psixolog@talim.uz', () => const SettingsScreen()),
  // Coordinator / specialists
  _Screen(
    'Coord main',
    'koordinator@talim.uz',
    () => const MainNavigationScreen(),
  ),
  _Screen('Dashboard', 'koordinator@talim.uz', () => const DashboardScreen()),
  _Screen('Students', 'koordinator@talim.uz', () => const StudentsListScreen()),
  _Screen(
    'Student detail',
    'koordinator@talim.uz',
    () => StudentDetailScreen(studentId: _firstStudentId()),
  ),
  _Screen(
    'Assessments',
    'koordinator@talim.uz',
    () => const AssessmentsListScreen(),
  ),
  _Screen('Sessions', 'koordinator@talim.uz', () => const SessionsScreen()),
  _Screen('IEP', 'koordinator@talim.uz', () => const IepListScreen()),
  _Screen('Monitoring', 'koordinator@talim.uz', () => const MonitoringScreen()),
  _Screen('Reports', 'koordinator@talim.uz', () => const ReportsScreen()),
  _Screen(
    'Specialists',
    'koordinator@talim.uz',
    () => const SpecialistsScreen(),
  ),
  _Screen('Referrals', 'koordinator@talim.uz', () => const ReferralsScreen()),
  _Screen(
    'Logoped main',
    'logoped@talim.uz',
    () => const MainNavigationScreen(),
  ),
  _Screen(
    'Teacher main',
    'oqituvchi@talim.uz',
    () => const MainNavigationScreen(),
  ),
  // System administrator
  _Screen('Admin portal', 'admin@talim.uz', () => const AdminPortalScreen()),
  _Screen(
    'Admin overview',
    'admin@talim.uz',
    () => AdminOverviewTab(onNavigateTab: (_) {}),
  ),
  _Screen('Admin users', 'admin@talim.uz', () => const AdminUsersTab()),
  _Screen('Admin students', 'admin@talim.uz', () => const AdminStudentsTab()),
  _Screen(
    'Admin specialists',
    'admin@talim.uz',
    () => const AdminSpecialistsTab(),
  ),
  _Screen(
    'Admin institutions',
    'admin@talim.uz',
    () => const AdminInstitutionsTab(),
  ),
  _Screen('Admin classes', 'admin@talim.uz', () => const AdminClassesTab()),
  _Screen('Admin roles', 'admin@talim.uz', () => const AdminRolesTab()),
  _Screen('Admin reports', 'admin@talim.uz', () => const AdminReportsTab()),
  _Screen(
    'Admin monitoring',
    'admin@talim.uz',
    () => const AdminMonitoringTab(),
  ),
  _Screen('Admin audit', 'admin@talim.uz', () => const AdminAuditTab()),
  _Screen('Admin settings', 'admin@talim.uz', () => const AdminSettingsTab()),
];

final _sourceLine = RegExp(
  r'(?:package:talim_nazorat/|lib[\\/])([^\s:]+\.dart):(\d+)',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final report = <String, Set<String>>{}; // "file:line" -> {"Screen @ width"}

  setUpAll(_loadRealFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final db = LocalDbService();
    db.resetForTest();
    await db.init();
  });

  tearDownAll(() {
    final out = StringBuffer();
    final keys = report.keys.toList()..sort();
    for (final k in keys) {
      out.writeln('$k  <-  ${report[k]!.join(', ')}');
    }
    Directory('build').createSync(recursive: true);
    File('build/overflow_report.txt').writeAsStringSync(out.toString());
    // ignore: avoid_print
    print('overflow sources: ${keys.length} (build/overflow_report.txt)');
  });

  for (final dark in [false, true]) {
    for (final screen in _screens) {
      testWidgets('${screen.name} ${dark ? 'dark' : 'light'}', (tester) async {
        AppColors.usePalette(dark ? AppPalette.dark : AppPalette.light);
        final auth = AuthProvider();
        final app = AppProvider();
        // wait for the provider's own startup (DB already initialised)
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        if (screen.login.isNotEmpty) {
          final r = await auth.login(screen.login, SeedData.demoPassword);
          expect(r['success'], isTrue, reason: 'login ${screen.login}');
          app.setCurrentUser(auth.currentUser);
        }

        final problems = <String>[];
        final found = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          final text = details.toString();
          final isLayout =
              text.contains('overflowed') ||
              text.contains('RenderBox was not laid out') ||
              text.contains('unbounded');
          if (!isLayout) return previous?.call(details);
          final src =
              _sourceLine
                  .allMatches(text)
                  .map((m) => '${m[1]}:${m[2]}')
                  .firstOrNull ??
              'unknown';
          problems.add(src);
        };

        for (final w in dark ? const <double>[390] : widths) {
          tester.view.physicalSize = Size(w, w >= 800 ? 900 : 844);
          tester.view.devicePixelRatio = 1.0;
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: app),
                ChangeNotifierProvider.value(value: auth),
                ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ],
              child: MaterialApp(
                key: ValueKey('$w-$dark'),
                theme: AppTheme.current,
                home: Scaffold(body: screen.build()),
              ),
            ),
          );
          for (var i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 300));
          }
          for (final p in problems) {
            report
                .putIfAbsent(p, () => <String>{})
                .add('${screen.name} @${w.toInt()}${dark ? ' dark' : ''}');
            found.add('$p @${w.toInt()}');
          }
          problems.clear();
        }
        FlutterError.onError = previous;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        AppColors.usePalette(AppPalette.light);
        await tester.pumpWidget(const SizedBox());
        auth.dispose(); // stops its once-a-minute session timer
        expect(
          found,
          isEmpty,
          reason: 'layout overflow (see build/overflow_report.txt)',
        );
      });
    }
  }
}
