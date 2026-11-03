import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/providers/app_provider.dart';
import 'package:talim_nazorat/providers/auth_provider.dart';
import 'package:talim_nazorat/screens/admin/admin_portal_screen.dart';
import 'package:talim_nazorat/screens/admin/tabs/admin_overview_tab.dart';
import 'package:talim_nazorat/services/local_db_service.dart';
import 'package:talim_nazorat/services/seed_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final db = LocalDbService();
    db.resetForTest();
    await db.init();
  });

  group('Admin Portal & Dashboard Enhancement Tests', () {
    testWidgets(
      'AdminPortalScreen renders with categorized sidebar navigation',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final auth = AuthProvider();
        final app = AppProvider();

        // Login as SuperAdmin
        final loginRes = await auth.login(
          'admin@talim.uz',
          SeedData.demoPassword,
        );
        expect(loginRes['success'], isTrue);
        app.setCurrentUser(auth.currentUser);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: app),
              ChangeNotifierProvider.value(value: auth),
            ],
            child: const MaterialApp(home: AdminPortalScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Check categorized sidebar headers
        expect(find.text('ASOSIY BOSHQARUV'), findsOneWidget);
        expect(find.text('MONITORING VA TAHLIL'), findsOneWidget);
        expect(find.text('REYESTRLAR VA KADRLAR'), findsOneWidget);
        expect(find.text('XAVFSIZLIK VA MA’MURIYAT'), findsOneWidget);

        // Check categorized items
        expect(find.text('Boshqaruv paneli'), findsOneWidget);
        expect(find.text('Monitoring markazi'), findsOneWidget);
        expect(find.text('Tahliliy hisobotlar'), findsOneWidget);
        expect(find.text('O‘quvchilar reyestri'), findsOneWidget);
        expect(find.text('Pedagog-mutaxassislar'), findsOneWidget);
        expect(find.text('Yo‘naltirishlar jurnali'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        auth.dispose();
      },
    );

    testWidgets(
      'AdminOverviewTab renders all required government-grade sections',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final auth = AuthProvider();
        final app = AppProvider();

        await auth.login('admin@talim.uz', SeedData.demoPassword);
        app.setCurrentUser(auth.currentUser);

        int navigatedTab = -1;

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: app),
              ChangeNotifierProvider.value(value: auth),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: AdminOverviewTab(
                  onNavigateTab: (idx) => navigatedTab = idx,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Government header
        expect(
          find.text('TA’LIM NAZORAT — Milliy va Hududiy Boshqaruv Markazi'),
          findsOneWidget,
        );

        // 2. Global Filters Card
        expect(find.text('Global Boshqaruv Filtrlari'), findsOneWidget);
        expect(find.text('Tuman / Shahar'), findsOneWidget);
        expect(find.text('Ta’lim muassasasi'), findsOneWidget);
        expect(find.text('Pedagog-mutaxassis'), findsOneWidget);

        // 3. KPI Statistics Grid
        expect(find.text('JAMI RO‘YXATDAGI BOLALAR'), findsOneWidget);
        expect(find.text('FAOL MUTAXASSISLAR'), findsOneWidget);
        expect(find.text('ISHLANMAGAN BOLALAR (QIZIL)'), findsOneWidget);
        expect(find.text('TUGALLANMAGAN BAHOLASHLAR'), findsOneWidget);
        expect(find.text('FAOL ITR REJALARI'), findsOneWidget);
        expect(find.text('KUTILAYOTGAN YO‘NALTIRISHLAR'), findsOneWidget);

        // 4. Attention Required Section
        expect(
          find.text(
            'E’tibor Talab Etiladigan O‘quvchilar va Kechikkan Amallar',
          ),
          findsOneWidget,
        );

        // 5. Monitoring Center Section
        expect(
          find.text('Avtomatlashtirilgan Monitoring Markazi'),
          findsOneWidget,
        );
        expect(find.text('Rivojlanishda Pasayish'), findsOneWidget);
        expect(find.text('O‘sish Yo‘q / To‘xtagan'), findsOneWidget);
        expect(find.text('Baholash O‘tkazilmagan'), findsOneWidget);

        // 6. Development Analytics Section
        expect(
          find.text('Rivojlanish Yo‘nalishlari Tahlili va Tarixiy Qiyoslash'),
          findsOneWidget,
        );
        expect(find.text('Nutq va Muloqot'), findsOneWidget);
        expect(find.text('Kognitiv va Intellekt'), findsOneWidget);
        expect(find.text('Diqqat va Xotira'), findsOneWidget);
        expect(find.text('Ijtimoiy-Hissiy Moslashuv'), findsOneWidget);
        expect(find.text('O‘quv va DTS Standartlari'), findsOneWidget);

        // 7. Specialist Workload Section
        expect(
          find.text('Pedagog-Mutaxassislar Ish Yuklamasi va Faolligi'),
          findsOneWidget,
        );

        // 8. Management Features
        expect(
          find.text('Tizim Boshqaruvi va Ma’muriy Funksiyalar'),
          findsOneWidget,
        );

        // 9. Recent Activity
        expect(
          find.text('So‘nggi Tizim Faolligi va Audit Qaydlari'),
          findsOneWidget,
        );

        // Test tapping a KPI card triggers navigation
        await tester.tap(find.text('FAOL MUTAXASSISLAR'));
        await tester.pumpAndSettle();
        expect(navigatedTab, 2);

        await tester.pumpWidget(const SizedBox());
        auth.dispose();
      },
    );

    testWidgets(
      'Role differentiation in AdminOverviewTab for institutionAdmin',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final auth = AuthProvider();
        final app = AppProvider();
        final db = LocalDbService();
        final superAdmin = db.getUserById('user_admin')!;
        await db.addUser(
          UserModel(
            id: 'test_inst_admin',
            email: 'test.admin@talim.uz',
            fullName: 'Test Direktor',
            role: UserRole.institutionAdmin,
            institutionId: 'inst_chortoq_5',
            institutionName: '5-sonli umumiy o‘rta ta’lim maktabi',
            password: 'TestPassword123!',
          ),
          byUser: superAdmin,
        );

        // Login as Institution Admin (School Director)
        await auth.login('test.admin@talim.uz', 'TestPassword123!');
        app.setCurrentUser(auth.currentUser);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: app),
              ChangeNotifierProvider.value(value: auth),
            ],
            child: MaterialApp(
              home: Scaffold(body: AdminOverviewTab(onNavigateTab: (_) {})),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should display institution-specific title and badge
        expect(
          find.textContaining(
            '5-sonli umumiy o‘rta ta’lim maktabi — Boshqaruv Paneli',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('MUASSASA DARAJASI'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        auth.dispose();
      },
    );
  });
}
