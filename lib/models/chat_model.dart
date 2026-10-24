import 'package:cloud_firestore/cloud_firestore.dart';

/// Conversation / Chat room model for Sportify.
class ChatModel {
  final String id;
  final String type; // 'direct', 'activity'
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final String? activityId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  ChatModel({
    required this.id,
    required this.type,
    this.participantIds = const [],
    this.participantNames = const {},
    this.activityId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
  });

  /// Converts [ChatModel] instance into a Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'activityId': activityId,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a [ChatModel] instance from Firestore map.
  factory ChatModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final participants =
        (map['participantIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final names =
        (map['participantNames'] as Map<dynamic, dynamic>?)?.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ) ??
        {};

    return ChatModel(
      id: docId ?? map['id'] as String? ?? '',
      type: map['type'] as String? ?? 'direct',
      participantIds: participants,
      participantNames: names,
      activityId: map['activityId'] as String?,
      lastMessage: map['lastMessage'] as String?,
      lastMessageAt: parseDateTime(map['lastMessageAt']),
      createdAt: parseDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  /// Returns a copy of [ChatModel] with updated fields.
  ChatModel copyWith({
    String? id,
    String? type,
    List<String>? participantIds,
    Map<String, String>? participantNames,
    String? activityId,
    String? lastMessage,
    DateTime? lastMessageAt,
    DateTime? createdAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      activityId: activityId ?? this.activityId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
