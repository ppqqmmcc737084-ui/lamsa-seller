import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../dashboard/main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_isLogin) {
      if (_storeNameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
        setState(() => _error = 'اسم المتجر ورقم الجوال مطلوبين');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = AuthService();

    if (_isLogin) {
      final error = await auth.signIn(email, password);
      if (!mounted) return;
      setState(() => _loading = false);
      if (error != null) {
        setState(() => _error = error);
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
      }
      return;
    }

    final error = await auth.signUp(email, password);
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _error = error;
        _loading = false;
      });
      return;
    }

    try {
      final uid = auth.currentUser!.uid;
      await FirebaseFirestore.instance.collection('sellers').doc(uid).set({
        'storeName': _storeNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
    } catch (e) {
      setState(() => _error = 'تم إنشاء الحساب لكن حدث خطأ بحفظ بيانات المتجر: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                  const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 56),
                  const SizedBox(height: 12),
                  const Text('لمسة للتجار', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.dark)),
                  const SizedBox(height: 6),
                  Text(_isLogin ? 'سجّل دخولك لإدارة متجرك' : 'أنشئ حساب متجرك الجديد',
                      style: const TextStyle(fontSize: 13, color: AppColors.grey)),
                  const SizedBox(height: 28),
                  if (!_isLogin) ...[
                    TextField(
                      controller: _storeNameController,
                      decoration: const InputDecoration(hintText: 'اسم المتجر'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: 'رقم جوال المتجر'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'البريد الإلكتروني'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'كلمة المرور'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(_isLogin ? 'دخول' : 'إنشاء حساب المتجر'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
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