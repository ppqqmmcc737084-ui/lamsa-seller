import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';

class EditStoreScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const EditStoreScreen({super.key, required this.data});

  @override
  State<EditStoreScreen> createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends State<EditStoreScreen> {
  late final _storeNameController = TextEditingController(text: widget.data['storeName'] ?? '');
  late final _phoneController = TextEditingController(text: widget.data['phone'] ?? '');
  late final _walletNumberController = TextEditingController(text: widget.data['walletNumber'] ?? '');
  
  // ✅ 1. إضافة متحكم رسوم التوصيل
  late final _deliveryFeeController = TextEditingController(text: '${widget.data['deliveryFee'] ?? 0}');
  
  late String _walletName = widget.data['walletName'] ?? 'الكريمي';
  final _walletOptions = ['الكريمي', 'شلن', 'جوالي', 'أخرى'];
  bool _loading = false;

  @override
  void dispose() {
    _storeNameController.dispose();
    _phoneController.dispose();
    _walletNumberController.dispose();
    _deliveryFeeController.dispose(); // ✅ تنظيف المتحكم الجديد لمنع تسرب الذاكرة
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    await FirebaseFirestore.instance.collection('sellers').doc(uid).update({
      'storeName': _storeNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'walletName': _walletNumberController.text.trim().isEmpty ? null : _walletName,
      'walletNumber': _walletNumberController.text.trim().isEmpty ? null : _walletNumberController.text.trim(),
      'deliveryFee': double.tryParse(_deliveryFeeController.text.trim()) ?? 0, // ✅ 3. تحديث الحقل في قاعدة البيانات
    });
    
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل بيانات المتجر')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _storeNameController, decoration: const InputDecoration(hintText: 'اسم المتجر')),
            const SizedBox(height: 12),
            TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'رقم الجوال')),
            
            // ✅ 2. إضافة حقل رسوم التوصيل في الواجهة
            const SizedBox(height: 12),
            TextField(
              controller: _deliveryFeeController, 
              keyboardType: TextInputType.number, 
              decoration: const InputDecoration(hintText: 'رسوم التوصيل (ر.ي)'),
            ),
            
            const SizedBox(height: 20),
            const Text('محفظة إلكترونية', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _walletName,
              items: _walletOptions.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
              onChanged: (value) => setState(() => _walletName = value!),
            ),
            const SizedBox(height: 12),
            TextField(controller: _walletNumberController, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'رقم المحفظة')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('حفظ التعديلات'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}