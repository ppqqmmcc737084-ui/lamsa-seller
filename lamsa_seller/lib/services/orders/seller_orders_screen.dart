import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../services/seller_order_service.dart';

class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: SellerOrderService().streamMyOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.grey),
                SizedBox(height: 12),
                Text('ما وصلك أي طلب بعد', style: TextStyle(color: AppColors.grey)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final orderId = docs[index].id;
            final status = data['status'] ?? 'pendingApproval';
            final isPending = status == 'pendingApproval';

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(data['productImage'] ?? '', width: 50, height: 50, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: AppColors.lightGrey)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['productName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            Text('العميل: ${data['customerName'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppColors.grey)),
                            Text('${data['customerPhone'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppColors.grey)),
                          ],
                        ),
                      ),
                      Text('${data['totalAmount'] ?? 0} ر.س', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ],
                  ),
                  if (isPending) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => SellerOrderService().updateStatus(orderId, 'rejected'),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, minimumSize: const Size.fromHeight(38)),
                            child: const Text('رفض'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => SellerOrderService().updateStatus(orderId, 'confirmed'),
                            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(38)),
                            child: const Text('موافقة'),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (status == 'confirmed' ? AppColors.success : AppColors.primary).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(status == 'confirmed' ? 'تمت الموافقة' : 'مرفوض',
                          style: TextStyle(fontSize: 11, color: status == 'confirmed' ? AppColors.success : AppColors.primary, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}