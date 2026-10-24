import 'package:cloud_firestore/cloud_firestore.dart';

/// Activity/Match listing model for Sportify.
class ActivityModel {
  final String id;
  final String hostId;
  final String hostName;
  final String? hostPhotoUrl;
  final String sport;
  final String skillLevel;
  final String area;
  final DateTime dateTime;
  final String venue;
  final String? venueAddress;
  final int playersNeeded;
  final String? description;
  final String status; // 'open', 'full', 'cancelled'
  final List<String> participantIds;
  final DateTime createdAt;

  ActivityModel({
    required this.id,
    required this.hostId,
    required this.hostName,
    this.hostPhotoUrl,
    required this.sport,
    required this.skillLevel,
    required this.area,
    required this.dateTime,
    required this.venue,
    this.venueAddress,
    required this.playersNeeded,
    this.description,
    this.status = 'open',
    this.participantIds = const [],
    required this.createdAt,
  });

  /// Computed getter to check if activity is at max capacity.
  bool get isFull => participantIds.length >= playersNeeded;

  /// Computed getter to find remaining player slots available.
  int get spotsLeft => (playersNeeded - participantIds.length).clamp(
    0,
    playersNeeded < 0 ? 0 : playersNeeded,
  );

  /// Converts [ActivityModel] instance to Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hostId': hostId,
      'hostName': hostName,
      'hostPhotoUrl': hostPhotoUrl,
      'sport': sport,
      'skillLevel': skillLevel,
      'area': area,
      'dateTime': Timestamp.fromDate(dateTime),
      'venue': venue,
      'venueAddress': venueAddress,
      'playersNeeded': playersNeeded,
      'description': description,
      'status': status,
      'participantIds': participantIds,
      'lastApprovedJoinRequestId': null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates an [ActivityModel] instance from Firestore map.
  factory ActivityModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final participants =
        (map['participantIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return ActivityModel(
      id: docId ?? map['id'] as String? ?? '',
      hostId: map['hostId'] as String? ?? '',
      hostName: map['hostName'] as String? ?? '',
      hostPhotoUrl: map['hostPhotoUrl'] as String?,
      sport: map['sport'] as String? ?? '',
      skillLevel: map['skillLevel'] as String? ?? 'Beginner',
      area: map['area'] as String? ?? '',
      dateTime: parseDateTime(map['dateTime']),
      venue: map['venue'] as String? ?? '',
      venueAddress: map['venueAddress'] as String?,
      playersNeeded: (map['playersNeeded'] as num?)?.toInt() ?? 1,
      description: map['description'] as String?,
      status: map['status'] as String? ?? 'open',
      participantIds: participants,
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  /// Returns a copy of [ActivityModel] with updated fields.
  ActivityModel copyWith({
    String? id,
    String? hostId,
    String? hostName,
    String? hostPhotoUrl,
    String? sport,
    String? skillLevel,
    String? area,
    DateTime? dateTime,
    String? venue,
    String? venueAddress,
    int? playersNeeded,
    String? description,
    String? status,
    List<String>? participantIds,
    DateTime? createdAt,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostPhotoUrl: hostPhotoUrl ?? this.hostPhotoUrl,
      sport: sport ?? this.sport,
      skillLevel: skillLevel ?? this.skillLevel,
      area: area ?? this.area,
      dateTime: dateTime ?? this.dateTime,
      venue: venue ?? this.venue,
      venueAddress: venueAddress ?? this.venueAddress,
      playersNeeded: playersNeeded ?? this.playersNeeded,
      description: description ?? this.description,
      status: status ?? this.status,
      participantIds: participantIds ?? this.participantIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
