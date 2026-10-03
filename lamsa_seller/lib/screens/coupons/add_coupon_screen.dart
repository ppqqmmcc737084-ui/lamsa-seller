import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../services/seller_coupon_service.dart';
import '../../services/seller_product_service.dart';

class AddCouponScreen extends StatefulWidget {
  const AddCouponScreen({super.key});

  @override
  State<AddCouponScreen> createState() => _AddCouponScreenState();
}

class _AddCouponScreenState extends State<AddCouponScreen> {
  final _codeController = TextEditingController();
  final _percentController = TextEditingController();
  String? _selectedProductId;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    final percent = int.tryParse(_percentController.text.trim());
    if (code.isEmpty || percent == null || percent <= 0 || percent > 90) {
      setState(() => _error = 'اكتب كود صحيح ونسبة خصم بين 1 و90');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SellerCouponService().addCoupon(code: code, discountPercent: percent, productId: _selectedProductId);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('كود خصم جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: 'الكود (مثل: SAVE20)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _percentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'نسبة الخصم % (مثال: 20)'),
            ),
            const SizedBox(height: 20),
            const Text('يطبّق على منتج معيّن (اختياري)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: SellerProductService().streamMyProducts(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                return DropdownButtonFormField<String>(
                  initialValue: _selectedProductId,
                  decoration: const InputDecoration(hintText: 'كل المنتجات'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('كل المنتجات')),
                    ...docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(value: doc.id, child: Text(data['name'] ?? ''));
                    }),
                  ],
                  onChanged: (value) => setState(() => _selectedProductId = value),
                );
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('إنشاء الكود'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}