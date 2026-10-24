import 'package:cloud_firestore/cloud_firestore.dart';

/// Connection/Friend request model for Sportify.
class ConnectionModel {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String? fromUserPhotoUrl;
  final String toUserId;
  final String toUserName;
  final String? toUserPhotoUrl;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime createdAt;

  ConnectionModel({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserPhotoUrl,
    required this.toUserId,
    required this.toUserName,
    this.toUserPhotoUrl,
    this.status = 'pending',
    required this.createdAt,
  });

  /// Converts [ConnectionModel] instance into a Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserPhotoUrl': fromUserPhotoUrl,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'toUserPhotoUrl': toUserPhotoUrl,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a [ConnectionModel] instance from Firestore map.
  factory ConnectionModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return ConnectionModel(
      id: docId ?? map['id'] as String? ?? '',
      fromUserId: map['fromUserId'] as String? ?? '',
      fromUserName: map['fromUserName'] as String? ?? '',
      fromUserPhotoUrl: map['fromUserPhotoUrl'] as String?,
      toUserId: map['toUserId'] as String? ?? '',
      toUserName: map['toUserName'] as String? ?? '',
      toUserPhotoUrl: map['toUserPhotoUrl'] as String?,
      status: map['status'] as String? ?? 'pending',
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  /// Returns a copy of [ConnectionModel] with updated fields.
  ConnectionModel copyWith({
    String? id,
    String? fromUserId,
    String? fromUserName,
    String? fromUserPhotoUrl,
    String? toUserId,
    String? toUserName,
    String? toUserPhotoUrl,
    String? status,
    DateTime? createdAt,
  }) {
    return ConnectionModel(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserPhotoUrl: fromUserPhotoUrl ?? this.fromUserPhotoUrl,
      toUserId: toUserId ?? this.toUserId,
      toUserName: toUserName ?? this.toUserName,
      toUserPhotoUrl: toUserPhotoUrl ?? this.toUserPhotoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
