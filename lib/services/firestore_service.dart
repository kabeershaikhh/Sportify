import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportify/models/user_model.dart';
import 'package:sportify/models/activity_model.dart';
import 'package:sportify/models/connection_model.dart';
import 'package:sportify/models/venue_model.dart';
import 'package:sportify/models/chat_model.dart';
import 'package:sportify/models/message_model.dart';
import 'package:sportify/models/game_join_request_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service managing all Cloud Firestore database operations for Sportify.
class FirestoreService {
  final FirebaseFirestore? _instance;
  FirestoreService({FirebaseFirestore? firestore}) : _instance = firestore;
  FirebaseFirestore get _firestore => _instance ?? FirebaseFirestore.instance;

  // ==========================================
  // USERS
  // ==========================================

  /// Saves a new user or overwrites an existing user in Firestore.
  Future<void> createUser(UserModel user) async {
    final ref = _firestore.collection('users').doc(user.uid);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      if (existing.data()?['isProfileComplete'] == true) {
        throw StateError(
          'Your profile is already set up. Edit it from Profile.',
        );
      }
      transaction.set(ref, user.toMap());
    });
  }

  /// Fetches a single user document by [uid]. Returns null if not found.
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  /// Updates specific fields for user [uid].
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  /// Queries users based on optional filters: [sport], [area], [skillLevel].
  Future<List<UserModel>> getUsersByFilters({
    String? sport,
    String? area,
    String? skillLevel,
  }) async {
    Query query = _firestore
        .collection('users')
        .where('isProfileComplete', isEqualTo: true);

    if (area != null && area.isNotEmpty && area != 'All') {
      query = query.where('area', isEqualTo: area);
    }

    final snapshot = await query.get();
    var users = snapshot.docs
        .map(
          (doc) =>
              UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();

    if (sport != null && sport.isNotEmpty && sport != 'All') {
      users = users.where((u) {
        return u.sports.any((s) => (s['sport'] == sport || s['name'] == sport));
      }).toList();
    }

    if (skillLevel != null && skillLevel.isNotEmpty && skillLevel != 'All') {
      users = users.where((u) {
        return u.sports.any((s) {
          final matchesSport =
              (sport == null ||
              sport.isEmpty ||
              sport == 'All' ||
              s['sport'] == sport ||
              s['name'] == sport);
          return matchesSport && s['skillLevel'] == skillLevel;
        });
      }).toList();
    }

    return users;
  }

  /// Streams real-time updates for a single user document by [uid].
  Stream<UserModel?> streamUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  // ==========================================
  // ACTIVITIES
  // ==========================================

  /// Creates a new sports activity match.
  Future<void> createActivity(ActivityModel activity) async {
    if (activity.playersNeeded < 2 ||
        activity.playersNeeded > 100 ||
        !activity.dateTime.isAfter(DateTime.now()) ||
        activity.venue.trim().isEmpty) {
      throw StateError(
        'Choose a future time, a venue, and 2–100 total players.',
      );
    }
    final docRef = activity.id.isEmpty
        ? _firestore.collection('activities').doc()
        : _firestore.collection('activities').doc(activity.id);

    final finalActivity = activity.copyWith(id: docRef.id);
    await docRef.set(finalActivity.toMap());
  }

  /// Fetches a list of activities with optional filters for [sport] and [area].
  Future<List<ActivityModel>> getActivities({
    String? sport,
    String? area,
  }) async {
    Query query = _firestore.collection('activities');

    if (sport != null && sport.isNotEmpty && sport != 'All') {
      query = query.where('sport', isEqualTo: sport);
    }

    if (area != null && area.isNotEmpty && area != 'All') {
      query = query.where('area', isEqualTo: area);
    }

    final snapshot = await query.get();
    final activities = snapshot.docs
        .map(
          (doc) =>
              ActivityModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();

    activities.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return activities;
  }

  /// Streams activities with optional filters for [sport] and [area].
  Stream<List<ActivityModel>> streamActivities({String? sport, String? area}) {
    Query query = _firestore.collection('activities');

    if (sport != null && sport.isNotEmpty && sport != 'All') {
      query = query.where('sport', isEqualTo: sport);
    }

    if (area != null && area.isNotEmpty && area != 'All') {
      query = query.where('area', isEqualTo: area);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map(
            (doc) => ActivityModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
      list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return list;
    });
  }

  /// Fetches a single activity by [id].
  Future<ActivityModel?> getActivity(String id) async {
    final doc = await _firestore.collection('activities').doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return ActivityModel.fromMap(doc.data()!, doc.id);
  }

  /// Updates specific fields of an activity.
  Future<void> updateActivity(String id, Map<String, dynamic> data) async {
    await _firestore.collection('activities').doc(id).update(data);
  }

  /// Edits details without replacing membership or request approval metadata.
  Future<void> editActivityDetails(ActivityModel edited, String hostId) async {
    final ref = _firestore.collection('activities').doc(edited.id);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw StateError('This game no longer exists.');
      final current = ActivityModel.fromMap(snapshot.data()!, edited.id);
      if (current.hostId != hostId) {
        throw StateError('Only the host can edit this game.');
      }
      if (current.status == 'cancelled' ||
          !current.dateTime.isAfter(DateTime.now())) {
        throw StateError('Only upcoming active games can be edited.');
      }
      if (!edited.dateTime.isAfter(DateTime.now()) ||
          edited.venue.trim().isEmpty ||
          edited.sport.trim().isEmpty ||
          edited.area.trim().isEmpty ||
          edited.skillLevel.trim().isEmpty ||
          edited.playersNeeded < 2 ||
          edited.playersNeeded > 100) {
        throw StateError(
          'Choose a future time, a venue, and 2–100 total players.',
        );
      }
      if (edited.playersNeeded < current.participantIds.length) {
        throw StateError(
          'Keep room for all ${current.participantIds.length} joined players.',
        );
      }
      transaction.update(ref, {
        'sport': edited.sport,
        'skillLevel': edited.skillLevel,
        'area': edited.area,
        'dateTime': Timestamp.fromDate(edited.dateTime),
        'venue': edited.venue.trim(),
        'venueAddress': edited.venueAddress,
        'playersNeeded': edited.playersNeeded,
        'description': edited.description,
        'status': current.participantIds.length >= edited.playersNeeded
            ? 'full'
            : 'open',
      });
    });
  }

  /// Adds a user to the activity participant list.
  Future<void> joinActivity(String activityId, String userId) async {
    await _changeParticipation(activityId, userId, joining: true);
  }

  /// Removes a user from the activity participant list.
  Future<void> leaveActivity(String activityId, String userId) async {
    await _changeParticipation(activityId, userId, joining: false);
  }

  Stream<GameJoinRequestModel?> streamGameJoinRequest(
    String activityId,
    String requesterId,
  ) {
    return _firestore
        .collection('game_join_requests')
        .doc('${activityId}_$requesterId')
        .snapshots()
        .map(
          (doc) => doc.exists
              ? GameJoinRequestModel.fromMap(doc.data()!, doc.id)
              : null,
        );
  }

  Stream<List<GameJoinRequestModel>> streamHostGameJoinRequests(String hostId) {
    return _firestore
        .collection('game_join_requests')
        .where('hostId', isEqualTo: hostId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GameJoinRequestModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<GameJoinRequestModel>> streamMyGameJoinRequests(
    String requesterId,
  ) {
    return _firestore
        .collection('game_join_requests')
        .where('requesterId', isEqualTo: requesterId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GameJoinRequestModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> requestToJoinActivity({
    required String activityId,
    required String requesterId,
    required String requesterName,
  }) async {
    final activityRef = _firestore.collection('activities').doc(activityId);
    await _firestore.runTransaction((transaction) async {
      final activityDoc = await transaction.get(activityRef);
      if (!activityDoc.exists) throw StateError('This game no longer exists.');
      final activity = ActivityModel.fromMap(activityDoc.data()!, activityId);
      if (activity.hostId == requesterId) {
        throw StateError('You are already the host of this game.');
      }
      final pair = [requesterId, activity.hostId]..sort();
      final connectionRef = _firestore
          .collection('connections')
          .doc(pair.join('_'));
      final requestRef = _firestore
          .collection('game_join_requests')
          .doc('${activityId}_$requesterId');
      final connectionDoc = await transaction.get(connectionRef);
      final requestDoc = await transaction.get(requestRef);
      if (connectionDoc.data()?['status'] != 'accepted') {
        throw StateError('Connect with the host before requesting to join.');
      }
      if (!activity.dateTime.isAfter(DateTime.now()) ||
          activity.status == 'cancelled') {
        throw StateError('This game is no longer accepting players.');
      }
      if (activity.isFull) throw StateError('This game is already full.');
      if (activity.participantIds.contains(requesterId)) return;
      if (requestDoc.exists && requestDoc.data()?['status'] == 'pending') {
        throw StateError('Your request is already waiting for the host.');
      }
      transaction.set(
        requestRef,
        GameJoinRequestModel(
          id: requestRef.id,
          activityId: activityId,
          requesterId: requesterId,
          requesterName: requesterName,
          hostId: activity.hostId,
          status: 'pending',
          createdAt: DateTime.now(),
        ).toMap(),
      );
    });
  }

  Future<void> respondToGameJoinRequest({
    required String requestId,
    required String hostId,
    required bool accept,
  }) async {
    final requestRef = _firestore
        .collection('game_join_requests')
        .doc(requestId);
    final requestSnapshot = await requestRef.get();
    if (!requestSnapshot.exists) {
      throw StateError('This request no longer exists.');
    }
    final initialRequest = GameJoinRequestModel.fromMap(
      requestSnapshot.data()!,
      requestSnapshot.id,
    );
    final activityRef = _firestore
        .collection('activities')
        .doc(initialRequest.activityId);
    final legacyChats = await _firestore
        .collection('chats')
        .where('type', isEqualTo: 'activity')
        .where('activityId', isEqualTo: initialRequest.activityId)
        .get();
    final chatRefs = {
      _firestore
          .collection('chats')
          .doc('activity_${initialRequest.activityId}')
          .path: _firestore
          .collection('chats')
          .doc('activity_${initialRequest.activityId}'),
      for (final doc in legacyChats.docs) doc.reference.path: doc.reference,
    }.values.toList();

    await _firestore.runTransaction((transaction) async {
      final requestDoc = await transaction.get(requestRef);
      final activityDoc = await transaction.get(activityRef);
      if (!requestDoc.exists) {
        throw StateError('This request no longer exists.');
      }
      final request = GameJoinRequestModel.fromMap(
        requestDoc.data()!,
        requestId,
      );
      if (!activityDoc.exists) throw StateError('This game no longer exists.');
      final activity = ActivityModel.fromMap(
        activityDoc.data()!,
        activityRef.id,
      );
      final chats = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final ref in chatRefs) {
        chats.add(await transaction.get(ref));
      }
      if (request.status != 'pending' ||
          request.hostId != hostId ||
          activity.hostId != hostId) {
        throw StateError('This request is no longer available.');
      }
      if (!accept) {
        transaction.update(requestRef, {'status': 'declined'});
        return;
      }
      final pair = [hostId, request.requesterId]..sort();
      final connectionRef = _firestore
          .collection('connections')
          .doc(pair.join('_'));
      final connectionDoc = await transaction.get(connectionRef);
      if (connectionDoc.data()?['status'] != 'accepted') {
        throw StateError(
          'You must be connected before approving this request.',
        );
      }
      if (!activity.dateTime.isAfter(DateTime.now()) ||
          activity.status == 'cancelled') {
        throw StateError('This game is no longer accepting players.');
      }
      if (activity.isFull) throw StateError('This game is already full.');
      if (activity.participantIds.contains(request.requesterId)) {
        throw StateError('This player already joined the game.');
      }
      final ids = [...activity.participantIds, request.requesterId];
      transaction.update(requestRef, {'status': 'accepted'});
      transaction.update(activityRef, {
        'participantIds': ids,
        'status': ids.length >= activity.playersNeeded ? 'full' : 'open',
        'lastApprovedJoinRequestId': requestId,
      });
      for (final chat in chats) {
        if (chat.exists) {
          final data = chat.data()!;
          transaction.update(chat.reference, {
            'participantIds': ids,
            'participantNames': {
              ...((data['participantNames'] as Map?)?.map(
                    (key, value) => MapEntry(key.toString(), value.toString()),
                  ) ??
                  {}),
              request.requesterId: request.requesterName,
            },
          });
        }
      }
    });
  }

  Stream<ActivityModel?> streamActivity(String id) => _firestore
      .collection('activities')
      .doc(id)
      .snapshots()
      .map(
        (doc) => doc.exists ? ActivityModel.fromMap(doc.data()!, doc.id) : null,
      );

  Future<void> _changeParticipation(
    String id,
    String uid, {
    required bool joining,
  }) async {
    if (joining) {
      throw StateError('Send a join request and wait for the host to accept.');
    }
    final ref = _firestore.collection('activities').doc(id);
    final chatRef = _firestore.collection('chats').doc('activity_$id');
    final rooms = await _firestore
        .collection('chats')
        .where('type', isEqualTo: 'activity')
        .where('activityId', isEqualTo: id)
        .get();
    final refs = {
      chatRef.path: chatRef,
      for (final room in rooms.docs) room.reference.path: room.reference,
    }.values.toList();
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw StateError('This game no longer exists.');
      final activity = ActivityModel.fromMap(snapshot.data()!, id);
      final chats = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final room in refs) {
        chats.add(await transaction.get(room));
      }
      final ids = [...activity.participantIds];
      if (joining) {
        throw StateError(
          'Send a join request and wait for the host to accept.',
        );
      } else {
        if (uid == activity.hostId) {
          throw StateError('Hosts must cancel the game instead of leaving.');
        }
        ids.remove(uid);
      }
      transaction.update(ref, {
        'participantIds': ids,
        'status': activity.status == 'cancelled'
            ? 'cancelled'
            : ids.length >= activity.playersNeeded
            ? 'full'
            : 'open',
      });
      for (final chat in chats) {
        if (chat.exists) {
          transaction.update(chat.reference, {'participantIds': ids});
        }
      }
    });
  }

  // ==========================================
  // CONNECTIONS
  // ==========================================

  /// Creates a new connection/friend request.
  Future<void> createConnection(ConnectionModel connection) async {
    if (connection.fromUserId == connection.toUserId) {
      throw StateError('You cannot connect with yourself.');
    }
    final pair = [connection.fromUserId, connection.toUserId]..sort();
    final docRef = _firestore.collection('connections').doc(pair.join('_'));
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(docRef);
      if (existing.exists && existing.data()?['status'] != 'declined') {
        throw StateError('A connection or request already exists.');
      }
      transaction.set(docRef, connection.copyWith(id: docRef.id).toMap());
    });
  }

  /// Streams all connections where the user is either the sender or receiver.
  Stream<List<ConnectionModel>> getConnections(String userId) {
    return _firestore
        .collection('connections')
        .where(
          Filter.or(
            Filter('fromUserId', isEqualTo: userId),
            Filter('toUserId', isEqualTo: userId),
          ),
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ConnectionModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Updates the status of a connection ('pending', 'accepted', 'declined').
  Future<void> updateConnectionStatus(
    String connectionId,
    String status,
  ) async {
    await _firestore.collection('connections').doc(connectionId).update({
      'status': status,
    });
  }

  /// Checks if a connection request or relationship already exists between two users.
  Future<bool> checkExistingConnection(
    String fromUserId,
    String toUserId,
  ) async {
    final snapshot = await _firestore
        .collection('connections')
        .where(
          Filter.or(
            Filter.and(
              Filter('fromUserId', isEqualTo: fromUserId),
              Filter('toUserId', isEqualTo: toUserId),
            ),
            Filter.and(
              Filter('fromUserId', isEqualTo: toUserId),
              Filter('toUserId', isEqualTo: fromUserId),
            ),
          ),
        )
        .get();

    return snapshot.docs.any((doc) => doc.data()['status'] != 'declined');
  }

  // ==========================================
  // VENUES
  // ==========================================

  /// Fetches a list of venues with optional filters for [sport] and [area].
  Future<List<VenueModel>> getVenues({String? sport, String? area}) async {
    Query query = _firestore
        .collection('venues')
        .where('status', isEqualTo: 'approved');

    if (area != null && area.isNotEmpty && area != 'All') {
      query = query.where('area', isEqualTo: area);
    }

    if (sport != null && sport.isNotEmpty && sport != 'All') {
      query = query.where('sports', arrayContains: sport);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map(
          (doc) =>
              VenueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  /// Suggests a new venue to be reviewed and approved.
  Future<void> suggestVenue(VenueModel venue) async {
    final docRef = venue.id.isEmpty
        ? _firestore.collection('venues').doc()
        : _firestore.collection('venues').doc(venue.id);

    final finalVenue = venue.copyWith(id: docRef.id);
    await docRef.set(finalVenue.toMap());
  }

  // ==========================================
  // CHATS
  // ==========================================

  /// Finds an existing direct chat between two users or creates a new one.
  Future<ChatModel> getOrCreateDirectChat(
    String userId1,
    String userId2,
    String name1,
    String name2,
  ) async {
    if (userId1 == userId2) {
      throw StateError('Choose another player to chat with.');
    }
    final relationship = await _firestore
        .collection('connections')
        .where(
          Filter.or(
            Filter.and(
              Filter('fromUserId', isEqualTo: userId1),
              Filter('toUserId', isEqualTo: userId2),
            ),
            Filter.and(
              Filter('fromUserId', isEqualTo: userId2),
              Filter('toUserId', isEqualTo: userId1),
            ),
          ),
        )
        .get();
    final accepted = relationship.docs.where(
      (doc) => doc.data()['status'] == 'accepted',
    );
    if (accepted.isEmpty) {
      throw StateError('Accept a connection before starting a direct chat.');
    }
    final connectionId = accepted.first.id;
    final snapshot = await _firestore
        .collection('chats')
        .where('type', isEqualTo: 'direct')
        .where('participantIds', arrayContains: userId1)
        .get();

    for (final doc in snapshot.docs) {
      final chat = ChatModel.fromMap(doc.data(), doc.id);
      if (chat.participantIds.contains(userId2)) {
        return chat;
      }
    }

    // Direct chat does not exist yet, create a new one
    final pair = [userId1, userId2]..sort();
    final docRef = _firestore
        .collection('chats')
        .doc('direct_${pair.join('_')}');
    final newChat = ChatModel(
      id: docRef.id,
      type: 'direct',
      participantIds: [userId1, userId2],
      participantNames: {userId1: name1, userId2: name2},
      createdAt: DateTime.now(),
    );
    return _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(docRef);
      if (existing.exists) {
        return ChatModel.fromMap(existing.data()!, existing.id);
      }
      transaction.set(docRef, {
        ...newChat.toMap(),
        'connectionId': connectionId,
      });
      return newChat;
    });
  }

  /// Creates or retrieves a group chat for an activity.
  Future<ChatModel> createActivityChat(
    String activityId,
    List<String> participantIds,
    Map<String, String> names,
  ) async {
    final legacy = await _firestore
        .collection('chats')
        .where('type', isEqualTo: 'activity')
        .where('activityId', isEqualTo: activityId)
        .get();
    final docRef = legacy.docs.isNotEmpty
        ? legacy.docs.first.reference
        : _firestore.collection('chats').doc('activity_$activityId');
    final activityRef = _firestore.collection('activities').doc(activityId);
    return _firestore.runTransaction((transaction) async {
      final gameDoc = await transaction.get(activityRef);
      final existing = await transaction.get(docRef);
      if (!gameDoc.exists) throw StateError('This game no longer exists.');
      final game = ActivityModel.fromMap(gameDoc.data()!, activityId);
      if (!game.participantIds.contains(
        FirebaseAuth.instance.currentUser?.uid,
      )) {
        throw StateError('Join this game before opening its group chat.');
      }
      final chat = existing.exists
          ? ChatModel.fromMap(existing.data()!, existing.id)
          : ChatModel(
              id: docRef.id,
              type: 'activity',
              participantIds: game.participantIds,
              participantNames: names,
              activityId: activityId,
              createdAt: DateTime.now(),
            );
      transaction.set(docRef, {
        ...chat.toMap(),
        'participantIds': game.participantIds,
        'participantNames': {...chat.participantNames, ...names},
      }, SetOptions(merge: true));
      return ChatModel.fromMap({
        ...chat.toMap(),
        'participantIds': game.participantIds,
      }, docRef.id);
    });
  }

  /// Streams all chats where the user is a participant.
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
              .toList();
          chats.sort((a, b) {
            final aTime = a.lastMessageAt ?? a.createdAt;
            final bTime = b.lastMessageAt ?? b.createdAt;
            return bTime.compareTo(aTime);
          });
          return chats;
        });
  }

  /// Sends a message into a chat conversation and updates last message preview.
  Future<ChatModel> getChat(String id) async {
    final doc = await _firestore.collection('chats').doc(id).get();
    if (!doc.exists) throw StateError('Conversation no longer exists.');
    return ChatModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> sendMessage(String chatId, MessageModel message) async {
    final messageRef = message.id.isEmpty
        ? _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .doc()
        : _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .doc(message.id);

    final finalMessage = message.copyWith(id: messageRef.id);
    if (message.text.trim().isEmpty || message.text.length > 2000) {
      throw StateError('Messages must contain 1–2000 characters.');
    }
    final batch = _firestore.batch();
    batch.set(messageRef, finalMessage.toMap());
    batch.update(_firestore.collection('chats').doc(chatId), {
      'lastMessage': message.text,
      'lastMessageAt': Timestamp.fromDate(message.sentAt),
    });
    await batch.commit();
  }

  /// Streams all messages within a specific chat conversation, ordered chronologically.
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Updates the last message preview and timestamp for a chat.
  Future<void> updateLastMessage(String chatId, String text) async {
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageAt': Timestamp.now(),
    });
  }

  // ==========================================
  // REPORTS
  // ==========================================

  /// Stores a user or content report.
  Future<void> createReport(Map<String, dynamic> reportData) async {
    await _firestore.collection('reports').add({
      ...reportData,
      'createdAt': Timestamp.now(),
    });
  }
}
