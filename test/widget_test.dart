import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talim_nazorat/services/local_db_service.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/models/student_model.dart';
import 'package:talim_nazorat/core/constants/namangan_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TA’LIM NAZORAT Models and Service Tests', () {
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

    test('LocalDbService initializes with seed data and zero Supabase', () async {
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
    });

    test('NamanganData provides all 14 administrative districts and realistic school data', () {
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
        expect(NamanganData.districts.contains(district), true, reason: '$district mavjud bo‘lishi lozim');
        final schools = NamanganData.getSchoolsForDistrict(district);
        expect(schools.isNotEmpty, true, reason: '$district da kamida 1 ta maktab bo‘lishi lozim');
      }
    });

    test('UserModel stores locked profession, Namangan region and district', () {
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
    });
  });
}
