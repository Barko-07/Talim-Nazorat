import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_api.dart';
import '../main_navigation_screen.dart';

// ============================================================================
// Server rejimidagi kirish bosqichlari: emailga kelgan kod, Authenticator kodi,
// Authenticator'ni sozlash, vaqtinchalik parolni almashtirish, ro'yxatdan
// o'tish kodi va parolni tiklash. Barcha tekshiruvlarni server bajaradi.
// ============================================================================

/// Parol talablari — serverdagi qoidalar bilan bir xil (passwords.py).
class PasswordRules {
  static const minLength = 12;

  static bool longEnough(String p) => p.length >= minLength;

  static int classes(String p) => [
    RegExp(r'[a-z]').hasMatch(p),
    RegExp(r'[A-Z]').hasMatch(p),
    RegExp(r'[0-9]').hasMatch(p),
    RegExp(r'[^A-Za-z0-9]').hasMatch(p),
  ].where((ok) => ok).length;

  static String? problem(String p) {
    if (!longEnough(p)) return 'Parol kamida $minLength ta belgidan iborat bo‘lsin.';
    if (classes(p) < 3) {
      return 'Kichik va katta harf, raqam va belgilardan kamida uchtasini ishlating.';
    }
    return null;
  }
}

/// Kirish tugagach — asosiy sahifaga (orqaga qaytib bo'lmaydi).
void _openApp(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    (route) => false,
  );
}

void _snack(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: error ? AppColors.error : AppColors.success,
    ),
  );
}

// ---------------------------------------------------------------- shared UI

/// Kirish sahifasi uslubidagi ekran: logo, sarlavha, karta.
class _AuthShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;

  const _AuthShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AmbientMeshBackground(
      intense: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading:
              onBack == null
                  ? null
                  : IconButton(
                    tooltip: 'Orqaga',
                    icon: const Icon(LucideIcons.arrowLeft),
                    onPressed: onBack,
                  ),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandLogo(height: 64)),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(icon, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 22),
                          child,
                        ],
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
}

/// 6 xonali kod maydoni. 6-raqam kiritilishi bilan [onCompleted] chaqiriladi.
class CodeField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onCompleted;
  final bool enabled;

  const CodeField({
    super.key,
    required this.controller,
    this.onCompleted,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: true,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
        fontSize: 28,
        letterSpacing: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      decoration: const InputDecoration(
        counterText: '',
        hintText: '••••••',
        hintStyle: TextStyle(letterSpacing: 12, color: AppColors.textMuted),
      ),
      onChanged: (v) {
        if (v.length == 6) onCompleted?.call(v);
      },
    );
  }
}

/// "Kodni qayta yuborish" — server ruxsat bergunga qadar teskari sanoq ko'rsatadi.
class ResendCodeButton extends StatefulWidget {
  final int initialWait;

  /// Natija: `success`, `message`, `extra` (keyingi kutish soniyalari), `retryAfter`.
  final Future<Map<String, dynamic>> Function() onResend;

  const ResendCodeButton({
    super.key,
    required this.initialWait,
    required this.onResend,
  });

  @override
  State<ResendCodeButton> createState() => _ResendCodeButtonState();
}

