import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile model for Sportify.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? bio;
  final String city;
  final String area;
  final List<Map<String, dynamic>> sports;
  final Map<String, List<String>> availability;
  final DateTime createdAt;
  final bool isProfileComplete;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.bio,
    this.city = 'Hyderabad',
    this.area = '',
    this.sports = const [],
    this.availability = const {},
    required this.createdAt,
    this.isProfileComplete = false,
  });

  /// Converts [UserModel] instance into a Map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'city': city,
      'area': area,
      'sports': sports,
      'availability': availability,
      'createdAt': Timestamp.fromDate(createdAt),
      'isProfileComplete': isProfileComplete,
    };
  }

  /// Creates a [UserModel] instance from Firestore document map and user id.
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    // Parse sports
    List<Map<String, dynamic>> parsedSports = [];
    if (map['sports'] != null && map['sports'] is List) {
      parsedSports = (map['sports'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    // Parse availability
    Map<String, List<String>> parsedAvailability = {};
    if (map['availability'] != null && map['availability'] is Map) {
      final availMap = map['availability'] as Map;
      availMap.forEach((key, value) {
        if (value is List) {
          parsedAvailability[key.toString()] = value
              .map((e) => e.toString())
              .toList();
        }
      });
    }

    // Parse createdAt
    DateTime parsedCreatedAt;
    if (map['createdAt'] is Timestamp) {
      parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      parsedCreatedAt =
          DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String?,
      city: map['city'] as String? ?? 'Hyderabad',
      area: map['area'] as String? ?? '',
      sports: parsedSports,
      availability: parsedAvailability,
      createdAt: parsedCreatedAt,
      isProfileComplete: map['isProfileComplete'] as bool? ?? false,
    );
  }

  /// Returns a copy of [UserModel] with updated fields.
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    String? bio,
    String? city,
    String? area,
    List<Map<String, dynamic>>? sports,
    Map<String, List<String>>? availability,
    DateTime? createdAt,
    bool? isProfileComplete,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      area: area ?? this.area,
      sports: sports ?? this.sports,
      availability: availability ?? this.availability,
      createdAt: createdAt ?? this.createdAt,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }
}
