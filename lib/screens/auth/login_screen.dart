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

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- SOHA / PROFESSIYA TANLASH HOLATI ---
  UserRole? _activeProfession;

  // --- LOGIN CONTROLLERS ---
  final _loginIdentifierCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController(text: 'Parol2026!');
  bool _loginObscure = true;

  // --- SIGN UP STEP MANAGEMENT (1 tadan so'rash uchun) ---
  int _signUpStep = 0; // 0: Ism-familiya, 1: Kasb va Maktab, 2: Telefon va Pochta, 3: Parol va Xulosa

  // Qadam 1: Shaxsiy ma'lumotlar (Ism birinchi, familiya ikkinchi)
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();

  // Qadam 2: Kasbiy faoliyat va Chortoq tumani maktabi
  UserRole _selectedRole = UserRole.psychologist;
  final String _selectedDistrict = 'Chortoq tumani';
  String? _selectedSchoolDropdown = '9-sonli inklyuziv ta’lim tayanch maktabi';
  final _institutionCtrl = TextEditingController(text: '9-sonli inklyuziv ta’lim tayanch maktabi');
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
      _selectedSchoolDropdown = initialSchools.first;
      _institutionCtrl.text = initialSchools.first;
    }
  }

  // --- iOS STYLE CHORTOQ MAKTABLARINI TANLASH MODAL OYNASI ---
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
                : allSchools.where((s) => s.toLowerCase().contains(searchQuery.toLowerCase())).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // iOS Grabber pill
                    Center(
                      child: Container(
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC7C7CC),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chortoq tumani maktablari',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.4,
                                    color: Color(0xFF1C1C1E),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Jami 54 ta ta’lim muassasasi',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                                ),
                              ],
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: const Text('Yopish', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF007AFF))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // iOS Search field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CupertinoSearchTextField(
                        placeholder: 'Maktab raqami yoki nomini izlang...',
                        onChanged: (val) {
                          setModalState(() {
                            searchQuery = val.trim();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // List of schools in iOS card style
                    Expanded(
                      child: filteredSchools.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(CupertinoIcons.search, size: 40, color: Color(0xFF8E8E93)),
                                  const SizedBox(height: 10),
                                  Text(
                                    '"$searchQuery" bo‘yicha maktab topilmadi',
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              itemCount: filteredSchools.length,
                              itemBuilder: (context, index) {
                                final school = filteredSchools[index];
                                final isSelected = _institutionCtrl.text == school;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFE5E5EA),
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    leading: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF007AFF).withValues(alpha: 0.12)
                                            : const Color(0xFFF2F2F7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        CupertinoIcons.building_2_fill,
                                        size: 16,
                                        color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF8E8E93),
                                      ),
                                    ),
                                    title: Text(
                                      school,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF1C1C1E),
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(CupertinoIcons.checkmark_circle_fill, color: Color(0xFF34C759), size: 20)
                                        : const Icon(CupertinoIcons.chevron_forward, color: Color(0xFFC7C7CC), size: 16),
                                    onTap: () {
                                      setState(() {
                                        _institutionCtrl.text = school;
                                        _selectedSchoolDropdown = school;
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

  // --- SOHANI TANLASH VA O'TISH ---
  void _selectProfession(UserRole role) {
    setState(() {
      _activeProfession = role;
      _selectedRole = role;
      _errorMessage = null;

      // Shu sohadagi birinchi namunaviy foydalanuvchini avtomatik tayyorlash
      final matchingUsers = SeedData.users.where((u) {
        if (role == UserRole.institutionAdmin || role == UserRole.superAdmin) {
          return u.role == UserRole.institutionAdmin || u.role == UserRole.superAdmin;
        }
        return u.role == role;
      }).toList();

      if (matchingUsers.isNotEmpty) {
        _loginIdentifierCtrl.text = matchingUsers.first.email;
        _specializationCtrl.text = matchingUsers.first.specialization ?? role.label;
      } else {
        _loginIdentifierCtrl.text = '';
        _specializationCtrl.text = role.label;
      }
    });
  }

  void _resetProfession() {
    setState(() {
      _activeProfession = null;
      _errorMessage = null;
      _signUpStep = 0;
    });
  }

  // --- LOGIN FUNKSIYASI ---
  void _handleLogin() async {
    setState(() => _errorMessage = null);

    final auth = context.read<AuthProvider>();
    final result = await auth.login(
      _loginIdentifierCtrl.text.trim(),
      _loginPasswordCtrl.text.trim(),
      requiredRole: _activeProfession,
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
        setState(() => _errorMessage = 'Iltimos, Chortoq tumanidagi maktabingizni tanlang.');
        return;
      }
    } else if (_signUpStep == 2) {
      final phone = _phoneCtrl.text.trim();
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 9) {
        setState(() => _errorMessage = 'Iltimos, to‘liq telefon raqamingizni kiriting (masalan: +998 90 123 45 67).');
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
      setState(() => _errorMessage = 'Parol kamida 6 ta belgidan iborat bo‘lishi lozim.');
      return;
    }

    if (_signUpPasswordCtrl.text.trim() != _signUpConfirmPasswordCtrl.text.trim()) {
      setState(() => _errorMessage = 'Kiritilgan parollar bir-biriga mos kelmadi.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final roleToRegister = _activeProfession ?? _selectedRole;

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _activeProfession == null ? 760 : 540,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _activeProfession == null
                    ? _buildProfessionSelectionGrid()
                    : _buildProfessionPortalView(auth),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===================== 1-BOSQICH: SOHANI TANLASH EKRANI =====================
  Widget _buildProfessionSelectionGrid() {
    final professions = [
      UserRole.speechTherapist,
      UserRole.psychologist,
      UserRole.specialEducation,
      UserRole.teacher,
      UserRole.institutionAdmin,
      UserRole.reviewer,
    ];

    return Column(
      key: const ValueKey('profession_selection_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ILОVA LOGO VA NOMI
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'TA’LIM NAZORAT',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Alohida ta’lim ehtiyojlari bo‘lgan bolalar rivojlanish monitoringi platformasi',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // SOHA TANLASH YO'RIQNOMASI VA OGOHLANTIRISH
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: const [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.badge_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Mutaxassislik Sohasi Bo‘yicha Kirish Portali',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'O‘z kasbiy mutaxassisligingizga mos portalni tanlang. Tanlangandan so‘ng sohani o‘zgartirib bo‘lmaydi va faqat sizning vakolatingizdagi bolalar ma’lumotlari hamda baholash mezonlari ochiladi.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // SOHALAR GRIDI / KARTALARI
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 580;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: professions.map((role) {
                final width = isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
                return SizedBox(
                  width: width,
                  child: _buildProfessionCard(role),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 20),
        const Text(
          'O‘zbekiston Respublikasi Maktabgacha va maktab ta’limi vazirligi inklyuziv ta’lim standarti asosida.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }

  // SOHA KARTASI
  Widget _buildProfessionCard(UserRole role) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _selectProfession(role),
        borderRadius: BorderRadius.circular(16),
        hoverColor: role.color.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: role.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(role.icon, color: role.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.label,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          role.professionTitle,
                          style: TextStyle(fontSize: 11, color: role.color, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: role.color),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                role.domainDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.35),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 12, color: role.color),
                    const SizedBox(width: 5),
                    Text(
                      'Sohaga kirish',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: role.color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== 2-BOSQICH: TANLANGAN SOHA PORTALI =====================
  Widget _buildProfessionPortalView(AuthProvider auth) {
    final role = _activeProfession!;

    // Ushbu sohaga tegishli namunaviy foydalanuvchilar
    final matchingUsers = SeedData.users.where((u) {
      if (role == UserRole.institutionAdmin || role == UserRole.superAdmin) {
        return u.role == UserRole.institutionAdmin || u.role == UserRole.superAdmin;
      }
      return u.role == role;
    }).toList();

    return Column(
      key: ValueKey('portal_view_${role.code}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ORQAGA QAYTISH TUGMASI (Faqat kirishdan avval)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _resetProfession,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('← Boshqa sohani tanlash'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 8),

        // TANLANGAN KASBIY SOHA BANNERI (QULFLANGAN)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: role.color.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: role.color.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: role.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(role.icon, color: role.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            role.label,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded, size: 10, color: AppColors.success),
                              SizedBox(width: 4),
                              Text(
                                'Qulflangan',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.professionTitle,
                      style: TextStyle(fontSize: 12, color: role.color, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // XAVFSIZLIK VA BIRIKTIRILGANLIK OGOHLANTIRISHI
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: role.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: role.color.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_rounded, size: 16, color: role.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ushbu portal orqali kirgandan so‘ng profilingiz "${role.label}" sohasiga biriktiriladi va o‘zgartirib bo‘lmaydi. Siz faqat o‘z sohangizga oid bolalar ma’lumotlarini kiritishingiz mumkin.',
                  style: TextStyle(fontSize: 11, color: role.color.withValues(alpha: 0.9), height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // TAB TANLASH: KIRISH YOKI RO'YXATDAN O'TISH
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(4),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: role.color,
              borderRadius: BorderRadius.circular(10),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Sohaga kirish (Login)'),
              Tab(text: 'Yangi hisob ochish (Sign Up)'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // XATOLIK BANNERI
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // FORMA KARTASI
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                if (_tabController.index == 0) {
                  return _buildLoginView(auth, role, matchingUsers);
                } else {
                  return _buildStepByStepSignUpView(auth, role);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ===================== TAB 1: SOHAGA KIRISH =====================
  Widget _buildLoginView(AuthProvider auth, UserRole role, List<UserModel> matchingUsers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // SOHANING RASMIY BIRIKTIRILGAN MUTAXASSISLARI
        if (matchingUsers.isNotEmpty) ...[
          Text(
            '${role.label} xodimlari (1 klikda kirish):',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          ...matchingUsers.map((u) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: role.color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: role.color.withValues(alpha: 0.25)),
              ),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: role.color.withValues(alpha: 0.15),
                  child: Icon(role.icon, color: role.color, size: 18),
                ),
                title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('${u.specialization ?? role.label} • ${u.phone ?? u.email}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                trailing: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: role.color.withValues(alpha: 0.15),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  onPressed: () => _selectDemoAccount(u),
                  child: Text('Kirish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: role.color)),
                ),
              ),
            );
          }),
          const Divider(height: 24),
        ],

        const Text(
          'Yoki telefon raqami / email orqali kiring:',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),

        // Telefon yoki Email
        TextField(
          controller: _loginIdentifierCtrl,
          decoration: const InputDecoration(
            labelText: 'Telefon raqami yoki Email',
            hintText: '+998 90 123-45-67 yoki mutaxassis@talim.uz',
            prefixIcon: Icon(Icons.person_outline, size: 20),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),

        // Parol
        TextField(
          controller: _loginPasswordCtrl,
          obscureText: _loginObscure,
          decoration: InputDecoration(
            labelText: 'Parol',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _loginObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _loginObscure = !_loginObscure),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Kirish tugmasi
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: role.color,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: auth.isLoading ? null : _handleLogin,
          child: auth.isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('${role.label} sifatida kirish', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),

        // Ro'yxatdan o'tish havolasi
        Center(
          child: TextButton(
            onPressed: () => _tabController.animateTo(1),
            child: Text('Ushbu sohada yangimisiz? Ro‘yxatdan o‘tish', style: TextStyle(color: role.color)),
          ),
        ),
      ],
    );
  }

  // ===================== TAB 2: RO'YXATDAN O'TISH (SO'ROVNOMA) =====================
  Widget _buildStepByStepSignUpView(AuthProvider auth, UserRole role) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepProgressBar(role),
        const SizedBox(height: 18),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildCurrentStepContent(auth, role),
        ),

        const SizedBox(height: 16),
        _buildStepActionButtons(auth, role),

        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () => _tabController.animateTo(0),
            child: const Text('Allaqachon hisobingiz bormi? Kirish'),
          ),
        ),
      ],
    );
  }

  Widget _buildStepProgressBar(UserRole role) {
    final stepTitles = ['Ism-familiya', 'Maktab', 'Aloqa', 'Xavfsizlik'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(14),
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
                        ? const Color(0xFF007AFF)
                        : const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(2),
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
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: Color(0xFF8E8E93),
                ),
              ),
              Text(
                stepTitles[_signUpStep],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF007AFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent(AuthProvider auth, UserRole role) {
    switch (_signUpStep) {
      case 0:
        return _buildStep1PersonalInfo();
      case 1:
        return _buildStep2ProfessionalInfo(role);
      case 2:
        return _buildStep3ContactInfo();
      case 3:
        return _buildStep4SecurityInfo(role);
      default:
        return const SizedBox.shrink();
    }
  }

  // 1-QADAM: SHAXSIY MA'LUMOTLAR (Avval Ism, keyin Familiya - iOS style)
  Widget _buildStep1PersonalInfo() {
    return KeyedSubtree(
      key: const ValueKey('step_1_personal'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '1-Qadam: Ism va Familiyangiz',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.3, color: Color(0xFF1C1C1E)),
          ),
          const SizedBox(height: 3),
          const Text(
            'Tizimda sizning nomingizdan rasmiy xulosalar va baholashlar yuritiladi.',
            style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
          ),
          const SizedBox(height: 18),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E5EA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 1. ISMI BIRINCHI SO'RALADI
                TextFormField(
                  controller: _firstNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ismingiz *',
                    hintText: 'Masalan: Dilnoza',
                    prefixIcon: Icon(CupertinoIcons.person, size: 20, color: Color(0xFF8E8E93)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const Divider(height: 1, indent: 48, color: Color(0xFFE5E5EA)),
                // 2. FAMILIYASI KEYIN SO'RALADI
                TextFormField(
                  controller: _lastNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Familiyangiz *',
                    hintText: 'Masalan: Qodirova',
                    prefixIcon: Icon(CupertinoIcons.person_badge_minus, size: 20, color: Color(0xFF8E8E93)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2-QADAM: KASBIY FAOLIYAT VA CHORTOQ MAKTABI (iOS style)
  Widget _buildStep2ProfessionalInfo(UserRole role) {
    final selectedSchool = _institutionCtrl.text.isNotEmpty
        ? _institutionCtrl.text
        : 'Maktab tanlanmagan';

    return KeyedSubtree(
      key: const ValueKey('step_2_profession'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '2-Qadam: Kasbingiz va Ta’lim Muassasasi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.3, color: Color(0xFF1C1C1E)),
          ),
          const SizedBox(height: 3),
          const Text(
            'Chortoq tumani maktablari ro‘yxatidan o‘z ta’lim muassasangizni tanlang.',
            style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
          ),
          const SizedBox(height: 16),

          // 1. SOHA QULFI (iOS Card)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: role.color.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: role.color.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: role.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(role.icon, color: role.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.label,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: role.color),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Biriktirilgan soha (Qulflangan)',
                        style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                      ),
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.lock_fill, size: 16, color: Color(0xFF8E8E93)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. HUDUD: CHORTOQ TUMANI (iOS Banner)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.location_solid, size: 18, color: Color(0xFF007AFF)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Chortoq tumani',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '54 ta maktab',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF007AFF)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. MAKTABNI TANLASH TUGMASI (iOS Card)
          InkWell(
            onTap: () => _showIosSchoolPickerModal(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _institutionCtrl.text.isNotEmpty ? const Color(0xFF007AFF) : const Color(0xFFE5E5EA),
                  width: _institutionCtrl.text.isNotEmpty ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(CupertinoIcons.building_2_fill, color: Color(0xFF007AFF), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ta’lim muassasasi (Maktab)',
                          style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93), fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          selectedSchool,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1C1C1E),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Tanlash', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF007AFF))),
                        SizedBox(width: 4),
                        Icon(CupertinoIcons.chevron_up_chevron_down, size: 12, color: Color(0xFF007AFF)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Yuqoridagi maydonga bosing va Chortoq tumanidagi 54 ta maktabdan o‘zingiznikini tanlang.',
              style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
            ),
          ),
        ],
      ),
    );
  }

  // 3-QADAM: ALOQA MA'LUMOTLARI (iOS style)
  Widget _buildStep3ContactInfo() {
    return KeyedSubtree(
      key: const ValueKey('step_3_contact'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '3-Qadam: Aloqa Ma’lumotlari',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.3, color: Color(0xFF1C1C1E)),
          ),
          const SizedBox(height: 3),
          const Text(
            'Telefon raqamingiz tizimga kirish uchun login sifatida xizmat qiladi.',
            style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
          ),
          const SizedBox(height: 18),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E5EA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Telefon raqamingiz *',
                    hintText: '+998 90 123-45-67',
                    prefixIcon: Icon(CupertinoIcons.phone, size: 20, color: Color(0xFF8E8E93)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const Divider(height: 1, indent: 48, color: Color(0xFFE5E5EA)),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Elektron pochta (ixtiyoriy)',
                    hintText: 'mutaxassis@talim.uz',
                    prefixIcon: Icon(CupertinoIcons.mail, size: 20, color: Color(0xFF8E8E93)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4-QADAM: XAVFSIZLIK VA PAROL (iOS style)
  Widget _buildStep4SecurityInfo(UserRole role) {
    return KeyedSubtree(
      key: const ValueKey('step_4_security'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '4-Qadam: Hisob Xavfsizligi va Tasdiqlash',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.3, color: Color(0xFF1C1C1E)),
          ),
          const SizedBox(height: 3),
          const Text(
            'Kamida 6 ta belgidan iborat ishonchli parol o‘rnating.',
            style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
          ),
          const SizedBox(height: 14),

          // RO'YXATDAN O'TISH XULOSA KARTASI (iOS style)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.checkmark_seal_fill, size: 18, color: role.color),
                    const SizedBox(width: 8),
                    Text(
                      'Ro‘yxatdan o‘tish xulosasi',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: role.color),
                    ),
                  ],
                ),
                const Divider(height: 16, color: Color(0xFFE5E5EA)),
                Text(
                  '• Mutaxassis: ${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E)),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Soha: ${role.label} (Qulflangan)',
                  style: TextStyle(fontSize: 12, color: role.color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• Hudud: Namangan viloyati, Chortoq tumani',
                  style: TextStyle(fontSize: 12, color: Color(0xFF3A3A3C)),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Maktab: ${_institutionCtrl.text.trim().isNotEmpty ? _institutionCtrl.text.trim() : "9-sonli inklyuziv ta’lim tayanch maktabi"}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF3A3A3C), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Login telefoni: ${_phoneCtrl.text.trim()}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // iOS Inset Grouped Section for Passwords
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E5EA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: _signUpPasswordCtrl,
                  obscureText: _signUpObscure,
                  decoration: InputDecoration(
                    labelText: 'Parol *',
                    hintText: 'Kamida 6 ta belgi',
                    prefixIcon: const Icon(CupertinoIcons.lock, size: 20, color: Color(0xFF8E8E93)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _signUpObscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                        size: 20,
                        color: const Color(0xFF8E8E93),
                      ),
                      onPressed: () => setState(() => _signUpObscure = !_signUpObscure),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 48, color: Color(0xFFE5E5EA)),
                TextFormField(
                  controller: _signUpConfirmPasswordCtrl,
                  obscureText: _signUpConfirmObscure,
                  decoration: InputDecoration(
                    labelText: 'Parolni tasdiqlang *',
                    hintText: 'Parolni qayta tering',
                    prefixIcon: const Icon(CupertinoIcons.lock_shield, size: 20, color: Color(0xFF8E8E93)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _signUpConfirmObscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                        size: 20,
                        color: const Color(0xFF8E8E93),
                      ),
                      onPressed: () => setState(() => _signUpConfirmObscure = !_signUpConfirmObscure),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // HARAKAT TUGMALARI (iOS style)
  Widget _buildStepActionButtons(AuthProvider auth, UserRole role) {
    final isLastStep = _signUpStep == 3;

    return Row(
      children: [
        if (_signUpStep > 0) ...[
          Expanded(
            flex: 2,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
              onPressed: auth.isLoading ? null : _previousStep,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.chevron_back, size: 16, color: Color(0xFF1C1C1E)),
                  SizedBox(width: 4),
                  Text('Orqaga', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1C1C1E))),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: 3,
          child: CupertinoButton.filled(
            padding: const EdgeInsets.symmetric(vertical: 14),
            borderRadius: BorderRadius.circular(12),
            onPressed: auth.isLoading
                ? null
                : (isLastStep ? _handleSignUp : _nextStep),
            child: auth.isLoading
                ? const CupertinoActivityIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLastStep ? 'Hisobni ochish' : 'Keyingisi',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isLastStep ? CupertinoIcons.checkmark_alt : CupertinoIcons.chevron_forward,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
