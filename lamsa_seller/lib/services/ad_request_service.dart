import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdRequestService {
  final _collection = FirebaseFirestore.instance.collection('ads');
  String get _sellerId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> requestAd({
    required String productId,
    required String productName,
    required String productImage,
    required int durationDays,
    required int price,
    required String transferReference,
  }) async {
    final sellerDoc = await FirebaseFirestore.instance.collection('sellers').doc(_sellerId).get();
    await _collection.add({
      'sellerId': _sellerId,
      'storeName': sellerDoc.data()?['storeName'] ?? 'متجر لمسة',
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'durationDays': durationDays,
      'price': price,
      'transferReference': transferReference,
      'status': 'pendingApproval',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> streamMyAds() {
    return _collection.where('sellerId', isEqualTo: _sellerId).orderBy('createdAt', descending: true).snapshots();
  }
}