class _ResendCodeButtonState extends State<ResendCodeButton> {
  Timer? _timer;
  int _left = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _start(widget.initialWait);
  }

  void _start(int seconds) {
    _timer?.cancel();
    setState(() => _left = seconds);
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _left--);
      if (_left <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() => _busy = true);
    final res = await widget.onResend();
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['success'] == true) {
      _snack(context, res['message'] as String? ?? 'Yangi kod yuborildi');
      _start((res['extra'] as int?) ?? 60);
    } else {
      _snack(context, res['message'] as String, error: true);
      final wait = res['retryAfter'] as int?;
      if (wait != null) _start(wait);
    }
  }

  @override
  Widget build(BuildContext context) {
    final waiting = _left > 0;
    return Center(
      child: TextButton.icon(
        onPressed: waiting || _busy ? null : _resend,
        icon: const Icon(LucideIcons.rotateCw, size: 16),
        label: Text(
          waiting
              ? 'Kodni qayta yuborish ($_left soniya)'
              : 'Kod kelmadimi? Qayta yuborish',
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        child:
            busy
                ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
                : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String? message;
  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        message!,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.error, fontSize: 13),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;

  const _PasswordField({
    required this.controller,
    required this.label,
    this.onChanged,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(LucideIcons.lock, size: 18),
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Parolni ko‘rsatish' : 'Parolni yashirish',
          icon: Icon(_obscure ? LucideIcons.eye : LucideIcons.eyeOff, size: 18),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final String text;
  final bool ok;
  const _RuleRow(this.text, this.ok);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            ok ? LucideIcons.circleCheck : LucideIcons.circle,
            size: 15,
            color: ok ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                color: ok ? AppColors.success : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Yangi parol + takrorlash, qoidalar ro'yxati bilan.
class _NewPasswordFields extends StatefulWidget {
  final TextEditingController password;
  final TextEditingController confirm;

  const _NewPasswordFields({required this.password, required this.confirm});

  @override
  State<_NewPasswordFields> createState() => _NewPasswordFieldsState();
}

class _NewPasswordFieldsState extends State<_NewPasswordFields> {
  @override
  Widget build(BuildContext context) {
    final p = widget.password.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PasswordField(
          controller: widget.password,
          label: 'Yangi parol',
          onChanged: (_) => setState(() {}),
        ),
        _RuleRow(
          'Kamida ${PasswordRules.minLength} ta belgi',
          PasswordRules.longEnough(p),
        ),
        _RuleRow(
          'Katta va kichik harf, raqam, belgi — kamida uchtasi',
          PasswordRules.classes(p) >= 3,
        ),
        const SizedBox(height: 12),
        _PasswordField(controller: widget.confirm, label: 'Yangi parolni takrorlang'),
      ],
    );
  }
}

String? _checkNewPassword(String password, String confirm) {
  final problem = PasswordRules.problem(password);
  if (problem != null) return problem;
  if (password != confirm) return 'Kiritilgan parollar bir-biriga mos kelmadi.';
  return null;
}

// ---------------------------------------------------------------- login steps

/// Parol to'g'ri bo'lgandan keyingi bosqichlar. Har bir muvaffaqiyatdan keyin
/// provider keyingi bosqichni aytadi; kirish tugagach ilova ochiladi.
class SecondFactorScreen extends StatelessWidget {
  const SecondFactorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) _openApp(context);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    Future<void> back() async {
      await auth.cancelPendingLogin();
      if (context.mounted) Navigator.of(context).pop();
    }

    switch (auth.pendingStep) {
      case AuthStep.emailCode:
        return _EmailCodeStep(onBack: back);
      case AuthStep.totp:
        return _TotpStep(onBack: back);
      case AuthStep.totpSetup:
        return _TotpSetupStep(onBack: back);
      case AuthStep.passwordChange:
        return _PasswordChangeStep(onBack: back);
      case AuthStep.ok:
      case null:
        // Sessiya tugadi yoki bekor qilindi — kirish sahifasiga qaytamiz.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        return const Scaffold(body: SizedBox.shrink());
    }
  }
}

String _maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 1) return email;
  return '${email.substring(0, 2)}***${email.substring(at)}';
}

class _EmailCodeStep extends StatefulWidget {
  final VoidCallback onBack;
  const _EmailCodeStep({required this.onBack});

  @override
  State<_EmailCodeStep> createState() => _EmailCodeStepState();
}

