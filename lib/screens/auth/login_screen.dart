import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/namangan_data.dart';
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

  // --- SIGN UP STEP MANAGEMENT (1 tadan so'rash uchun) ---
  int _signUpStep = 0; // 0: Ism-familiya, 1: Kasb va Maktab, 2: Telefon va Pochta, 3: Parol va Xulosa

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

  // --- MyGov / iOS USLUBIDAGI CHORTOQ MAKTABLARINI TANLASH MODALI ---
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
                      (s) =>
                          s.toLowerCase().contains(searchQuery.toLowerCase()),
                    )
                    .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // iOS pill grabber
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ta’lim muassasasini tanlash',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Namangan viloyati • Chortoq tumani (54 ta maktab)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Qidiruv maydoni
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        onChanged: (val) {
                          setModalState(() => searchQuery = val);
                        },
                        decoration: InputDecoration(
                          hintText: 'Maktab raqami yoki nomini qidiring...',
                          prefixIcon: const Icon(CupertinoIcons.search, size: 20, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Maktablar ro'yxati
                    Expanded(
                      child: filteredSchools.isEmpty
                          ? const Center(
                              child: Text(
                                'Bunday maktab topilmadi',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                              itemCount: filteredSchools.length,
                              itemBuilder: (context, index) {
                                final school = filteredSchools[index];
                                final isSelected = _institutionCtrl.text == school;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFEBF3FF) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF0052CC) : const Color(0xFFE2E8F0),
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    leading: Icon(
                                      Icons.account_balance_outlined,
                                      color: isSelected ? const Color(0xFF0052CC) : const Color(0xFF64748B),
                                      size: 20,
                                    ),
                                    title: Text(
                                      school,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? const Color(0xFF0052CC) : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0052CC), size: 20)
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _institutionCtrl.text = school;
                                        _errorMessage = null;
                                      });
                                      Navigator.of(sheetContext).pop();
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- LOGIN FUNKSIYASI ---
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

  // --- QADAMLAR VALIDATSIYASI VA KEYINGISIGA O'TISH ---
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

  // --- YAKUNIY RO'YXATDAN O'TISH FUNKSIYASI ---
  void _handleSignUp() async {
    setState(() => _errorMessage = null);

    if (_signUpPasswordCtrl.text.trim().length < 6) {
      setState(
        () => _errorMessage = 'Parol kamida 6 ta belgidan iborat bo‘lishi lozim.',
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- MyGov USLUBIDAGI DAVLAT STANDARTI SHAPKASI ---
                  _buildMyGovHeader(),
                  const SizedBox(height: 20),

                  // --- TAB TANLASH: KIRISH / RO'YXATDAN O'TISH ---
                  _buildMyGovTabs(),
                  const SizedBox(height: 16),

                  // --- XATOLIK BANNERI ---
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // --- ASOSIY MyGov FORMA KARTASI ---
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) {
                        if (_tabController.index == 0) {
                          return _buildLoginView(auth);
                        } else {
                          return _buildStepByStepSignUpView(auth);
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- MyGov RASMIY FOOTER ---
                  const Center(
                    child: Text(
                      'O‘zbekiston Respublikasi Maktabgacha va maktab ta’limi vazirligi © 2026',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- MyGov DAVLAT SHAPKASI ---
  Widget _buildMyGovHeader() {
    return Column(
      children: [
        // Rasmiy Gerb / Nishon
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF0052CC),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0052CC).withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.account_balance_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'O‘ZBEKISTON RESPUBLIKASI MAKTABGACHA VA MAKTAB TA’LIMI VAZIRLIGI',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'TA’LIM NAZORAT',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
            color: Color(0xFF0B3A82),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Yagona inklyuziv ta’lim monitoring tizimi',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --- MyGov TABLARINI TANLASH ---
  Widget _buildMyGovTabs() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: const Color(0xFF0052CC),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.login_rounded, size: 18),
            text: 'Kirish',
          ),
          Tab(
            icon: Icon(Icons.person_add_alt_1_rounded, size: 18),
            text: 'Ro‘yxatdan o‘tish',
          ),
        ],
      ),
    );
  }

  // ===================== TAB 1: KIRISH (LOGIN) =====================
  Widget _buildLoginView(AuthProvider auth) {
    // Namunaviy test profillari (faqat o'rganuvchilar uchun 1 klikli tezkor kirish)
    final demoProfiles = [
      (SeedData.users.firstWhere((u) => u.role == UserRole.psychologist), 'Psixolog'),
      (SeedData.users.firstWhere((u) => u.role == UserRole.speechTherapist), 'Logoped'),
      (SeedData.users.firstWhere((u) => u.role == UserRole.specialEducation), 'Defektolog'),
      (SeedData.users.firstWhere((u) => u.role == UserRole.teacher), 'O‘qituvchi'),
      (SeedData.users.firstWhere((u) => u.role == UserRole.coordinator), 'Koordinator'),
      (SeedData.users.firstWhere((u) => u.role == UserRole.superAdmin), 'Admin'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tizimga kirish',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Telefon raqamingiz yoki elektron pochtangizni kiriting',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),

        // Telefon yoki Pochta kiritish
        TextField(
          controller: _loginIdentifierCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Telefon raqam yoki Email',
            hintText: '+998 90 123 45 67 yoki login@talim.uz',
            prefixIcon: const Icon(CupertinoIcons.person, size: 20, color: Color(0xFF0052CC)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0052CC), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Parol kiritish
        TextField(
          controller: _loginPasswordCtrl,
          obscureText: _loginObscure,
          decoration: InputDecoration(
            labelText: 'Parol',
            prefixIcon: const Icon(CupertinoIcons.lock, size: 20, color: Color(0xFF0052CC)),
            suffixIcon: IconButton(
              icon: Icon(
                _loginObscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                size: 20,
                color: const Color(0xFF64748B),
              ),
              onPressed: () => setState(() => _loginObscure = !_loginObscure),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0052CC), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Kirish tugmasi
        SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0052CC),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: auth.isLoading ? null : _handleLogin,
            child: auth.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
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
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 14),

        // Ro'yxatdan o'tishga yo'naltirish
        Center(
          child: TextButton(
            onPressed: () => _tabController.animateTo(1),
            child: const Text(
              'Yangi hisob ochish (Ro‘yxatdan o‘tish)',
              style: TextStyle(
                color: Color(0xFF0052CC),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),

        const Divider(height: 24, color: Color(0xFFE2E8F0)),

        // Tezkor sinash uchun namunaviy hisoblar
        const Text(
          'Namunaviy hisoblar (1-klikda sinash):',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: demoProfiles.map((item) {
            final user = item.$1;
            final label = item.$2;
            return ActionChip(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              backgroundColor: const Color(0xFFF1F5F9),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B3A82),
                ),
              ),
              onPressed: () => _selectDemoAccount(user),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ===================== TAB 2: RO'YXATDAN O'TISH (SIGN UP) =====================
  Widget _buildStepByStepSignUpView(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepProgressBar(),
        const SizedBox(height: 18),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _buildCurrentStepContent(auth),
        ),

        const SizedBox(height: 18),
        _buildStepActionButtons(auth),

        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => _tabController.animateTo(0),
            child: const Text(
              'Allaqachon hisobingiz bormi? Kirish',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepProgressBar() {
    final stepTitles = ['Ism-familiya', 'Kasb & Maktab', 'Aloqa', 'Parol'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(4, (index) {
              final isPassed = index < _signUpStep;
              final isCurrent = index == _signUpStep;

              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 3,
                    right: index == 3 ? 0 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: isPassed || isCurrent
                        ? const Color(0xFF0052CC)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QADAM ${_signUpStep + 1} / 4',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                stepTitles[_signUpStep],
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0052CC),
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

  // 1-QADAM: SHAXSIY MA'LUMOTLAR
  Widget _buildStep1PersonalInfo() {
    return KeyedSubtree(
      key: const ValueKey('step_1_personal'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '1-Qadam: Ism va Familiyangiz',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tizimda rasmiy hujjatlar sizning nomingizdan yuritiladi.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _firstNameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Ismingiz *',
              hintText: 'Masalan: Dilnoza',
              prefixIcon: const Icon(CupertinoIcons.person, size: 20, color: Color(0xFF0052CC)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lastNameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Familiyangiz *',
              hintText: 'Masalan: Qodirova',
              prefixIcon: const Icon(CupertinoIcons.person_badge_minus, size: 20, color: Color(0xFF0052CC)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2-QADAM: KASBIY MUTAXASSISLIK VA MAKTAB
  Widget _buildStep2ProfessionalInfo() {
    final availableRoles = [
      (UserRole.psychologist, 'Amaliyotchi psixolog', Icons.psychology_outlined),
      (UserRole.speechTherapist, 'Logoped-defektolog', Icons.record_voice_over_outlined),
      (UserRole.specialEducation, 'Maxsus pedagog (Defektolog)', Icons.extension_outlined),
      (UserRole.teacher, 'Fan o‘qituvchisi / Sinf rahbari', Icons.menu_book_rounded),
      (UserRole.institutionAdmin, 'Maktab koordinatori', Icons.business_outlined),
      (UserRole.reviewer, 'Metodik inspektor', Icons.remove_red_eye_outlined),
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
            '2-Qadam: Mutaxassislik va Ta’lim muassasasi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'O‘z kasbingizni va Chortoq tumanidagi maktabingizni tanlang.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          // Kasbni tanlash
          const Text(
            'Mutaxassislik sohasi *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableRoles.map((item) {
              final r = item.$1;
              final title = item.$2;
              final icon = item.$3;
              final isSelected = _selectedRole == r;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedRole = r;
                    _specializationCtrl.text = r.label;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEBF3FF) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0052CC) : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: isSelected ? const Color(0xFF0052CC) : const Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF0052CC) : const Color(0xFF0F172A),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF0052CC), size: 14),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Maktab tanlash
          const Text(
            'Ta’lim muassasasi (Chortoq tumani) *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),

          InkWell(
            onTap: () => _showIosSchoolPickerModal(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0052CC).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_rounded, color: Color(0xFF0052CC), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedSchool,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0052CC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Tanlash',
                      style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3-QADAM: ALOQA MA'LUMOTLARI
  Widget _buildStep3ContactInfo() {
    return KeyedSubtree(
      key: const ValueKey('step_3_contact'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '3-Qadam: Aloqa Ma’lumotlari',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Telefon raqamingiz tizimga kirish uchun xizmat qiladi.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Telefon raqam *',
              hintText: '+998 90 123 45 67',
              prefixIcon: const Icon(CupertinoIcons.phone, size: 20, color: Color(0xFF0052CC)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Elektron pochta (Ixtiyoriy)',
              hintText: 'mutaxassis@talim.uz',
              prefixIcon: const Icon(CupertinoIcons.mail, size: 20, color: Color(0xFF0052CC)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4-QADAM: XAVFSIZLIK VA PAROL
  Widget _buildStep4SecurityInfo() {
    return KeyedSubtree(
      key: const ValueKey('step_4_security'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '4-Qadam: Parol va Tasdiqlash',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kamida 6 ta belgidan iborat parol o‘rnating.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          // Qisqa xulosa bloki
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'F.I.Sh: ${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Soha: ${_selectedRole.label}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF0052CC), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Maktab: ${_institutionCtrl.text.trim()}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _signUpPasswordCtrl,
            obscureText: _signUpObscure,
            decoration: InputDecoration(
              labelText: 'Parol *',
              hintText: 'Kamida 6 ta belgi',
              prefixIcon: const Icon(CupertinoIcons.lock, size: 20, color: Color(0xFF0052CC)),
              suffixIcon: IconButton(
                icon: Icon(
                  _signUpObscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                  size: 20,
                  color: const Color(0xFF64748B),
                ),
                onPressed: () => setState(() => _signUpObscure = !_signUpObscure),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _signUpConfirmPasswordCtrl,
            obscureText: _signUpConfirmObscure,
            decoration: InputDecoration(
              labelText: 'Parolni tasdiqlang *',
              prefixIcon: const Icon(CupertinoIcons.lock_shield, size: 20, color: Color(0xFF0052CC)),
              suffixIcon: IconButton(
                icon: Icon(
                  _signUpConfirmObscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                  size: 20,
                  color: const Color(0xFF64748B),
                ),
                onPressed: () => setState(() => _signUpConfirmObscure = !_signUpConfirmObscure),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // HARAKAT TUGMALARI
  Widget _buildStepActionButtons(AuthProvider auth) {
    final isLastStep = _signUpStep == 3;

    return Row(
      children: [
        if (_signUpStep > 0) ...[
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 46,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                onPressed: auth.isLoading ? null : _previousStep,
                child: const Text('Orqaga', style: TextStyle(color: Color(0xFF0F172A), fontSize: 13)),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0052CC),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: auth.isLoading ? null : (isLastStep ? _handleSignUp : _nextStep),
              child: auth.isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isLastStep ? 'Ro‘yxatdan o‘tish' : 'Keyingisi',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
