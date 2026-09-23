import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerProductService {
  final _collection = FirebaseFirestore.instance.collection('products');

  String get _sellerId => FirebaseAuth.instance.currentUser?.uid ?? '';
    Future<void> addProduct({
    required String name,
    required String description,
    required double price,
    double? discountPrice,
    required String imageUrl,
    required String category,
  }) async {
    final sellerDoc = await FirebaseFirestore.instance.collection('sellers').doc(_sellerId).get();
    final storeName = sellerDoc.data()?['storeName'] ?? 'متجر لمسة';

    await _collection.add({
      'sellerId': _sellerId,
      'storeName': storeName,
      'name': name,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'imageUrl': imageUrl,
      'category': category,
      'rating': 0,
      'reviewsCount': 0,
      'soldCount': 0,
      'isBestSeller': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  Stream<QuerySnapshot> streamMyProducts() {
    return _collection.where('sellerId', isEqualTo: _sellerId).snapshots();
  }
  Future<void> updateProduct(
    String productId, {
    required String name,
    required String description,
    required double price,
    double? discountPrice,
    required String imageUrl,
    required String category,
  }) async {
    await _collection.doc(productId).update({
      'name': name,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'imageUrl': imageUrl,
      'category': category,
    });
  }
  Future<void> deleteProduct(String productId) => _collection.doc(productId).delete();
}