class _EmailCodeStepState extends State<_EmailCodeStep> {
  final _code = TextEditingController();
  bool _remember = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_code.text.length != 6) {
      setState(() => _error = 'Emailga kelgan 6 xonali kodni kiriting.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await context.read<AuthProvider>().verifyEmailCode(
      _code.text,
      remember: _remember,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['success'] != true) {
      setState(() => _error = res['message'] as String);
      _code.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final email = auth.pendingUser?.email ?? '';
    return _AuthShell(
      icon: LucideIcons.mailCheck,
      title: 'Emailga kod yuborildi',
      subtitle:
          '${_maskEmail(email)} manziliga 6 xonali kirish kodi yuborildi. '
          'Kod 10 daqiqa amal qiladi. Xat ko‘rinmasa, “Spam” papkasini ham tekshiring.',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CodeField(controller: _code, onCompleted: (_) => _submit()),
          if (auth.canRememberDevice) ...[
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _remember,
              onChanged: (v) => setState(() => _remember = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Bu qurilmani 30 kun eslab qol'),
              subtitle: const Text(
                'Faqat shaxsiy qurilmangizda belgilang. Umumiy kompyuterda belgilamang.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
          _ErrorText(_error),
          const SizedBox(height: 16),
          _PrimaryButton(label: 'Tasdiqlash', busy: _busy, onPressed: _submit),
          const SizedBox(height: 8),
          ResendCodeButton(
            initialWait: auth.resendAfter,
            onResend: auth.resendEmailCode,
          ),
        ],
      ),
    );
  }
}

class _TotpStep extends StatefulWidget {
  final VoidCallback onBack;
  const _TotpStep({required this.onBack});

  @override
  State<_TotpStep> createState() => _TotpStepState();
}

class _TotpStepState extends State<_TotpStep> {
  final _code = TextEditingController();
  final _recovery = TextEditingController();
  bool _useRecovery = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _recovery.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _busy = true;
      _error = null;
    });
    final res =
        _useRecovery
            ? await auth.useRecoveryCode(_recovery.text.trim())
            : await auth.verifyTotp(_code.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['success'] != true) {
      setState(() => _error = res['message'] as String);
      _code.clear();
      return;
    }
    if (_useRecovery) {
      _snack(
        context,
        'Zaxira kod qabul qilindi. Qolgan zaxira kodlar: ${res['extra']} ta.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthShell(
      icon: LucideIcons.smartphone,
      title: 'Ikki bosqichli tasdiqlash',
      subtitle:
          _useRecovery
              ? 'Qog‘ozga yozib olgan zaxira kodlaringizdan birini kiriting (masalan: K7QM-2XPA). Har bir kod bir marta ishlaydi.'
              : 'Telefoningizdagi Google Authenticator ilovasini oching va “Individ” qatoridagi 6 xonali kodni kiriting.',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_useRecovery)
            TextField(
              controller: _recovery,
              autofocus: true,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 22,
                letterSpacing: 4,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(hintText: 'XXXX-XXXX'),
              onSubmitted: (_) => _submit(),
            )
          else
            CodeField(controller: _code, onCompleted: (_) => _submit()),
          _ErrorText(_error),
          const SizedBox(height: 16),
          _PrimaryButton(label: 'Tasdiqlash', busy: _busy, onPressed: _submit),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed:
                  () => setState(() {
                    _useRecovery = !_useRecovery;
                    _error = null;
                  }),
              child: Text(
                _useRecovery
                    ? 'Authenticator kodi bilan kirish'
                    : 'Telefon yo‘qmi? Zaxira kod bilan kirish',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotpSetupStep extends StatefulWidget {
  final VoidCallback onBack;
  const _TotpSetupStep({required this.onBack});

  @override
  State<_TotpSetupStep> createState() => _TotpSetupStepState();
}

class _TotpSetupStepState extends State<_TotpSetupStep> {
  final _password = TextEditingController();
  final _code = TextEditingController();
  TotpSetup? _setup;
  List<String> _recoveryCodes = const [];
  bool _saved = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await context.read<AuthProvider>().startTotpSetup(
      _password.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (res['success'] == true) {
        _setup = res['extra'] as TotpSetup;
        _password.clear();
      } else {
        _error = res['message'] as String;
      }
    });
  }

  Future<void> _enable() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await context.read<AuthProvider>().enableTotp(_code.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (res['success'] == true) {
        _recoveryCodes = (res['extra'] as List).cast<String>();
      } else {
        _error = res['message'] as String;
        _code.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_recoveryCodes.isNotEmpty) return _buildRecoveryCodes();
    if (_setup != null) return _buildScan();
    return _AuthShell(
      icon: LucideIcons.shieldCheck,
      title: 'Authenticator’ni sozlang',
      subtitle:
          'Administrator hisoblari uchun Google Authenticator majburiy. '
          'Avval telefoningizga Google Authenticator ilovasini o‘rnating, keyin parolingizni qayta kiriting.',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PasswordField(controller: _password, label: 'Parolingiz'),
          _ErrorText(_error),
          const SizedBox(height: 16),
          _PrimaryButton(label: 'Davom etish', busy: _busy, onPressed: _start),
        ],
      ),
    );
  }

  Widget _buildScan() {
    final setup = _setup!;
    return _AuthShell(
      icon: LucideIcons.qrCode,
      title: 'QR-kodni skanerlang',
      subtitle:
          'Google Authenticator’da “+” → “QR-kodni skanerlash” ni bosing va shu kodni skanerlang. '
          'Keyin ilovada chiqqan 6 xonali kodni pastga kiriting.',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: QrImageView(data: setup.otpauthUri, size: 200),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Skanerlab bo‘lmasa, kalitni qo‘lda kiriting:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          SelectableText(
            setup.secret.replaceAllMapped(
              RegExp(r'.{4}'),
              (m) => '${m.group(0)} ',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 18),
          CodeField(controller: _code, onCompleted: (_) => _enable()),
          _ErrorText(_error),
          const SizedBox(height: 16),
          _PrimaryButton(label: 'Yoqish', busy: _busy, onPressed: _enable),
        ],
      ),
    );
  }

  Widget _buildRecoveryCodes() {
    return _AuthShell(
      icon: LucideIcons.keyRound,
      title: 'Zaxira kodlarni saqlang',
      subtitle:
          'Telefoningiz yo‘qolsa, shu kodlar bilan kirasiz. Har biri bir marta ishlaydi. '
          'Ularni qog‘ozga yozib, xavfsiz joyda saqlang — bu kodlar boshqa ko‘rsatilmaydi.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 18,
              runSpacing: 8,
              children: [
                for (final c in _recoveryCodes)
                  SelectableText(
                    c,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: _recoveryCodes.join('\n')),
              );
              _snack(context, 'Zaxira kodlar nusxalandi');
            },
            icon: const Icon(LucideIcons.copy, size: 16),
            label: const Text('Nusxa olish'),
          ),
          CheckboxListTile(
            value: _saved,
            onChanged: (v) => setState(() => _saved = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text('Kodlarni xavfsiz joyga saqlab oldim'),
          ),
          const SizedBox(height: 8),
          _PrimaryButton(
            label: 'Davom etish',
            onPressed:
                _saved
                    ? () => context.read<AuthProvider>().finishTotpSetup()
                    : null,
          ),
        ],
      ),
    );
  }
}

