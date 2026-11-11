import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  Future<String> uploadProductImage(Uint8List bytes, String fileName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final lower = fileName.toLowerCase();
    final type = lower.endsWith('.png')
        ? 'image/png'
        : (lower.endsWith('.webp') ? 'image/webp' : 'image/jpeg');
    final ref = FirebaseStorage.instance
        .ref()
        .child('products')
        .child(uid)
        .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');
    final task = await ref.putData(bytes, SettableMetadata(contentType: type));
    return await task.ref.getDownloadURL();
  }
}
