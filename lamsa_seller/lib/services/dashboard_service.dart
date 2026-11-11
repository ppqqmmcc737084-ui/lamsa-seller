import 'dart:async';
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

  /// يتحدث مع أي تغيير في المنتجات أو الطلبات.
  /// confirmedOrders = الطلبات النشطة (مؤكد، قيد التجهيز، مشحون).
  /// totalRevenue = إجمالي الطلبات المسلّمة.
  Stream<DashboardStats> streamStats() {
    final db = FirebaseFirestore.instance;
    final controller = StreamController<DashboardStats>();
    QuerySnapshot<Map<String, dynamic>>? products;
    QuerySnapshot<Map<String, dynamic>>? orders;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? productsSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? ordersSub;

    void emit() {
      final p = products;
      final o = orders;
      if (p == null || o == null || controller.isClosed) return;

      int pending = 0;
      int active = 0;
      double revenue = 0;
      for (final doc in o.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString();
        if (status == 'pendingApproval') {
          pending++;
        } else if (status == 'confirmed' || status == 'preparing' || status == 'shipped') {
          active++;
        } else if (status == 'delivered' || status == 'completed') {
          final total = data['totalAmount'];
          if (total is num) revenue += total.toDouble();
        }
      }

      controller.add(DashboardStats(
        totalProducts: p.docs.length,
        pendingOrders: pending,
        confirmedOrders: active,
        totalRevenue: revenue,
      ));
    }

    controller.onListen = () {
      productsSub = db
          .collection('products')
          .where('sellerId', isEqualTo: _sellerId)
          .snapshots()
          .listen((snapshot) {
        products = snapshot;
        emit();
      }, onError: (Object e, StackTrace st) => controller.addError(e, st));

      ordersSub = db
          .collection('orders')
          .where('sellerId', isEqualTo: _sellerId)
          .snapshots()
          .listen((snapshot) {
        orders = snapshot;
        emit();
      }, onError: (Object e, StackTrace st) => controller.addError(e, st));
    };

    controller.onCancel = () async {
      await productsSub?.cancel();
      await ordersSub?.cancel();
    };

    return controller.stream;
  }
}
