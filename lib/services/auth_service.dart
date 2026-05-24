import 'package:firebase_auth/firebase_auth.dart';

import 'firestore_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authState => _auth.authStateChanges();

  static Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cleanName = name.trim();
      final cleanEmail = email.trim();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password.trim(),
      );

      await credential.user?.updateDisplayName(cleanName);

      await FirestoreService.createUserProfile(
        name: cleanName,
        email: cleanEmail,
      );

      return null;
    } on FirebaseAuthException catch (e) {
      return '${e.code}: ${e.message ?? "Firebase auth error"}';
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      return null;
    } on FirebaseAuthException catch (e) {
      return '${e.code}: ${e.message ?? "Firebase auth error"}';
    } catch (e) {
      return e.toString();
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }
  static Future<String?> resetPassword({
  required String email,
}) async {
  try {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      return 'Please enter your email first.';
    }

    await _auth.sendPasswordResetEmail(email: cleanEmail);

    return null;
  } on FirebaseAuthException catch (e) {
    return '${e.code}: ${e.message ?? "Firebase auth error"}';
  } catch (e) {
    return e.toString();
  }
}
}