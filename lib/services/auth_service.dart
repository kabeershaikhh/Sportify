import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Authentication service wrapping Firebase Auth and Google Sign-In for Sportify.
class AuthService {
  final FirebaseAuth? _instance;
  GoogleSignIn? _google;
  AuthService({FirebaseAuth? auth}) : _instance = auth;
  FirebaseAuth get _auth => _instance ?? FirebaseAuth.instance;
  GoogleSignIn get _googleSignIn => _google ??= GoogleSignIn();

  /// Gets the currently authenticated Firebase user, or null if unauthenticated.
  User? get currentUser => _auth.currentUser;

  /// Stream of user authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register with email and password.
  Future<UserCredential> registerWithEmail(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Send password reset email.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Deletes the authenticated account. A deployed Auth deletion trigger removes
  /// the account's Firestore and Storage data asynchronously.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in account to delete.');
    await user.delete();
  }

  /// Standard Google Sign-In flow using GoogleSignIn and GoogleAuthProvider.
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) return _auth.signInWithPopup(GoogleAuthProvider());
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  /// Signs out from both Google Sign-In and Firebase Auth.
  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        /* Firebase session is already closed. */
      }
    }
  }
}
