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
            final isCancelled = status == 'cancelledByCustomer'; // ✅ تمت إضافة المتغير

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
                        child: Image.network(
                          data['productImage'] ?? '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: AppColors.lightGrey),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['productName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            Text('العميل: ${data['customerName'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppColors.grey)),
                            Text('${data['customerPhone'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppColors.grey)),
                            if (data['transferReference'] != null && (data['transferReference'] as String).isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                  '⚠️ تحقق من التحويل — مرجع: ${data['transferReference']}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.dark),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text('${data['totalAmount'] ?? 0} ر.س', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // ✅ منطق تحديث الحالات مع تمرير البيانات الجديدة
                  if (status == 'pendingApproval') ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => SellerOrderService().updateStatus(
                              orderId, 'rejected',
                              customerId: data['customerId'],
                              productName: data['productName'],
                            ),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, minimumSize: const Size.fromHeight(38)),
                            child: const Text('رفض'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => SellerOrderService().updateStatus(
                              orderId, 'confirmed',
                              customerId: data['customerId'],
                              productName: data['productName'],
                              productId: data['productId'],
                              quantity: data['quantity'],
                            ),
                            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(38)),
                            child: const Text('موافقة'),
                          ),
                        ),
                      ],
                    ),
                  ] else if (status == 'confirmed') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => SellerOrderService().updateStatus(
                          orderId, 'preparing',
                          customerId: data['customerId'],
                          productName: data['productName'],
                        ),
                        icon: const Icon(Icons.inventory_2_outlined, size: 16),
                        label: const Text('بدء التجهيز'),
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(38)),
                      ),
                    ),
                  ] else if (status == 'preparing') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => SellerOrderService().updateStatus(
                          orderId, 'shipped',
                          customerId: data['customerId'],
                          productName: data['productName'],
                        ),
                        icon: const Icon(Icons.local_shipping_outlined, size: 16),
                        label: const Text('تم الشحن'),
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(38)),
                      ),
                    ),
                  ] else if (status == 'shipped') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => SellerOrderService().updateStatus(
                          orderId, 'delivered',
                          customerId: data['customerId'],
                          productName: data['productName'],
                        ),
                        icon: const Icon(Icons.home_rounded, size: 16),
                        label: const Text('تم التسليم'),
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(38)),
                      ),
                    ),
                  ] 
                  // ✅ تمت إضافة حالة الطلب الملغى من قبل الزبون
                  else if (isCancelled)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.grey.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cancel_outlined, color: AppColors.grey, size: 14),
                          SizedBox(width: 4),
                          Text('ألغاه الزبون', style: TextStyle(color: AppColors.grey, fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: AppColors.success, size: 14),
                          SizedBox(width: 4),
                          Text('تم التسليم', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
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