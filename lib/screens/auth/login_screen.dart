import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/namangan_data.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/seed_data.dart';
import '../main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool initialIsSignUp;

  const LoginScreen({super.key, this.initialIsSignUp = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- LOGIN CONTROLLERS ---
  final _loginIdentifierCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController(text: 'Parol2026!');
  bool _loginObscure = true;

  // --- SIGN UP STEP MANAGEMENT ---
  int _signUpStep = 0;

  // Qadam 1: Shaxsiy ma'lumotlar
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();

  // Qadam 2: Kasbiy mutaxassislik va Chortoq tumani maktabi
  UserRole _selectedRole = UserRole.psychologist;
  final _institutionCtrl = TextEditingController(
    text: '9-sonli inklyuziv ta’lim tayanch maktabi',
  );
  final _specializationCtrl = TextEditingController();

  // Qadam 3: Aloqa ma'lumotlari
  final _phoneCtrl = TextEditingController(text: '+998 ');
  final _emailCtrl = TextEditingController();

  // Qadam 4: Xavfsizlik
  final _signUpPasswordCtrl = TextEditingController();
  final _signUpConfirmPasswordCtrl = TextEditingController();
  bool _signUpObscure = true;
  bool _signUpConfirmObscure = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIsSignUp ? 1 : 0,
    );
    _tabController.addListener(() {
      if (mounted) {
        setState(() => _errorMessage = null);
      }
    });
    final initialSchools =
        NamanganData.getSchoolsForDistrict('Chortoq tumani');
    if (initialSchools.isNotEmpty) {
      _institutionCtrl.text = initialSchools.first;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginIdentifierCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _institutionCtrl.dispose();
    _specializationCtrl.dispose();
    _signUpPasswordCtrl.dispose();
    _signUpConfirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _showIosSchoolPickerModal(BuildContext context) {
    final allSchools = NamanganData.getSchoolsForDistrict('Chortoq tumani');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredSchools = searchQuery.isEmpty
                ? allSchools
                : allSchools
                    .where(
                      (s) => s
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()),
                    )
                    .toList();

            return SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.78,
              child: GlassSurface(
                borderRadius: 22,
                blur: 18,
                opacity: 0.97,
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 40,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: AppColors.borderSlate,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ta’lim muassasasini tanlash',
                                    style: TextStyle(
                                      fontSize: 17.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Namangan viloyati • Chortoq tumani (${allSchools.length} ta maktab)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              icon: const Icon(
                                LucideIcons.x,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: TextField(
                          onChanged: (val) =>
                              setModalState(() => searchQuery = val),
                          decoration: const InputDecoration(
                            hintText: 'Maktab raqami yoki nomini qidiring...',
                            prefixIcon: Icon(
                              LucideIcons.search,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filteredSchools.isEmpty
                            ? const Center(
                                child: Text(
                                  'Bunday maktab topilmadi',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 8,
                                ),
                                itemCount: filteredSchools.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final school = filteredSchools[index];
                                  final isSelected =
                                      _institutionCtrl.text == school;

                                  return SurfaceCard(
                                    elevated: false,
                                    borderRadius: 12,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 13,
                                    ),
                                    backgroundColor: isSelected
                                        ? AppColors.primaryLight
                                        : AppColors.glassWellFill,
                                    borderColor: isSelected
                                        ? AppColors.primary
                                            .withValues(alpha: 0.4)
                                        : AppColors.border,
                                    onTap: () {
                                      setState(() {
                                        _institutionCtrl.text = school;
                                        _errorMessage = null;
                                      });
                                      Navigator.of(sheetContext).pop();
                                    },
                                    child: Row(
                                      children: [
                                        Icon(
                                          LucideIcons.school,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.textMuted,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            school,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            LucideIcons.circleCheck,
                                            color: AppColors.primary,
                                            size: 18,
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
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

  void _handleLogin() async {
    setState(() => _errorMessage = null);

    final auth = context.read<AuthProvider>();
    final result = await auth.login(
      _loginIdentifierCtrl.text.trim(),
      _loginPasswordCtrl.text.trim(),
    );

    if (mounted) {
      if (result['success'] == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        setState(() {
          _errorMessage = result['message'] as String?;
        });
      }
    }
  }

  void _nextStep() {
    setState(() => _errorMessage = null);

    if (_signUpStep == 0) {
      if (_firstNameCtrl.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Iltimos, ismingizni kiriting.');
        return;
      }
      if (_lastNameCtrl.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Iltimos, familiyangizni kiriting.');
        return;
      }
    } else if (_signUpStep == 1) {
      if (_institutionCtrl.text.trim().isEmpty) {
        setState(
          () => _errorMessage =
              'Iltimos, Chortoq tumanidagi maktabingizni tanlang.',
        );
        return;
      }
    } else if (_signUpStep == 2) {
      final phone = _phoneCtrl.text.trim();
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 9) {
        setState(
          () => _errorMessage =
              'Iltimos, to‘liq telefon raqamingizni kiriting (masalan: +998 90 123 45 67).',
        );
        return;
      }
    }

    if (_signUpStep < 3) {
      setState(() => _signUpStep++);
    }
  }

  void _previousStep() {
    setState(() {
      _errorMessage = null;
      if (_signUpStep > 0) _signUpStep--;
    });
  }

  void _handleSignUp() async {
    setState(() => _errorMessage = null);

    if (_signUpPasswordCtrl.text.trim().length < 6) {
      setState(
        () => _errorMessage =
            'Parol kamida 6 ta belgidan iborat bo‘lishi lozim.',
      );
      return;
    }

    if (_signUpPasswordCtrl.text.trim() !=
        _signUpConfirmPasswordCtrl.text.trim()) {
      setState(
        () => _errorMessage = 'Kiritilgan parollar bir-biriga mos kelmadi.',
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final roleToRegister = _selectedRole;

    final result = await auth.register(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      role: roleToRegister,
      region: NamanganData.defaultRegion,
      district: 'Chortoq tumani',
      institutionName: _institutionCtrl.text.trim().isNotEmpty
          ? _institutionCtrl.text.trim()
          : '9-sonli inklyuziv ta’lim tayanch maktabi',
      specialization: _specializationCtrl.text.trim().isNotEmpty
          ? _specializationCtrl.text.trim()
          : roleToRegister.label,
      qualificationCategory: 'Mutaxassis',
      experienceYears: 3,
      password: _signUpPasswordCtrl.text.trim(),
    );

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        setState(() {
          _errorMessage = result['message'] as String?;
        });
      }
    }
  }

  void _selectDemoAccount(UserModel user) {
    _loginIdentifierCtrl.text = user.email;
    _loginPasswordCtrl.text = 'Parol2026!';
    _handleLogin();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AmbientMeshBackground(
      intense: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBrandHeader()
                        .animate()
                        .fadeIn(duration: 220.ms, curve: Curves.easeOutCubic)
                        .slideY(
                          begin: 0.04,
                          end: 0,
                          duration: 220.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 24),

                    _buildSegmentedTabs(),
                    const SizedBox(height: 18),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.errorBorder,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.circleAlert,
                              color: AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    GlassSurface(
                      borderRadius: 20,
                      blur: 18,
                      opacity: 0.96,
                      boxShadow: AppColors.elevatedShadow,
                      padding: const EdgeInsets.all(24),
                      child: PageTransitionSwitcher(
                        duration: const Duration(milliseconds: 210),
                        transitionBuilder: (child, primary, secondary) {
                          return FadeThroughTransition(
                            fillColor: Colors.transparent,
                            animation: primary,
                            secondaryAnimation: secondary,
                            child: child,
                          );
                        },
                        child: _tabController.index == 0
                            ? KeyedSubtree(
                                key: const ValueKey('tab_login'),
                                child: _buildLoginView(auth),
                              )
                            : KeyedSubtree(
                                key: const ValueKey('tab_signup'),
                                child: _buildStepByStepSignUpView(auth),
                              ),
                      ),
                    )
                        .animate()
                        .fadeIn(
                          delay: 50.ms,
                          duration: 240.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .slideY(
                          begin: 0.03,
                          end: 0,
                          duration: 240.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: 24),

                    const Center(
                      child: Text(
                        'O‘zbekiston Respublikasi Maktabgacha va maktab ta’limi vazirligi © 2026',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        const Icon(
          LucideIcons.landmark,
          color: AppColors.primary,
          size: 38,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: const Text(
            'MAKTABGACHA VA MAKTAB TA’LIMI VAZIRLIGI',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.75,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'TA’LIM NAZORAT',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Yagona inklyuziv ta’lim va pedagogik monitoring platformasi',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF1F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.9),
      ),
      child: Row(
        children: [
          _buildSegmentButton(
            index: 0,
            icon: LucideIcons.logIn,
            label: 'Kirish',
          ),
          _buildSegmentButton(
            index: 1,
            icon: LucideIcons.userPlus,
            label: 'Ro‘yxatdan o‘tish',
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color:
                  isSelected ? AppColors.glassWhiteBorder : Colors.transparent,
              width: 0.85,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x0D0F172A),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginView(AuthProvider auth) {
    final demoProfiles = [
      (
        SeedData.users.firstWhere((u) => u.role == UserRole.psychologist),
        'Psixolog',
        LucideIcons.brain,
      ),
      (
        SeedData.users.firstWhere((u) => u.role == UserRole.speechTherapist),
        'Logoped',
        LucideIcons.mic,
      ),
      (
        SeedData.users.firstWhere((u) => u.role == UserRole.specialEducation),
        'Defektolog',
        LucideIcons.puzzle,
      ),
      (
        SeedData.users.firstWhere((u) => u.role == UserRole.teacher),
        'O‘qituvchi',
        LucideIcons.bookOpen,
      ),
      (
        SeedData.users.firstWhere((u) => u.role == UserRole.coordinator),
        'Koordinator',
        LucideIcons.sparkles,
      ),
      (
        SeedData.users.firstWhere((u) => u.role == UserRole.superAdmin),
        'Admin',
        LucideIcons.shieldCheck,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Shaxsiy kabinetga kirish',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.35,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Telefon raqamingiz yoki elektron pochtangiz orqali tizimga kiring',
          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: _loginIdentifierCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Telefon raqam yoki Email',
            hintText: '+998 90 123 45 67 yoki login@talim.uz',
            prefixIcon: Icon(
              LucideIcons.user,
              size: 18,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _loginPasswordCtrl,
          obscureText: _loginObscure,
          onSubmitted: (_) => _handleLogin(),
          decoration: InputDecoration(
            labelText: 'Parol',
            prefixIcon: const Icon(
              LucideIcons.lock,
              size: 18,
              color: AppColors.primary,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _loginObscure ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 18,
                color: AppColors.textMuted,
              ),
              onPressed: () =>
                  setState(() => _loginObscure = !_loginObscure),
            ),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: auth.isLoading ? null : _handleLogin,
            child: auth.isLoading
                ? const SizedBox(
                    height: 19,
                    width: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Tizimga kirish',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(LucideIcons.arrowRight, size: 17),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),

        Center(
          child: TextButton(
            onPressed: () => _tabController.animateTo(1),
            child: const Text(
              'Yangi hisob ochish (Ro‘yxatdan o‘tish)',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(),
        ),

        const Row(
          children: [
            Icon(LucideIcons.zap, size: 14, color: AppColors.primary),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Namunaviy hisoblar (1-klikda tezkor kirish):',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: demoProfiles.map((item) {
            final user = item.$1;
            final label = item.$2;
            final icon = item.$3;
            return SurfaceCard(
              elevated: false,
              borderRadius: 10,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: AppColors.glassWellFill,
              borderColor: AppColors.border,
              onTap: () => _selectDemoAccount(user),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStepByStepSignUpView(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepProgressBar(),
        const SizedBox(height: 20),
        PageTransitionSwitcher(
          duration: const Duration(milliseconds: 190),
          transitionBuilder: (child, primary, secondary) {
            return FadeThroughTransition(
              fillColor: Colors.transparent,
              animation: primary,
              secondaryAnimation: secondary,
              child: child,
            );
          },
          child: _buildCurrentStepContent(auth),
        ),
        const SizedBox(height: 20),
        _buildStepActionButtons(auth),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => _tabController.animateTo(0),
            child: const Text(
              'Allaqachon hisobingiz bormi? Kirish',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepProgressBar() {
    final stepTitles = ['Ism-familiya', 'Kasb va Maktab', 'Aloqa', 'Parol'];

    return GlassWell(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Column(
        children: [
          Row(
            children: List.generate(4, (index) {
              final isPassed = index <= _signUpStep;

              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  height: 5,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 3,
                    right: index == 3 ? 0 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: isPassed
                        ? AppColors.primary
                        : AppColors.borderSlate,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QADAM ${_signUpStep + 1} / 4',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.textMuted,
                ),
              ),
              Flexible(
                child: Text(
                  stepTitles[_signUpStep],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent(AuthProvider auth) {
    switch (_signUpStep) {
      case 0:
        return _buildStep1PersonalInfo();
      case 1:
        return _buildStep2ProfessionalInfo();
      case 2:
        return _buildStep3ContactInfo();
      case 3:
        return _buildStep4SecurityInfo();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1PersonalInfo() {
    return KeyedSubtree(
      key: const ValueKey('step_1_personal'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '1-Qadam: Ism va Familiyangiz',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tizimda rasmiy hujjatlar sizning nomingizdan yuritiladi.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _firstNameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Ismingiz *',
              hintText: 'Masalan: Dilnoza',
              prefixIcon: Icon(
                LucideIcons.user,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _lastNameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Familiyangiz *',
              hintText: 'Masalan: Qodirova',
              prefixIcon: Icon(
                LucideIcons.idCard,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2ProfessionalInfo() {
    final availableRoles = [
      (UserRole.psychologist, 'Amaliyotchi psixolog', LucideIcons.brain),
      (UserRole.speechTherapist, 'Logoped-defektolog', LucideIcons.mic),
      (
        UserRole.specialEducation,
        'Maxsus pedagog (Defektolog)',
        LucideIcons.puzzle,
      ),
      (UserRole.teacher, 'Fan o‘qituvchisi', LucideIcons.bookOpen),
      (UserRole.institutionAdmin, 'Maktab koordinatori', LucideIcons.landmark),
      (UserRole.reviewer, 'Metodik inspektor', LucideIcons.eye),
    ];

    final selectedSchool = _institutionCtrl.text.isNotEmpty
        ? _institutionCtrl.text
        : 'Maktab tanlanmagan';

    return KeyedSubtree(
      key: const ValueKey('step_2_profession'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '2-Qadam: Mutaxassislik va Muassasa',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'O‘z kasbingizni va Chortoq tumanidagi maktabingizni tanlang.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          const Text(
            'Mutaxassislik sohasi *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableRoles.map((item) {
              final r = item.$1;
              final title = item.$2;
              final icon = item.$3;
              final isSelected = _selectedRole == r;

              return SurfaceCard(
                elevated: false,
                borderRadius: 10,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                backgroundColor: isSelected
                    ? AppColors.primaryLight
                    : AppColors.glassWellFill,
                borderColor: isSelected
                    ? AppColors.primary.withValues(alpha: 0.45)
                    : AppColors.border,
                onTap: () {
                  setState(() {
                    _selectedRole = r;
                    _specializationCtrl.text = r.label;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 15,
                      color:
                          isSelected ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        LucideIcons.circleCheck,
                        color: AppColors.primary,
                        size: 14,
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ta’lim muassasasi (Chortoq tumani) *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SurfaceCard(
            elevated: false,
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            backgroundColor: AppColors.glassWellFill,
            borderColor: AppColors.border,
            onTap: () => _showIosSchoolPickerModal(context),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.school,
                  color: AppColors.primary,
                  size: 19,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    selectedSchool,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const StatusPill(
                  label: 'Tanlash',
                  color: AppColors.primary,
                  backgroundColor: AppColors.primaryLight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3ContactInfo() {
    return KeyedSubtree(
      key: const ValueKey('step_3_contact'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '3-Qadam: Aloqa Ma’lumotlari',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Telefon raqamingiz tizimga kirish identifikatori bo‘lib xizmat qiladi.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefon raqam *',
              hintText: '+998 90 123 45 67',
              prefixIcon: Icon(
                LucideIcons.phone,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Elektron pochta (Ixtiyoriy)',
              hintText: 'mutaxassis@talim.uz',
              prefixIcon: Icon(
                LucideIcons.mail,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4SecurityInfo() {
    return KeyedSubtree(
      key: const ValueKey('step_4_security'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '4-Qadam: Parol va Tasdiqlash',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kamida 6 ta belgidan iborat xavfsiz parol o‘rnating.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          GlassWell(
            borderRadius: 12,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'F.I.Sh: ${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Soha: ${_selectedRole.label}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Maktab: ${_institutionCtrl.text.trim()}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _signUpPasswordCtrl,
            obscureText: _signUpObscure,
            decoration: InputDecoration(
              labelText: 'Parol *',
              hintText: 'Kamida 6 ta belgi',
              prefixIcon: const Icon(
                LucideIcons.lock,
                size: 18,
                color: AppColors.primary,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _signUpObscure ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                onPressed: () =>
                    setState(() => _signUpObscure = !_signUpObscure),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _signUpConfirmPasswordCtrl,
            obscureText: _signUpConfirmObscure,
            decoration: InputDecoration(
              labelText: 'Parolni tasdiqlang *',
              prefixIcon: const Icon(
                LucideIcons.shieldCheck,
                size: 18,
                color: AppColors.primary,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _signUpConfirmObscure ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                onPressed: () => setState(
                  () => _signUpConfirmObscure = !_signUpConfirmObscure,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepActionButtons(AuthProvider auth) {
    final isLastStep = _signUpStep == 3;

    return Row(
      children: [
        if (_signUpStep > 0) ...[
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: auth.isLoading ? null : _previousStep,
                child: const Text('Orqaga'),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: auth.isLoading
                  ? null
                  : (isLastStep ? _handleSignUp : _nextStep),
              child: auth.isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            isLastStep ? 'Ro‘yxatdan o‘tish' : 'Keyingisi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isLastStep
                              ? LucideIcons.check
                              : LucideIcons.arrowRight,
                          size: 16,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
