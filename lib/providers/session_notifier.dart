import 'package:flutter/foundation.dart';

/// Network requests may finish after their account's provider tree is removed.
class SessionNotifier extends ChangeNotifier {
  bool _disposed = false;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
