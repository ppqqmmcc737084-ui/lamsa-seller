import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// طلب تسجيل التاجر: مسودة ثم مراجعة ثم قبول أو رفض.
class SellerApplicationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  DocumentReference<Map<String, dynamic>> get _ref =>
      _db.collection('sellerApplications').doc(_uid);

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamMine() => _ref.snapshots();

  Future<bool> isAdmin() async {
    if (_uid.isEmpty) return false;
    try {
      final doc = await _db.collection('admins').doc(_uid).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  /// يحفظ حقولاً في المسودة (وينشئها لو غير موجودة) ويعيد الحالة إلى draft.
  Future<void> saveFields(Map<String, dynamic> fields, {int? step}) {
    final data = <String, dynamic>{
      ...fields,
      if (step != null) 'step': step,
      'status': 'draft',
      'email': FirebaseAuth.instance.currentUser?.email,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    return _ref.set(data, SetOptions(merge: true));
  }

  /// يرفع صورة وثيقة إلى مسار خاص ويرجع المسار.
  Future<String> uploadDoc(Uint8List bytes, String slot, String fileName) async {
    final path = 'sellerDocs/$_uid/$slot';
    final lower = fileName.toLowerCase();
    final type = lower.endsWith('.png')
        ? 'image/png'
        : (lower.endsWith('.webp') ? 'image/webp' : 'image/jpeg');
    await FirebaseStorage.instance.ref(path).putData(bytes, SettableMetadata(contentType: type));
    return path;
  }

  /// يرجع null عند النجاح، أو نصاً يشرح السبب.
  Future<String?> submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'انتهت الجلسة، سجّل دخولك مرة ثانية';
    await user.reload();
    final fresh = FirebaseAuth.instance.currentUser;
    if (fresh == null || !fresh.emailVerified) return 'فعّل بريدك الإلكتروني أولاً';
    await fresh.getIdToken(true);
    await _ref.update({
      'status': 'pendingReview',
      'submittedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return null;
  }

  /// وثيقة المتجر العامة: تُنشأ مرة واحدة بعد القبول.
  Future<void> ensureStoreDoc(Map<String, dynamic> app) async {
    final ref = _db.collection('sellers').doc(_uid);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'storeName': app['storeName'] ?? '',
      'phone': app['phone'] ?? '',
      'walletName': app['walletName'],
      'walletNumber': app['walletNumber'],
      'deliveryFee': app['deliveryFee'] ?? 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ===== للمدير =====

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamPending() {
    return _db
        .collection('sellerApplications')
        .where('status', isEqualTo: 'pendingReview')
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final at = a.data()['submittedAt'];
        final bt = b.data()['submittedAt'];
        if (at is Timestamp && bt is Timestamp) return at.compareTo(bt);
        return 0;
      });
      return docs;
    });
  }

  Future<void> review(String uid, {required bool approve, String? reason}) {
    return _db.collection('sellerApplications').doc(uid).update({
      'status': approve ? 'approved' : 'rejected',
      if (!approve) 'rejectionReason': reason ?? '',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': _uid,
    });
  }

  Future<String> docUrl(String path) => FirebaseStorage.instance.ref(path).getDownloadURL();
}
