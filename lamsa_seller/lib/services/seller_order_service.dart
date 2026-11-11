import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class SellerOrderService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection => _db.collection('orders');

  String get _sellerId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<QuerySnapshot> streamMyOrders() {
    return _collection
        .where('sellerId', isEqualTo: _sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// تحديث الحالة هو الأساس ويرمي الخطأ لو فشل.
  /// ما بعده (المبيعات والإشعارات) تكميلي: فشله لا يفشّل العملية.
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
      try {
        await _db.collection('products').doc(productId).update({
          'soldCount': FieldValue.increment(quantity ?? 1),
        });
      } catch (e) {
        debugPrint('فشل تحديث المبيعات: $e');
      }
    }

    if (customerId == null) return;
    final message = _messageFor(status, productName ?? '');
    if (message == null) return;

    try {
      await _db.collection('notifications').add({
        'userId': customerId,
        'message': message,
        'orderId': orderId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('فشل حفظ الإشعار: $e');
    }
    try {
      await NotificationService().sendToCustomer(customerId, message);
    } catch (e) {
      debugPrint('فشل إرسال الإشعار: $e');
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
