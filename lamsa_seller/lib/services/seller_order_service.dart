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

    Future<void> updateStatus(String orderId, String status, {String? customerId, String? productName}) async {
    await _collection.doc(orderId).update({'status': status});

    if (customerId != null) {
      final message = status == 'confirmed'
          ? 'تمت الموافقة على طلبك: $productName'
          : 'تم رفض طلبك: $productName';

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
