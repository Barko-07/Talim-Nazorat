import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talim_nazorat/services/local_db_service.dart';
import 'package:talim_nazorat/providers/app_provider.dart';
import 'package:talim_nazorat/providers/auth_provider.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/models/student_model.dart';
import 'package:talim_nazorat/screens/entry/intro_screen.dart';
import 'package:talim_nazorat/screens/students/add_student_screen.dart';
import 'package:talim_nazorat/core/constants/namangan_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Individ Models and Service Tests', () {
    test('UserModel role conversion and labels in Uzbek', () {
      final user = UserModel(
        id: 'u_1',
        email: 'psixolog@talim.uz',
        fullName: 'Dilnoza Usmonova',
        role: UserRole.psychologist,
      );

      expect(user.role.label, 'Amaliyotchi psixolog');
      expect(user.role.code, 'PSYCHOLOGIST');
    });

    test('StudentModel calculates age correctly', () {
      final student = StudentModel(
        id: 's_1',
        institutionId: 'inst_1',
        institutionName: '14-Maktab',
        firstName: 'Jasur',
        lastName: 'Aliyev',
        dateOfBirth: DateTime(2016, 5, 14),
        gender: 'Erkak',
        grade: '3-A',
        status: 'Faol',
        primaryNeed: 'Nutqiy rivojlanishdan orqada qolish',
        supportLevel: '2-daraja',
        createdAt: DateTime.now(),
      );

      expect(student.fullName, 'Aliyev Jasur');
      expect(student.age, greaterThanOrEqualTo(9));
    });

    test(
      'LocalDbService initializes with seed data and zero Supabase',
      () async {
        final db = LocalDbService();
        await db.init();

        final students = db.getStudents();
        expect(students.isNotEmpty, true);
        expect(students.length, greaterThanOrEqualTo(6));

        final users = db.getUsers();
        expect(users.isNotEmpty, true);
        expect(users.any((u) => u.email == 'admin@talim.uz'), true);

        final alerts = db.getAlerts();
        expect(alerts.isNotEmpty, true);
      },
    );

    test(
      'NamanganData provides all 14 administrative districts and realistic school data',
      () {
        expect(NamanganData.defaultRegion, 'Namangan viloyati');
        expect(NamanganData.districts.length, 14);

        const requiredDistricts = [
          'Namangan shahri',
          'Davlatobod tumani',
          'Yangi Namangan tumani',
          'Chortoq tumani',
          'Chust tumani',
          'Kosonsoy tumani',
          'Mingbuloq tumani',
          'Namangan tumani',
          'Norin tumani',
          'Pop tumani',
          'To‘raqo‘rg‘on tumani',
          'Uychi tumani',
          'Uchqo‘rg‘on tumani',
          'Yangiqo‘rg‘on tumani',
        ];

        for (final district in requiredDistricts) {
          expect(
            NamanganData.districts.contains(district),
            true,
            reason: '$district mavjud bo‘lishi lozim',
          );
          final schools = NamanganData.getSchoolsForDistrict(district);
          expect(
            schools.isNotEmpty,
            true,
            reason: '$district da kamida 1 ta maktab bo‘lishi lozim',
          );
        }
      },
    );

    test(
      'UserModel stores locked profession, Namangan region and district',
      () {
        final user = UserModel(
          id: 'u_namangan_1',
          email: 'logoped.chust@talim.uz',
          fullName: 'Ziyodaxon Rahimova',
          role: UserRole.speechTherapist,
          region: 'Namangan viloyati',
          district: 'Chust tumani',
          institutionName: '12-sonli inklyuziv maktab',
        );

        expect(user.role, UserRole.speechTherapist);
        expect(user.role.professionTitle, 'Logopediya va nutq rivojlanishi');
        expect(user.region, 'Namangan viloyati');
        expect(user.district, 'Chust tumani');
        expect(user.institutionName, '12-sonli inklyuziv maktab');
      },
    );

    testWidgets(
      'AddStudentScreen renders without DropdownButton assertion errors',
      (tester) async {
        final appProvider = AppProvider();
        final authProvider = AuthProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: appProvider),
              ChangeNotifierProvider.value(value: authProvider),
            ],
            child: const MaterialApp(home: AddStudentScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Yangi bola'), findsOneWidget);
        expect(find.text('Familiyasi *'), findsOneWidget);
        expect(find.text('Qo‘llab-quvvatlash darajasi'), findsOneWidget);

        // Bir nechta vasiy qo'shiladi va olib tashlanadi.
        final addGuardian = find.text('Vasiy qo‘shish');
        await tester.ensureVisible(addGuardian);
        await tester.tap(addGuardian);
        await tester.pumpAndSettle();
        expect(find.text('2-vasiy'), findsOneWidget);
        await tester.tap(find.text('Olib tashlash').last);
        await tester.pumpAndSettle();
        expect(find.text('2-vasiy'), findsNothing);

        // Sessiya taymeri to'xtatiladi (ilovada provayderni ChangeNotifierProvider yopadi)
        await tester.pumpWidget(const SizedBox());
        authProvider.dispose();
      },
    );

    testWidgets(
      'IntroScreen animates only logo and brand name and finishes cleanly',
      (tester) async {
        var finished = false;
        await tester.pumpWidget(
          MaterialApp(
            home: IntroScreen(onDone: () => finished = true),
          ),
        );

        // Boshlang'ich holatda ortiqcha yuklagich yoki shior chiqmasligi shart
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Ma’lumotlar yuklanmoqda…'), findsNothing);

        // Animatsiya to'liq o'ynab bo'lishi (kirish + silliq chiqish)
        // Belgi va shrift tayyor bo'lishini kutish (testda - 700 ms zaxira),
        // kirish, so'ng logotipning qisqa jim turishi.
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump(const Duration(milliseconds: 1800));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(finished, isTrue);
      },
    );
  });
}
