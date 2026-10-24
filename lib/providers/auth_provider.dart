import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportify/services/auth_service.dart';

/// Provider managing authentication state and actions.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  StreamSubscription<User?>? _authSubscription;

  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService() {
    init();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isInitialized => _isInitialized;

  void init() {
    _user = _authService.currentUser;
    _authSubscription?.cancel();
    _authSubscription = _authService.authStateChanges.listen((User? user) {
      _user = user;
      _isInitialized = true;
      notifyListeners();
    });
  }

  /// Register with email and password.
  Future<void> registerWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _authService.registerWithEmail(email, password);
      _user = credential.user;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e.code);
      rethrow;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with email and password.
  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithEmail(email, password);
      _user = credential.user;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e.code);
      rethrow;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send password reset email.
  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.changePassword(currentPassword, newPassword);
    } on FirebaseAuthException catch (e) {
      _error = switch (e.code) {
        'wrong-password' ||
        'invalid-credential' => 'Your current password is incorrect.',
        'weak-password' || 'password-does-not-meet-requirements' =>
          'Choose a stronger password that meets the account requirements.',
        'too-many-requests' =>
          'Too many attempts. Please wait before trying again.',
        'network-request-failed' => 'Check your connection and try again.',
        'requires-recent-login' ||
        'user-token-expired' => 'Sign out and sign in again, then retry.',
        _ => 'Couldn’t change your password. Please try again.',
      };
      rethrow;
    } catch (_) {
      _error = 'Couldn’t change your password. Please try again.';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with Google.
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithGoogle();
      if (credential != null) {
        _user = credential.user;
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Convert Firebase error codes to user-friendly messages.
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try logging in.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Authentication error: $code';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
