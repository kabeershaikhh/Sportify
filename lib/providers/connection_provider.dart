import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sportify/providers/session_notifier.dart';
import 'package:sportify/models/connection_model.dart';
import 'package:sportify/services/firestore_service.dart';

/// Provider managing partner connections, friend requests, and connection statuses.
class ConnectionProvider extends SessionNotifier {
  final FirestoreService _firestoreService;

  List<ConnectionModel> _connections = [];
  List<ConnectionModel> _pendingRequests = [];
  bool _isLoading = false;
  StreamSubscription<List<ConnectionModel>>? _connectionsSubscription;

  ConnectionProvider({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  /// All connection records involving the user.
  List<ConnectionModel> get connections => _connections;

  /// Incoming pending connection requests awaiting approval.
  List<ConnectionModel> get pendingRequests => _pendingRequests;

  /// Established connections with status 'accepted'.
  List<ConnectionModel> get acceptedConnections =>
      _connections.where((c) => c.status == 'accepted').toList();

  /// Whether a connection operation is currently processing.
  bool get isLoading => _isLoading;

  /// Listens to real-time connections stream for [userId].
  void loadConnections(String userId) {
    _isLoading = true;
    notifyListeners();

    _connectionsSubscription?.cancel();
    _connectionsSubscription = _firestoreService
        .getConnections(userId)
        .listen(
          (connections) {
            _connections = connections;
            _pendingRequests = connections
                .where((c) => c.toUserId == userId && c.status == 'pending')
                .toList();
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Error loading connections: $e');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Sends a connection request after verifying no previous request exists.
  Future<void> sendRequest(ConnectionModel connection) async {
    _isLoading = true;
    notifyListeners();

    try {
      final exists = await _firestoreService.checkExistingConnection(
        connection.fromUserId,
        connection.toUserId,
      );

      if (exists) {
        throw Exception('A connection request already exists between you.');
      }

      await _firestoreService.createConnection(connection);
    } catch (e) {
      debugPrint('Error sending connection request: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Accepts a pending connection request.
  Future<void> acceptRequest(String connectionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.updateConnectionStatus(connectionId, 'accepted');
    } catch (e) {
      debugPrint('Error accepting connection request: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Declines a pending connection request.
  Future<void> declineRequest(String connectionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.updateConnectionStatus(connectionId, 'declined');
    } catch (e) {
      debugPrint('Error declining connection request: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectionsSubscription?.cancel();
    super.dispose();
  }

  void clear() {
    _connectionsSubscription?.cancel();
    _connections = [];
    _pendingRequests = [];
    _isLoading = false;
    notifyListeners();
  }
}
