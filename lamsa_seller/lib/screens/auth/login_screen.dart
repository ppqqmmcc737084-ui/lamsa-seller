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
  final _walletNumberController = TextEditingController();
  final _deliveryFeeController = TextEditingController(); // ✅ تمت الإضافة

  String _walletName = 'الكريمي';
  final _walletOptions = ['الكريمي', 'شلن', 'جوالي', 'أخرى'];

  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _storeNameController.dispose();
    _phoneController.dispose();
    _walletNumberController.dispose();
    _deliveryFeeController.dispose(); // ✅ تنظيف المتحكم الجديد
    super.dispose();
  }

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
        'walletName': _walletNumberController.text.trim().isEmpty ? null : _walletName,
        'walletNumber': _walletNumberController.text.trim().isEmpty ? null : _walletNumberController.text.trim(),
        'deliveryFee': double.tryParse(_deliveryFeeController.text.trim()) ?? 0, // ✅ تمت الإضافة هنا
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
                    TextField(controller: _storeNameController, decoration: const InputDecoration(hintText: 'اسم المتجر')),
                    const SizedBox(height: 12),
                    TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'رقم جوال المتجر')),
                    const SizedBox(height: 12),
                    const Align(alignment: Alignment.centerRight, child: Text('محفظة إلكترونية (اختياري)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _walletName,
                      decoration: const InputDecoration(),
                      items: _walletOptions.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                      onChanged: (value) => setState(() => _walletName = value!),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _walletNumberController, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'رقم المحفظة (اتركه فاضي إذا ما تستخدمها)')),
                    const SizedBox(height: 12),
                    // ✅ تمت إضافة حقل رسوم التوصيل هنا
                    TextField(
                      controller: _deliveryFeeController, 
                      keyboardType: TextInputType.number, 
                      decoration: const InputDecoration(hintText: 'رسوم التوصيل (ر.ي) — اتركه فاضي إذا مجاني')
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'البريد الإلكتروني')),
                  const SizedBox(height: 12),
                  TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(hintText: 'كلمة المرور')),
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