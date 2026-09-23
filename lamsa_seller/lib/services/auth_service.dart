import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    }
  }

  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'ما فيه حساب بهذا البريد';
      case 'wrong-password':
        return 'كلمة المرور غلط';
      case 'email-already-in-use':
        return 'هذا البريد مستخدم من قبل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة، لازم 6 أحرف فأكثر';
      case 'invalid-email':
        return 'صيغة البريد غير صحيحة';
      default:
        return 'حدث خطأ: $code';
    }
  }
}