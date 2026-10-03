import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/payment_type.dart';

class StoreService {
  Stream<List<Product>> streamStoreProducts(String sellerId) {
    return FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: doc.id,
          sellerId: data['sellerId'] ?? '',
          name: data['name'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          description: data['description'] ?? '',
          category: data['category'] ?? '',
          storeName: data['storeName'] ?? 'متجر لمسة',
          price: (data['price'] ?? 0).toDouble(),
          discountPrice: data['discountPrice'] != null ? (data['discountPrice']).toDouble() : null,
          rating: (data['rating'] ?? 0).toDouble(),
          reviewsCount: data['reviewsCount'] ?? 0,
          soldCount: data['soldCount'] ?? 0,
          isBestSeller: data['isBestSeller'] ?? false,
          allowedPayments: const [PaymentType.cashOnDelivery, PaymentType.fullOnline],
        );
      }).toList();
    });
  }

  Future<Map<String, dynamic>?> getStoreInfo(String sellerId) async {
    final doc = await FirebaseFirestore.instance.collection('sellers').doc(sellerId).get();
    return doc.data();
  }
}