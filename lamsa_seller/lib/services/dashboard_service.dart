import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardStats {
  final int totalProducts;
  final int pendingOrders;
  final int confirmedOrders;
  final double totalRevenue;

  DashboardStats({
    required this.totalProducts,
    required this.pendingOrders,
    required this.confirmedOrders,
    required this.totalRevenue,
  });
}

class DashboardService {
  String get _sellerId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<DashboardStats> streamStats() {
    final productsStream = FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: _sellerId)
        .snapshots();

    final ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .where('sellerId', isEqualTo: _sellerId)
        .snapshots();

    return productsStream.asyncMap((productsSnap) async {
      final ordersSnap = await ordersStream.first;
      int pending = 0;
      int confirmed = 0;
      double revenue = 0;

      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        final status = data['status'] ?? '';
        if (status == 'pendingApproval') pending++;
        if (status == 'confirmed' || status == 'completed') {
          confirmed++;
          revenue += (data['paidAmount'] ?? 0).toDouble();
        }
      }

      return DashboardStats(
        totalProducts: productsSnap.docs.length,
        pendingOrders: pending,
        confirmedOrders: confirmed,
        totalRevenue: revenue,
      );
    });
  }
}