import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../services/seller_coupon_service.dart';
import 'add_coupon_screen.dart';

class MyCouponsScreen extends StatelessWidget {
  const MyCouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أكواد الخصم')),
      body: StreamBuilder<QuerySnapshot>(
        stream: SellerCouponService().streamMyCoupons(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('ما سويت أي كود بعد', style: TextStyle(color: AppColors.grey)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final active = data['active'] ?? true;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.medium)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['code'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 1)),
                          Text('خصم ${data['discountPercent']}%', style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                        ],
                      ),
                    ),
                    Switch(
                      value: active,
                      onChanged: (value) => SellerCouponService().toggleActive(docs[index].id, value),
                      activeThumbColor: AppColors.primary,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.grey),
                      onPressed: () => SellerCouponService().deleteCoupon(docs[index].id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCouponScreen())),
        icon: const Icon(Icons.local_offer_outlined),
        label: const Text('كود جديد'),
      ),
    );
  }
}