import 'package:cloud_firestore/cloud_firestore.dart';

class GameJoinRequestModel {
  final String id;
  final String activityId;
  final String requesterId;
  final String requesterName;
  final String hostId;
  final String status;
  final DateTime createdAt;

  const GameJoinRequestModel({
    required this.id,
    required this.activityId,
    required this.requesterId,
    required this.requesterName,
    required this.hostId,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'activityId': activityId,
    'requesterId': requesterId,
    'requesterName': requesterName,
    'hostId': hostId,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory GameJoinRequestModel.fromMap(Map<String, dynamic> map, String id) =>
      GameJoinRequestModel(
        id: id,
        activityId: map['activityId'] as String? ?? '',
        requesterId: map['requesterId'] as String? ?? '',
        requesterName: map['requesterName'] as String? ?? 'Player',
        hostId: map['hostId'] as String? ?? '',
        status: map['status'] as String? ?? 'pending',
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
}
