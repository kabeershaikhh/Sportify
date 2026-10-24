import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sportify/providers/session_notifier.dart';
import 'package:sportify/models/chat_model.dart';
import 'package:sportify/models/message_model.dart';
import 'package:sportify/services/firestore_service.dart';

/// Provider managing active chats, messages, and conversation real-time streams.
class ChatProvider extends SessionNotifier {
  final FirestoreService _firestoreService;

  List<ChatModel> _chats = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription<List<ChatModel>>? _chatsSubscription;
  StreamSubscription<List<MessageModel>>? _messagesSubscription;

  ChatProvider({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  /// List of conversations for the user.
  List<ChatModel> get chats => _chats;

  /// Messages belonging to the currently opened chat.
  List<MessageModel> get messages => _messages;

  /// Whether a chat operation is currently loading.
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Listens to real-time chats stream for [userId].
  void loadChats(String userId) {
    _error = null;
    _chats = [];
    _isLoading = true;
    notifyListeners();

    _chatsSubscription?.cancel();
    _chatsSubscription = _firestoreService
        .getUserChats(userId)
        .listen(
          (chats) {
            _chats = chats;
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Error loading user chats: $e');
            _error = 'Conversations couldn’t load. Please try again.';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Listens to real-time messages stream for [chatId].
  void loadMessages(String chatId) {
    _error = null;
    _isLoading = true;
    _messages = [];
    notifyListeners();

    _messagesSubscription?.cancel();
    _messagesSubscription = _firestoreService
        .getMessages(chatId)
        .listen(
          (messages) {
            _messages = messages;
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Error loading chat messages: $e');
            _error = 'Messages couldn’t load. Please try again.';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Sends a new message in [chatId].
  Future<void> sendMessage(String chatId, MessageModel message) async {
    try {
      await _firestoreService.sendMessage(chatId, message);
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// Retrieves an existing direct chat between two users or creates a new one.
  Future<String> getOrCreateDirectChat(
    String userId1,
    String userId2,
    String name1,
    String name2,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final chat = await _firestoreService.getOrCreateDirectChat(
        userId1,
        userId2,
        name1,
        name2,
      );
      return chat.id;
    } catch (e) {
      debugPrint('Error getting or creating direct chat: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates or retrieves a group conversation for an activity.
  Future<String> createActivityChat(
    String activityId,
    List<String> participantIds,
    Map<String, String> names,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final chat = await _firestoreService.createActivityChat(
        activityId,
        participantIds,
        names,
      );
      return chat.id;
    } catch (e) {
      debugPrint('Error creating activity chat: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  void clear() {
    _chatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _chats = [];
    _messages = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
