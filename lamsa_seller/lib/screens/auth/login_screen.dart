import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

/// شاشة الدخول وإنشاء الحساب. بعد النجاح تنتقل البوابة تلقائياً للشاشة المناسبة.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  bool _hidePassword = true;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _strongEnough(String p) =>
      p.length >= 8 && RegExp(r'[A-Za-z]').hasMatch(p) && RegExp(r'\d').hasMatch(p);

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'أدخل البريد وكلمة المرور';
        _info = null;
      });
      return;
    }
    if (!_isLogin) {
      if (!_strongEnough(password)) {
        setState(() {
          _error = 'كلمة المرور لازم 8 أحرف على الأقل وفيها حروف وأرقام';
          _info = null;
        });
        return;
      }
      if (password != _confirmController.text) {
        setState(() {
          _error = 'كلمتا المرور غير متطابقتين';
          _info = null;
        });
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });

    final auth = AuthService();
    final error = _isLogin ? await auth.signIn(email, password) : await auth.signUp(email, password);
    if (error == null && !_isLogin) await auth.sendVerificationEmail();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  Future<void> _forgot() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _error = 'اكتب بريدك أولاً ثم اضغط نسيت كلمة المرور';
        _info = null;
      });
      return;
    }
    final error = await AuthService().resetPassword(email);
    if (!mounted) return;
    setState(() {
      _error = error;
      _info = error == null ? 'أرسلنا رابط إعادة تعيين كلمة المرور إلى بريدك' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo/logo_transparent_1024.png',
                    width: 120,
                    height: 120,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 56),
                  ),
                  const SizedBox(height: 12),
                  const Text('لمسة للتجار',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.dark)),
                  const SizedBox(height: 6),
                  Text(
                    _isLogin ? 'سجّل دخولك لإدارة متجرك' : 'أنشئ حسابك ثم أكمل بيانات متجرك على مراحل',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.grey),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'البريد الإلكتروني'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    decoration: InputDecoration(
                      hintText: 'كلمة المرور',
                      suffixIcon: IconButton(
                        icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _hidePassword = !_hidePassword),
                      ),
                    ),
                  ),
                  if (!_isLogin) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmController,
                      obscureText: _hidePassword,
                      decoration: const InputDecoration(hintText: 'تأكيد كلمة المرور'),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                  ],
                  if (_info != null) ...[
                    const SizedBox(height: 10),
                    Text(_info!, style: const TextStyle(color: AppColors.success, fontSize: 12)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(_isLogin ? 'دخول' : 'إنشاء الحساب'),
                    ),
                  ),
                  if (_isLogin)
                    TextButton(onPressed: _loading ? null : _forgot, child: const Text('نسيت كلمة المرور؟')),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                              _isLogin = !_isLogin;
                              _error = null;
                              _info = null;
                            }),
                    child: Text(_isLogin ? 'ما عندك متجر؟ سجّل الآن' : 'عندك حساب؟ سجّل دخولك'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
