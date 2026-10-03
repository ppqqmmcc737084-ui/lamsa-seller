import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/platform_info.dart';
import '../../services/ad_request_service.dart';
import '../../services/seller_product_service.dart';

class RequestAdScreen extends StatefulWidget {
  const RequestAdScreen({super.key});

  @override
  State<RequestAdScreen> createState() => _RequestAdScreenState();
}

class _RequestAdScreenState extends State<RequestAdScreen> {
  String? _selectedProductId;
  Map<String, dynamic>? _selectedProductData;
  int _duration = 3;
  final _refController = TextEditingController();
  bool _loading = false;
  String? _error;

  int get _price {
    switch (_duration) {
      case 7:
        return PlatformInfo.price7Days;
      case 14:
        return PlatformInfo.price14Days;
      default:
        return PlatformInfo.price3Days;
    }
  }

  Future<void> _submit() async {
    if (_selectedProductId == null || _refController.text.trim().isEmpty) {
      setState(() => _error = 'اختر منتج وأدخل رقم مرجع التحويل');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AdRequestService().requestAd(
        productId: _selectedProductId!,
        productName: _selectedProductData?['name'] ?? '',
        productImage: _selectedProductData?['imageUrl'] ?? '',
        durationDays: _duration,
        price: _price,
        transferReference: _refController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب الإعلان، بانتظار المراجعة')),
      );
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
      appBar: AppBar(title: const Text('طلب إعلان مدفوع')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اختر المنتج', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: SellerProductService().streamMyProducts(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                return DropdownButtonFormField<String>(
                  initialValue: _selectedProductId,
                  decoration: const InputDecoration(hintText: 'اختر منتج'),
                  items: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(value: doc.id, child: Text(data['name'] ?? ''));
                  }).toList(),
                  onChanged: (value) {
                    final doc = docs.firstWhere((d) => d.id == value);
                    setState(() {
                      _selectedProductId = value;
                      _selectedProductData = doc.data() as Map<String, dynamic>;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            const Text('مدة الإعلان', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [3, 7, 14].map((d) {
                final selected = _duration == d;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _duration = d),
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                        border: Border.all(color: selected ? AppColors.primary : AppColors.lightGrey),
                      ),
                      child: Column(
                        children: [
                          Text('$d أيام', style: TextStyle(color: selected ? Colors.white : AppColors.dark, fontWeight: FontWeight.w700)),
                          Text(
                            '${d == 7 ? PlatformInfo.price7Days : d == 14 ? PlatformInfo.price14Days : PlatformInfo.price3Days} ر.ي',
                            style: TextStyle(color: selected ? Colors.white70 : AppColors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(AppRadius.medium)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('حوّل المبلغ على محفظة المنصة:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('${PlatformInfo.walletName} — ${PlatformInfo.walletNumber}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('المبلغ المطلوب: $_price ر.ي', style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                  const SizedBox(height: 10),
                  TextField(controller: _refController, decoration: const InputDecoration(hintText: 'رقم مرجع التحويل')),
                ],
              ),
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
                    : const Text('إرسال طلب الإعلان'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}