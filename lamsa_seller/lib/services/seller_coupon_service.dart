import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerCouponService {
  final _collection = FirebaseFirestore.instance.collection('coupons');
  String get _sellerId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> addCoupon({
    required String code,
    required int discountPercent,
    String? productId,
  }) async {
    await _collection.add({
      'sellerId': _sellerId,
      'code': code.toUpperCase().trim(),
      'discountPercent': discountPercent,
      'productId': productId,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> streamMyCoupons() {
    return _collection.where('sellerId', isEqualTo: _sellerId).snapshots();
  }

  Future<void> toggleActive(String id, bool active) => _collection.doc(id).update({'active': active});
  Future<void> deleteCoupon(String id) => _collection.doc(id).delete();
}