import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sportify/providers/session_notifier.dart';
import 'package:sportify/models/activity_model.dart';
import 'package:sportify/services/firestore_service.dart';

/// Provider managing sports activities and matches.
class ActivityProvider extends SessionNotifier {
  final FirestoreService _firestoreService;

  List<ActivityModel> _activities = [];
  ActivityModel? _selectedActivity;
  bool _isLoading = false;
  String? _error;
  int _version = 0;
  StreamSubscription<List<ActivityModel>>? _subscription;

  ActivityProvider({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  /// List of retrieved activities.
  List<ActivityModel> get activities => _activities;

  /// Currently selected activity details.
  ActivityModel? get selectedActivity => _selectedActivity;

  /// Whether an activity operation is in progress.
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Loads activities with optional [sport] and [area] filters.
  Future<void> loadActivities({String? sport, String? area}) async {
    final version = ++_version;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // A replacement listener must not wait on the previous stream's shutdown.
      // The version check below discards any late events from that listener.
      _subscription?.cancel();
      if (version != _version) return;
      final initial = Completer<void>();
      _subscription = _firestoreService
          .streamActivities(sport: sport, area: area)
          .listen(
            (activities) {
              if (version != _version) return;
              _activities = activities;
              _error = null;
              _isLoading = false;
              notifyListeners();
              if (!initial.isCompleted) initial.complete();
            },
            onError: (Object e) {
              if (version == _version) {
                _error =
                    'Games couldn’t load. Check your connection and try again.';
                _isLoading = false;
                notifyListeners();
              }
              if (!initial.isCompleted) initial.complete();
            },
          );
      await initial.future;
    } catch (e) {
      debugPrint('Error loading activities: $e');
      if (version == _version) _error = 'Check your connection and try again.';
    } finally {
      if (version == _version) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void clear() {
    _subscription?.cancel();
    _version++;
    _activities = [];
    _selectedActivity = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _version++;
    _subscription?.cancel();
    super.dispose();
  }

  /// Creates a new activity and refreshes the activity list.
  Future<void> createActivity(ActivityModel activity) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.createActivity(activity);
      await loadActivities();
    } catch (e) {
      debugPrint('Error creating activity: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> editActivity(ActivityModel activity, String hostId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.editActivityDetails(activity, hostId);
      await loadActivity(activity.id);
      await loadActivities();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Joins an activity as a participant.
  Future<void> joinActivity(String activityId, String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.joinActivity(activityId, userId);
      await loadActivity(activityId);
      await loadActivities();
    } catch (e) {
      debugPrint('Error joining activity: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Leaves an activity as a participant.
  Future<void> leaveActivity(String activityId, String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.leaveActivity(activityId, userId);
      await loadActivity(activityId);
      await loadActivities();
    } catch (e) {
      debugPrint('Error leaving activity: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancels an activity by updating its status to 'cancelled'.
  Future<void> cancelActivity(String activityId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.updateActivity(activityId, {
        'status': 'cancelled',
      });
      await loadActivity(activityId);
      await loadActivities();
    } catch (e) {
      debugPrint('Error cancelling activity: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads a single activity by [id] into [_selectedActivity].
  Future<void> loadActivity(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedActivity = await _firestoreService.getActivity(id);
    } catch (e) {
      debugPrint('Error loading activity: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
