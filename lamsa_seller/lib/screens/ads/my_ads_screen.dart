import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ad_request_service.dart';
import 'request_ad_screen.dart';

class MyAdsScreen extends StatelessWidget {
  const MyAdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعلاناتي')),
      body: StreamBuilder<QuerySnapshot>(
        stream: AdRequestService().streamMyAds(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('ما طلبت أي إعلان بعد', style: TextStyle(color: AppColors.grey)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pendingApproval';
              String statusText = 'بانتظار المراجعة';
              Color statusColor = AppColors.accent;
              if (status == 'active') {
                statusText = 'نشط الآن';
                statusColor = AppColors.success;
              } else if (status == 'rejected') {
                statusText = 'مرفوض';
                statusColor = AppColors.primary;
              } else if (status == 'expired') {
                statusText = 'منتهي';
                statusColor = AppColors.grey;
              }
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.medium)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['productName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('${data['durationDays']} أيام — ${data['price']} ر.ي', style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestAdScreen())),
        icon: const Icon(Icons.campaign_rounded),
        label: const Text('طلب إعلان'),
      ),
    );
  }
}