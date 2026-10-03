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
    final sellerData = sellerDoc.data() ?? {};

    await _collection.add({
      'sellerId': _sellerId,
      'storeName': sellerData['storeName'] ?? 'متجر لمسة',
      'walletName': sellerData['walletName'],
      'walletNumber': sellerData['walletNumber'],
      'deliveryFee': sellerData['deliveryFee'] ?? 0, // ✅ تمت الإضافة هنا
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

  Future<void> updateProduct(
    String productId, {
    required String name,
    required String description,
    required double price,
    double? discountPrice,
    required String imageUrl,
    required String category,
    required bool isFeatured,
  }) async {
    await _collection.doc(productId).update({
      'name': name,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'imageUrl': imageUrl,
      'category': category,
      'isFeatured': isFeatured,
    });
  }

  Stream<QuerySnapshot> streamMyProducts() {
    return _collection.where('sellerId', isEqualTo: _sellerId).snapshots();
  }

  Future<void> deleteProduct(String productId) => _collection.doc(productId).delete();
}