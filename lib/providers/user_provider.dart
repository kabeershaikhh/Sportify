import 'package:flutter/foundation.dart';
import 'package:sportify/providers/session_notifier.dart';
import 'package:sportify/models/user_model.dart';
import 'package:sportify/services/firestore_service.dart';
import 'package:sportify/services/matching_service.dart';

/// Provider managing the current user profile and partner discovery state.
class UserProvider extends SessionNotifier {
  final FirestoreService _firestoreService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  int _searchVersion = 0;
  List<UserModel> _discoveredUsers = [];

  UserProvider({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  /// The currently loaded user profile.
  UserModel? get currentUser => _currentUser;

  /// Whether a profile operation or search is in progress.
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// List of users discovered via partner search.
  List<UserModel> get discoveredUsers => _discoveredUsers;

  /// Whether the user has completed their onboarding profile.
  bool get isProfileComplete => _currentUser?.isProfileComplete ?? false;

  /// Fetches and sets the user profile for [uid] from Firestore.
  Future<void> loadUserProfile(String uid) async {
    _isLoading = true;
    _error = null;
    if (_currentUser?.uid != uid) _currentUser = null;
    notifyListeners();

    try {
      _currentUser = await _firestoreService.getUser(uid);
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _error = 'Could not load your profile. Please try again.';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new user profile document in Firestore.
  Future<void> createUserProfile(UserModel user) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.createUser(user);
      _currentUser = user;
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates existing user profile fields in Firestore and reloads profile.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.updateUser(uid, data);
      if (_currentUser?.uid == uid) {
        _currentUser = UserModel.fromMap({
          ..._currentUser!.toMap(),
          ...data,
        }, uid);
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Queries Firestore for sports partners matching the given filters.
  Future<void> discoverPartners({
    String? sport,
    String? area,
    String? skillLevel,
  }) async {
    final version = ++_searchVersion;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final users = await _firestoreService.getUsersByFilters(
        sport: sport,
        area: area,
        skillLevel: skillLevel,
      );
      // Exclude current logged-in user from discovery results
      if (version != _searchVersion) return;
      _discoveredUsers = users
          .where((u) => u.uid != _currentUser?.uid)
          .toList();
      final me = _currentUser;
      if (me != null) {
        _discoveredUsers.sort(
          (a, b) => MatchingService.score(
            me,
            b,
          ).compareTo(MatchingService.score(me, a)),
        );
      }
    } catch (e) {
      if (version != _searchVersion) return;
      _error = 'Partners couldn’t load. Check your connection and try again.';
      debugPrint('Error discovering partners: $e');
      _discoveredUsers = [];
    } finally {
      if (version == _searchVersion) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Clears the active user state (e.g. upon sign out).
  void clearUser() {
    _searchVersion++;
    _error = null;
    _isLoading = false;
    _currentUser = null;
    _discoveredUsers = [];
    notifyListeners();
  }
}
