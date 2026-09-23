import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SellerBannerService {
  final _collection = FirebaseFirestore.instance.collection('banners');
  String get _sellerId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> addBanner({
    required Uint8List imageBytes,
    required String imageName,
    required String title,
    String? productId,
  }) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('banners')
        .child(_sellerId)
        .child('${DateTime.now().millisecondsSinceEpoch}_$imageName');
    final task = await ref.putData(imageBytes);
    final imageUrl = await task.ref.getDownloadURL();

    await _collection.add({
      'sellerId': _sellerId,
      'imageUrl': imageUrl,
      'title': title,
      'productId': productId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> streamMyBanners() {
    return _collection.where('sellerId', isEqualTo: _sellerId).snapshots();
  }

  Future<void> deleteBanner(String id) => _collection.doc(id).delete();
}