import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talim_nazorat/core/theme/app_theme.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/providers/auth_provider.dart';
import 'package:talim_nazorat/screens/settings/profile_edit_dialog.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final user = UserModel(
    id: 'u1',
    email: 'dilnoza@maktab.uz',
    fullName: 'Karimova Dilnoza',
    role: UserRole.teacher,
    phone: '+998901112233',
    specialization: 'Matematika',
    experienceYears: 7,
  );

  for (final width in [375.0, 1280.0]) {
    testWidgets('profile form is prefilled, validated and fits at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = AuthProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: MaterialApp(
            theme: AppTheme.current,
            home: Builder(
              builder:
                  (ctx) => Scaffold(
                    body: TextButton(
                      onPressed: () => showProfileEditDialog(ctx, user),
                      child: const Text('ochish'),
                    ),
                  ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ochish'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.widgetWithText(TextFormField, 'Karimova'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Dilnoza'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Matematika'), findsOneWidget);
      // Email is not editable here.
      expect(find.text('dilnoza@maktab.uz'), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextFormField, '+998901112233'),
        'abc',
      );
      await tester.tap(find.text('Saqlash'));
      await tester.pumpAndSettle();
      expect(find.text('Telefon raqam noto‘g‘ri'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    });
  }
}
