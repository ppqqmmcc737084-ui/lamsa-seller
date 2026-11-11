import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/seller_application_service.dart';
import '../admin/admin_review_screen.dart';
import '../auth/login_screen.dart';
import '../dashboard/main_navigation.dart';
import '../registration/seller_registration_screen.dart';
import '../splash/splash_screen.dart';
import 'application_status_screens.dart';

/// جذر التطبيق: يقرر الشاشة بحسب تسجيل الدخول وحالة طلب التاجر.
class SellerGate extends StatelessWidget {
  const SellerGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SplashScreen();
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return _UserGate(key: ValueKey(user.uid));
      },
    );
  }
}

class _UserGate extends StatefulWidget {
  const _UserGate({super.key});

  @override
  State<_UserGate> createState() => _UserGateState();
}

class _UserGateState extends State<_UserGate> {
  final _service = SellerApplicationService();
  late final Future<bool> _adminFuture = _service.isAdmin();
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _stream = _service.streamMine();
  bool _editingRejected = false;
  bool _storeEnsured = false;

  Future<void> _ensureStoreDoc(Map<String, dynamic> data) async {
    if (_storeEnsured) return;
    _storeEnsured = true;
    try {
      await _service.ensureStoreDoc(data);
    } catch (e) {
      debugPrint('فشل تجهيز وثيقة المتجر: $e');
    }
  }

  Widget _errorView() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 52),
              const SizedBox(height: 12),
              const Text('تعذّر تحميل حالة حسابك', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => setState(() => _stream = _service.streamMine()),
                child: const Text('إعادة المحاولة'),
              ),
              TextButton(onPressed: () => AuthService().signOut(), child: const Text('تسجيل الخروج')),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _adminFuture,
      builder: (context, adminSnap) {
        if (!adminSnap.hasData) return const SplashScreen();
        if (adminSnap.data == true) return const AdminReviewScreen();

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _stream,
          builder: (context, snap) {
            if (snap.hasError && !snap.hasData) return _errorView();
            if (!snap.hasData) return const SplashScreen();

            final data = snap.data!.data();
            final status = data?['status'];

            if (data == null || status == 'draft') {
              return SellerRegistrationScreen(initial: data ?? const <String, dynamic>{});
            }
            if (status == 'pendingReview') {
              _editingRejected = false;
              return const PendingReviewScreen();
            }
            if (status == 'approved') {
              _ensureStoreDoc(data);
              return const MainNavigation();
            }
            if (status == 'rejected') {
              if (_editingRejected) return SellerRegistrationScreen(initial: data);
              return RejectedScreen(
                reason: (data['rejectionReason'] ?? '').toString(),
                onEdit: () => setState(() => _editingRejected = true),
              );
            }
            return SellerRegistrationScreen(initial: data);
          },
        );
      },
    );
  }
}
