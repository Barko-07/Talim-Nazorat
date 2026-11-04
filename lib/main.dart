import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_brand.dart';
import 'core/constants/app_colors.dart';
import 'core/widgets/brand_logo.dart';
import 'providers/auth_provider.dart';
import 'providers/app_provider.dart';
import 'providers/theme_provider.dart';
import 'models/user_model.dart';
import 'screens/entry/intro_screen.dart';
import 'screens/entry/landing_screen.dart';
import 'screens/entry/welcome_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/admin/admin_portal_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Ilovani bazaning boshlang'ich yuklanishini kutib turmasdan ko'rsatamiz.
  // AuthProvider tayyor holatda bo'lguncha foydalanuvchiga yuklanish ekrani chiqadi.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const TalimNazoratApp(),
    ),
  );
}

class TalimNazoratApp extends StatefulWidget {
  const TalimNazoratApp({super.key});

  @override
  State<TalimNazoratApp> createState() => _TalimNazoratAppState();
}

class _TalimNazoratAppState extends State<TalimNazoratApp>
    with WidgetsBindingObserver {
  bool? _shownDark;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // "Tizimli" tanlanganda telefon mavzusi almashsa, ilova ham almashadi.
  @override
  void didChangePlatformBrightness() => setState(() {});

  /// Mavzu almashganda hamma oynalar qayta chiziladi (const vidjetlar ham),
  /// ochiq sahifa va kiritilgan ma'lumotlar esa joyida qoladi.
  void _repaintEverything() {
    void visit(Element e) {
      e.markNeedsBuild();
      e.visitChildren(visit);
    }

    (context as Element).visitChildren(visit);
  }

  @override
  Widget build(BuildContext context) {
    final themes = context.watch<ThemeProvider>();
    final dark = themes.isDark(
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
    AppColors.usePalette(dark ? AppPalette.dark : AppPalette.light);
    if (_shownDark != null && _shownDark != dark) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _repaintEverything());
    }
    _shownDark = dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: MaterialApp(
        title: AppBrand.name,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.current,
        home: const AppEntry(),
      ),
    );
  }
}

/// Ilovaning ildiz oynasi. Saytda: kirmagan mehmonga landing sahifa.
/// Telefon/desktop ilovasida: avval qisqa animatsiya, keyin "Xush kelibsiz"
/// ekrani. Kirgan foydalanuvchiga — rolga mos bosh sahifa.
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  // Animatsiya faqat ilovada va faqat ochilishda bir marta.
  bool _introDone = kIsWeb;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!_introDone) {
      return IntroScreen(onDone: () => setState(() => _introDone = true));
    }
    // Faqat ilova ochilayotganda. Kirish tugmasi bosilganda ham yuklanish
    // ekrani ko'rsatilsa, kirish sahifasi yopilib, kod oynasi ochilmay qoladi.
    if (auth.isInitializing) {
      return const _AppLoadingScreen();
    }
    if (auth.initializationError != null) {
      return _InitializationErrorScreen(onRetry: auth.retryInitialization);
    }
    if (auth.isAuthenticated) {
      if (auth.currentUser?.role == UserRole.superAdmin) {
        return const AdminPortalScreen();
      }
      return const MainNavigationScreen();
    }
    return kIsWeb ? const LandingScreen() : const WelcomeScreen();
  }
}

class _AppLoadingScreen extends StatelessWidget {
  const _AppLoadingScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandLogo(height: 110),
          const SizedBox(height: 22),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(height: 10),
          Text(
            'Ma’lumotlar yuklanmoqda…',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _InitializationErrorScreen extends StatelessWidget {
  const _InitializationErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surfaceMuted,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.database, size: 42, color: AppColors.warning),
              const SizedBox(height: 14),
              const Text(
                'Mahalliy ma’lumotlarni ochib bo‘lmadi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Saqlangan ma’lumotlar ustidan yozilmadi. Sahifani qayta yuklashga urinib ko‘ring. Muammo takrorlansa, brauzer ma’lumotlarini tozalamang va administratorga murojaat qiling.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, height: 1.45),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.refreshCw),
                label: const Text('Qayta urinish'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
