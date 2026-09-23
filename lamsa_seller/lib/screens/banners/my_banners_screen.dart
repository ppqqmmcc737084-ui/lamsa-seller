import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../services/seller_banner_service.dart';
import 'add_banner_screen.dart';

class MyBannersScreen extends StatelessWidget {
  const MyBannersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة العروض')),
      body: StreamBuilder<QuerySnapshot>(
        stream: SellerBannerService().streamMyBanners(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('ما سويت أي بانر بعد', style: TextStyle(color: AppColors.grey)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.medium)),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(data['imageUrl'] ?? '', width: 70, height: 50, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700))),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.grey),
                      onPressed: () => SellerBannerService().deleteBanner(docs[index].id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBannerScreen())),
        icon: const Icon(Icons.add),
        label: const Text('بانر جديد'),
      ),
    );
  }
}