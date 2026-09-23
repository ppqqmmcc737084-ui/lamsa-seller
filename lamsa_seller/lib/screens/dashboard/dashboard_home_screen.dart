import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/dashboard_service.dart';
import '../banners/my_banners_screen.dart';

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DashboardStats>(
      stream: DashboardService().streamStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final stats = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('نظرة عامة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.dark)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _statCard('منتجاتي', '${stats.totalProducts}', Icons.inventory_2_rounded, AppColors.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('طلبات جديدة', '${stats.pendingOrders}', Icons.pending_actions_rounded, AppColors.accent)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _statCard('طلبات مؤكدة', '${stats.confirmedOrders}', Icons.check_circle_rounded, AppColors.success)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('إجمالي المبيعات', '${stats.totalRevenue.toStringAsFixed(0)} ر.س', Icons.payments_rounded, AppColors.dark)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBannersScreen())),
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text('إدارة العروض والبانرات'),
                ),
              ),
              if (stats.pendingOrders > 0) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('عندك ${stats.pendingOrders} طلب بانتظار الموافقة — روح تبويب "الطلبات"',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.dark)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.dark)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grey)),
        ],
      ),
    );
  }
}