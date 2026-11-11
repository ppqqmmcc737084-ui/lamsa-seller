import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class PendingReviewScreen extends StatelessWidget {
  const PendingReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StatusScaffold(
      icon: Icons.hourglass_top_rounded,
      color: AppColors.accent,
      title: 'طلبك قيد المراجعة',
      message: 'نراجع بياناتك ووثائقك الآن. ما تقدر تضيف منتجات إلا بعد القبول، افتح التطبيق لاحقاً لمتابعة الحالة.',
    );
  }
}

class RejectedScreen extends StatelessWidget {
  final String reason;
  final VoidCallback onEdit;
  const RejectedScreen({super.key, required this.reason, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return _StatusScaffold(
      icon: Icons.cancel_outlined,
      color: AppColors.primary,
      title: 'لم يُقبل طلبك',
      message: reason.isEmpty ? 'راجع بياناتك ووثائقك ثم أعد الإرسال.' : 'السبب: $reason',
      action: ElevatedButton(onPressed: onEdit, child: const Text('تعديل البيانات وإعادة الإرسال')),
    );
  }
}

class _StatusScaffold extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final Widget? action;
  const _StatusScaffold({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: Icon(icon, color: color, size: 44),
                ),
                const SizedBox(height: 20),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.dark)),
                const SizedBox(height: 8),
                Text(message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.grey, height: 1.6)),
                if (action != null) ...[const SizedBox(height: 24), action!],
                const SizedBox(height: 12),
                TextButton(onPressed: () => AuthService().signOut(), child: const Text('تسجيل الخروج')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