class _PasswordChangeStep extends StatefulWidget {
  final VoidCallback onBack;
  const _PasswordChangeStep({required this.onBack});

  @override
  State<_PasswordChangeStep> createState() => _PasswordChangeStepState();
}

class _PasswordChangeStepState extends State<_PasswordChangeStep> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final problem = _checkNewPassword(_new.text, _confirm.text);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await context.read<AuthProvider>().changeTemporaryPassword(
      _current.text,
      _new.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (res['success'] != true) _error = res['message'] as String;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AuthShell(
      icon: LucideIcons.keyRound,
      title: 'Yangi parol o‘rnating',
      subtitle:
          'Sizga vaqtinchalik parol berilgan edi. Davom etish uchun faqat o‘zingiz biladigan yangi parol o‘rnating.',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PasswordField(controller: _current, label: 'Vaqtinchalik parol'),
          const SizedBox(height: 12),
          _NewPasswordFields(password: _new, confirm: _confirm),
          _ErrorText(_error),
          const SizedBox(height: 16),
          _PrimaryButton(label: 'Saqlash', busy: _busy, onPressed: _submit),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- sign-up code

class RegistrationCodeScreen extends StatefulWidget {
  final String registrationId;
  final String email;
  final int resendAfter;

  const RegistrationCodeScreen({
    super.key,
    required this.registrationId,
    required this.email,
    required this.resendAfter,
  });

  @override
  State<RegistrationCodeScreen> createState() => _RegistrationCodeScreenState();
}

class _RegistrationCodeScreenState extends State<RegistrationCodeScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _done;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_code.text.length != 6) {
      setState(() => _error = 'Emailga kelgan 6 xonali kodni kiriting.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await context.read<AuthProvider>().verifyRegistration(
      widget.registrationId,
      _code.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (res['success'] == true) {
        _done = res['message'] as String;
      } else {
        _error = res['message'] as String;
        _code.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_done != null) {
      return _AuthShell(
        icon: LucideIcons.badgeCheck,
        title: 'Email tasdiqlandi',
        subtitle:
            '$_done. Tasdiqlangach emailingizga xabar keladi va shu email hamda parolingiz bilan kirasiz.',
        child: _PrimaryButton(
          label: 'Kirish sahifasiga qaytish',
          onPressed: () => Navigator.of(context).pop(),
        ),
      );
    }
    return _AuthShell(
      icon: LucideIcons.mailCheck,
      title: 'Emailingizni tasdiqlang',
      subtitle:
          '${_maskEmail(widget.email)} manziliga 6 xonali tasdiqlash kodi yuborildi. '
          'Kod 10 daqiqa amal qiladi. Xat ko‘rinmasa, “Spam” papkasini ham tekshiring.',
      onBack: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CodeField(controller: _code, onCompleted: (_) => _submit()),
          _ErrorText(_error),
          const SizedBox(height: 16),
          _PrimaryButton(label: 'Tasdiqlash', busy: _busy, onPressed: _submit),
          const SizedBox(height: 8),
          ResendCodeButton(
            initialWait: widget.resendAfter,
            onResend:
                () => context.read<AuthProvider>().resendRegistrationCode(
                  widget.registrationId,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- forgot password

class PasswordResetScreen extends StatefulWidget {
  final String initialEmail;
  const PasswordResetScreen({super.key, this.initialEmail = ''});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  late final _email = TextEditingController(
    text: widget.initialEmail.contains('@') ? widget.initialEmail : '',
  );
  final _code = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await context.read<AuthProvider>().requestPasswordReset(
      _email.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (res['success'] == true) {
        _codeSent = true;
      } else {
        _error = res['message'] as String;
      }
    });
  }

  Future<void> _confirmReset() async {
    if (_code.text.length != 6) {
      setState(() => _error = 'Emailga kelgan 6 xonali kodni kiriting.');
      return;
    }
    final problem = _checkNewPassword(_new.text, _confirm.text);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await context.read<AuthProvider>().confirmPasswordReset(
      _email.text,
      _code.text,
      _new.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['success'] == true) {
      _snack(context, res['message'] as String);
      Navigator.of(context).pop();
    } else {
      setState(() => _error = res['message'] as String);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_codeSent) {
      return _AuthShell(
        icon: LucideIcons.keyRound,
        title: 'Parolni tiklash',
        subtitle:
            'Hisobingiz emailini kiriting. Unga 6 xonali tasdiqlash kodi yuboriladi.',
        onBack: () => Navigator.of(context).pop(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _email,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Elektron pochta',
                prefixIcon: Icon(LucideIcons.mail, size: 18),
              ),
              onSubmitted: (_) => _request(),
            ),
            _ErrorText(_error),
            const SizedBox(height: 16),
            _PrimaryButton(label: 'Kod yuborish', busy: _busy, onPressed: _request),
          ],
        ),
      );
    }
    return _AuthShell(
      icon: LucideIcons.mailCheck,
      title: 'Kodni kiriting',
      subtitle:
          'Agar ${_email.text.trim()} bilan hisob mavjud bo‘lsa, unga 6 xonali kod yuborildi. '
          'Kod 10 daqiqa amal qiladi.',
      onBack: () => setState(() => _codeSent = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CodeField(controller: _code),
          const SizedBox(height: 14),
          _NewPasswordFields(password: _new, confirm: _confirm),
          _ErrorText(_error),
          const SizedBox(height: 16),
          _PrimaryButton(
            label: 'Parolni tiklash',
            busy: _busy,
            onPressed: _confirmReset,
          ),
          const SizedBox(height: 8),
          ResendCodeButton(
            initialWait: 60,
            onResend: () async {
              final res = await context
                  .read<AuthProvider>()
                  .requestPasswordReset(_email.text);
              return {...res, 'extra': 60};
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- change password (settings)

/// Profil sozlamalaridan parolni o'zgartirish: joriy parol + emailga kelgan kod.
Future<void> showServerPasswordChange(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const _ChangePasswordScreen()));
}

class _ChangePasswordScreen extends StatefulWidget {
  const _ChangePasswordScreen();

  @override
  State<_ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<_ChangePasswordScreen> {
  final _current = TextEditingController();
  final _code = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _code.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await context.read<AuthProvider>().requestPasswordChangeCode();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (res['success'] == true) {
        _codeSent = true;
      } else {
        _error = res['message'] as String;
      }
    });
  }

  Future<void> _save() async {
    final problem = _checkNewPassword(_new.text, _confirm.text);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await context.read<AuthProvider>().changePassword(
      _current.text,
      _new.text,
      code: _code.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['success'] == true) {
      _snack(context, res['message'] as String);
      Navigator.of(context).pop();
    } else {
      setState(() => _error = res['message'] as String);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthShell(
      icon: LucideIcons.keyRound,
      title: 'Parolni o‘zgartirish',
      subtitle:
          _codeSent
              ? 'Emailingizga kelgan kodni, joriy va yangi parolni kiriting. '
                  'Parol o‘zgargach boshqa qurilmalardagi seanslar yopiladi.'
              : 'Xavfsizlik uchun avval emailingizga tasdiqlash kodi yuboriladi.',
      onBack: () => Navigator.of(context).pop(),
      child:
          !_codeSent
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ErrorText(_error),
                  const SizedBox(height: 8),
                  _PrimaryButton(
                    label: 'Emailga kod yuborish',
                    busy: _busy,
                    onPressed: _sendCode,
                  ),
                ],
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CodeField(controller: _code),
                  const SizedBox(height: 14),
                  _PasswordField(controller: _current, label: 'Joriy parol'),
                  const SizedBox(height: 12),
                  _NewPasswordFields(password: _new, confirm: _confirm),
                  _ErrorText(_error),
                  const SizedBox(height: 16),
                  _PrimaryButton(label: 'Saqlash', busy: _busy, onPressed: _save),
                  const SizedBox(height: 8),
                  ResendCodeButton(
                    initialWait: 60,
                    onResend: () async {
                      final res =
                          await context
                              .read<AuthProvider>()
                              .requestPasswordChangeCode();
                      return {...res, 'extra': 60};
                    },
                  ),
                ],
              ),
    );
  }
}
