import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/namangan_data.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
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
  final _loginPasswordCtrl = TextEditingController();
  bool _loginObscure = true;

  // --- SIGN UP STEP MANAGEMENT ---
  int _signUpStep = 0;

  // Qadam 1: Shaxsiy ma'lumotlar
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();

  // Qadam 2: Kasbiy mutaxassislik va tuman/maktab
  UserRole _selectedRole = UserRole.psychologist;
  String _selectedDistrict = 'Chortoq tumani';
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
    final initialSchools = NamanganData.getSchoolsForDistrict('Chortoq tumani');
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
    final allSchools = NamanganData.getSchoolsForDistrict(_selectedDistrict);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredSchools =
                searchQuery.isEmpty
                    ? allSchools
                    : allSchools
                        .where(
                          (s) => s.toLowerCase().contains(
                            searchQuery.toLowerCase(),
                          ),
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
                          onChanged:
                              (val) => setModalState(() => searchQuery = val),
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
                        child:
                            filteredSchools.isEmpty
                                ? const Center(
                                  child: Text(
                                    'Bunday maktab topilmadi',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                )
                                : ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 8,
                                  ),
                                  itemCount: filteredSchools.length,
                                  separatorBuilder:
                                      (_, _) => const SizedBox(height: 8),
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
                                      backgroundColor:
                                          isSelected
                                              ? AppColors.primaryLight
                                              : AppColors.glassWellFill,
                                      borderColor:
                                          isSelected
                                              ? AppColors.primary.withValues(
                                                alpha: 0.4,
                                              )
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
                                            color:
                                                isSelected
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
                                                fontWeight:
                                                    isSelected
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                                color:
                                                    isSelected
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
          () =>
              _errorMessage =
                  'Iltimos, Chortoq tumanidagi maktabingizni tanlang.',
        );
        return;
      }
    } else if (_signUpStep == 2) {
      final phone = _phoneCtrl.text.trim();
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 9) {
        setState(
          () =>
              _errorMessage =
                  'Iltimos, to‘liq telefon raqamingizni kiriting (masalan: +998 90 123 45 67).',
        );
        return;
      }
    }

    if (_signUpStep < 3) {
      setState(() => _signUpStep++);
    }
  }

  TextStyle _myGovFont({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color color = AppColors.textPrimary,
    double letterSpacing = -0.1,
    double? height,
  }) {
    return GoogleFonts.golosText(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  bool get _hasMinLength => _signUpPasswordCtrl.text.trim().length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_signUpPasswordCtrl.text);
  bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(_signUpPasswordCtrl.text);
  bool get _hasDigit => RegExp(r'[0-9]').hasMatch(_signUpPasswordCtrl.text);

  int get _passwordStrengthScore =>
      (_hasMinLength ? 1 : 0) +
      (_hasUppercase ? 1 : 0) +
      (_hasLowercase ? 1 : 0) +
      (_hasDigit ? 1 : 0);

  void _previousStep() {
    setState(() {
      _errorMessage = null;
      if (_signUpStep > 0) _signUpStep--;
    });
  }

  void _handleSignUp() async {
    setState(() => _errorMessage = null);

    if (!_hasMinLength || !_hasUppercase || !_hasLowercase || !_hasDigit) {
      setState(
        () =>
            _errorMessage =
                'Parolda kamida 8 ta belgi, 1 ta katta harf (A-Z), 1 ta kichik harf (a-z) va 1 ta raqam (0-9) bo‘lishi shart.',
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
      district: _selectedDistrict,
      institutionName:
          _institutionCtrl.text.trim().isNotEmpty
              ? _institutionCtrl.text.trim()
              : '9-sonli inklyuziv ta’lim tayanch maktabi',
      specialization:
          _specializationCtrl.text.trim().isNotEmpty
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
                            child:
                                _tabController.index == 0
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
        const Icon(LucideIcons.landmark, color: AppColors.primary, size: 38),
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
            boxShadow:
                isSelected
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
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color:
                        isSelected
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Shaxsiy kabinetga kirish',
          style: _myGovFont(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.25,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Telefon raqamingiz yoki elektron pochtangiz orqali kiring.',
          style: _myGovFont(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF475569),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF2D48A)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 17,
                color: Color(0xFF9A6700),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bu versiyada ma’lumotlar faqat ushbu qurilma yoki brauzerda saqlanadi. Haqiqiy bolalar ma’lumotlarini kiritmang.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: Color(0xFF704D00),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

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
              onPressed: () => setState(() => _loginObscure = !_loginObscure),
            ),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: auth.isLoading ? null : _handleLogin,
            child:
                auth.isLoading
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
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: Text(
                  'Yangi hisob ochish (Ro‘yxatdan o‘tish)',
                  style: _myGovFont(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _showPasswordRecoveryDialog(context),
                child: Text(
                  'Parolni unutdingizmi?',
                  style: _myGovFont(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPasswordRecoveryDialog(BuildContext context) {
    final ctrl = TextEditingController(text: _loginIdentifierCtrl.text.trim());
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Parolni tiklash so‘rovi'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Telefon raqamingiz yoki elektron pochtangizni kiriting. Muassasa yoki tizim administratoriga parolni tiklash so‘rovi yuboriladi va sizga vaqtinchalik parol taqdim etiladi.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(
                      labelText: 'Telefon raqam yoki Email *',
                      hintText: '+998 90 123 45 67 yoki login@talim.uz',
                      prefixIcon: Icon(
                        LucideIcons.keyRound,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Bekor qilish'),
              ),
              FilledButton(
                onPressed: () async {
                  final res = await context
                      .read<AuthProvider>()
                      .requestPasswordRecovery(ctrl.text);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res['message'] as String),
                        backgroundColor:
                            res['success'] == true
                                ? AppColors.success
                                : AppColors.error,
                      ),
                    );
                  }
                },
                child: const Text('So‘rov yuborish'),
              ),
            ],
          ),
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
            child: Text(
              'Allaqachon hisobingiz bormi? Kirish',
              style: _myGovFont(
                color: const Color(0xFF475569),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepProgressBar() {
    final stepTitles = ['Shaxsiy', 'Soha', 'Aloqa', 'Parol'];

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
                    color: isPassed ? AppColors.primary : AppColors.borderSlate,
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
                style: _myGovFont(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: const Color(0xFF64748B),
                ),
              ),
              Flexible(
                child: Text(
                  stepTitles[_signUpStep],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _myGovFont(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
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
          Text(
            '1-Qadam: Ism va Familiya',
            style: _myGovFont(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Tizimda rasmiy hujjatlar sizning nomingizdan yuritiladi.',
            style: _myGovFont(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _firstNameCtrl,
            textCapitalization: TextCapitalization.words,
            style: _myGovFont(fontSize: 14, fontWeight: FontWeight.w500),
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
            style: _myGovFont(fontSize: 14, fontWeight: FontWeight.w500),
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
      (UserRole.psychologist, 'Amaliyotchi psixolog', LucideIcons.idCard),
      (UserRole.speechTherapist, 'Logoped-defektolog', LucideIcons.mic),
      (UserRole.specialEducation, 'Defektolog', LucideIcons.shield),
      (
        UserRole.specialEdTeacher,
        'Maxsus o‘qituvchi',
        LucideIcons.graduationCap,
      ),
      (UserRole.teacher, 'Fan o‘qituvchisi', LucideIcons.bookOpen),
    ];

    final selectedSchool =
        _institutionCtrl.text.isNotEmpty
            ? _institutionCtrl.text
            : 'Maktab tanlanmagan';

    return KeyedSubtree(
      key: const ValueKey('step_2_profession'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '2-Qadam: Soha va maktab',
            style: _myGovFont(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Sohangiz va maktabingizni tanlang.',
            style: _myGovFont(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Mutaxassislik sohasi *',
            style: _myGovFont(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                availableRoles.map((item) {
                  final r = item.$1;
                  final title = item.$2;
                  final icon = item.$3;
                  final isSelected = _selectedRole == r;

                  return SurfaceCard(
                    elevated: false,
                    borderRadius: 12,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    backgroundColor:
                        isSelected
                            ? AppColors.primaryLight
                            : const Color(0xFFF8FAFC),
                    borderColor:
                        isSelected
                            ? AppColors.primary.withValues(alpha: 0.55)
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
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AppColors.primary.withValues(
                                        alpha: 0.35,
                                      )
                                      : const Color(0xFFE2E8F0),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            icon,
                            size: 16,
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _myGovFont(
                              fontSize: 13.5,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : const Color(0xFF1E293B),
                              letterSpacing: -0.05,
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            LucideIcons.circleCheck,
                            color: AppColors.primary,
                            size: 15,
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Tuman / shahar *',
            style: _myGovFont(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedDistrict,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(
                LucideIcons.mapPin,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            items:
                NamanganData.districts
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                _selectedDistrict = val;
                final schools = NamanganData.getSchoolsForDistrict(val);
                _institutionCtrl.text = schools.isNotEmpty ? schools.first : '';
              });
            },
          ),
          const SizedBox(height: 14),
          Text(
            'Maktab *',
            style: _myGovFont(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SurfaceCard(
            elevated: false,
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            backgroundColor: const Color(0xFFF8FAFC),
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
                    style: _myGovFont(
                      fontSize: 13.5,
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
          Text(
            '3-Qadam: Aloqa',
            style: _myGovFont(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Kirish uchun telefon raqamingizni kiriting.',
            style: _myGovFont(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: _myGovFont(fontSize: 14, fontWeight: FontWeight.w500),
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
            style: _myGovFont(fontSize: 14, fontWeight: FontWeight.w500),
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
          Text(
            '4-Qadam: Parol',
            style: _myGovFont(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Hisobingiz uchun kuchli parol o‘rnating.',
            style: _myGovFont(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _signUpPasswordCtrl,
            obscureText: _signUpObscure,
            onChanged: (_) => setState(() => _errorMessage = null),
            style: _myGovFont(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: 'Parol *',
              hintText: 'Masalan: Talim2026',
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
                onPressed:
                    () => setState(() => _signUpObscure = !_signUpObscure),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPasswordRequirementsBox(),
          const SizedBox(height: 14),
          TextField(
            controller: _signUpConfirmPasswordCtrl,
            obscureText: _signUpConfirmObscure,
            onChanged: (_) => setState(() => _errorMessage = null),
            style: _myGovFont(fontSize: 14, fontWeight: FontWeight.w500),
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
                onPressed:
                    () => setState(
                      () => _signUpConfirmObscure = !_signUpConfirmObscure,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirementsBox() {
    final score = _passwordStrengthScore;
    final Color activeColor =
        score <= 1
            ? AppColors.error
            : score == 2
            ? const Color(0xFFD97706)
            : score == 3
            ? AppColors.primary
            : AppColors.success;
    final String strengthLabel =
        score == 0
            ? 'Parol talablari'
            : score == 1
            ? 'Kuchsiz parol'
            : score == 2
            ? 'O‘rtacha parol'
            : score == 3
            ? 'Yaxshi parol'
            : 'Kuchli parol';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strengthLabel,
                style: _myGovFont(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: score == 0 ? const Color(0xFF334155) : activeColor,
                ),
              ),
              Text(
                '$score / 4',
                style: _myGovFont(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(4, (index) {
              final passed = index < score;
              return Expanded(
                child: Container(
                  height: 4.5,
                  margin: EdgeInsets.only(right: index == 3 ? 0 : 5),
                  decoration: BoxDecoration(
                    color: passed ? activeColor : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 11),
          _buildPasswordRuleRow('Kamida 8 ta belgi', _hasMinLength),
          const SizedBox(height: 6),
          _buildPasswordRuleRow('Kamida 1 ta katta harf (A–Z)', _hasUppercase),
          const SizedBox(height: 6),
          _buildPasswordRuleRow('Kamida 1 ta kichik harf (a–z)', _hasLowercase),
          const SizedBox(height: 6),
          _buildPasswordRuleRow('Kamida 1 ta raqam (0–9)', _hasDigit),
        ],
      ),
    );
  }

  Widget _buildPasswordRuleRow(String text, bool met) {
    return Row(
      children: [
        Icon(
          met ? LucideIcons.circleCheck : LucideIcons.circle,
          size: 15,
          color: met ? AppColors.success : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: _myGovFont(
              fontSize: 12.5,
              fontWeight: met ? FontWeight.w600 : FontWeight.w500,
              color: met ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
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
              onPressed:
                  auth.isLoading
                      ? null
                      : (isLastStep ? _handleSignUp : _nextStep),
              child:
                  auth.isLoading
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
