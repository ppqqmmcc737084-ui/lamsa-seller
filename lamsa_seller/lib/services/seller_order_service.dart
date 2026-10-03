import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class SellerOrderService {
  final _collection = FirebaseFirestore.instance.collection('orders');

  String get _sellerId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<QuerySnapshot> streamMyOrders() {
    return _collection
        .where('sellerId', isEqualTo: _sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updateStatus(
    String orderId,
    String status, {
    String? customerId,
    String? productName,
    String? productId,
    int? quantity,
  }) async {
    await _collection.doc(orderId).update({'status': status});

    if (status == 'confirmed' && productId != null) {
      await FirebaseFirestore.instance.collection('products').doc(productId).update({
        'soldCount': FieldValue.increment(quantity ?? 1),
      });
    }

    if (customerId != null) {
      final message = _messageFor(status, productName ?? '');
      if (message != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': customerId,
          'message': message,
          'orderId': orderId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await NotificationService().sendToCustomer(customerId, message);
      }
    }
  }

  String? _messageFor(String status, String productName) {
    switch (status) {
      case 'confirmed':
        return 'تمت الموافقة على طلبك: $productName';
      case 'rejected':
        return 'تم رفض طلبك: $productName';
      case 'preparing':
        return 'طلبك قيد التجهيز الآن: $productName';
      case 'shipped':
        return 'تم شحن طلبك 🚚: $productName';
      case 'delivered':
        return 'تم تسليم طلبك بنجاح 🎉: $productName';
      default:
        return null;
    }
  }
}