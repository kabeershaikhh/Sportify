import 'package:cloud_firestore/cloud_firestore.dart';

/// Sports venue model for Sportify.
class VenueModel {
  final String id;
  final String name;
  final String address;
  final String area;
  final List<String> sports;
  final String? priceRange;
  final String status; // 'pending', 'approved'
  final String? suggestedBy;
  final DateTime createdAt;

  VenueModel({
    required this.id,
    required this.name,
    required this.address,
    required this.area,
    this.sports = const [],
    this.priceRange,
    this.status = 'pending',
    this.suggestedBy,
    required this.createdAt,
  });

  /// Converts [VenueModel] instance into a Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'area': area,
      'sports': sports,
      'priceRange': priceRange,
      'status': status,
      'suggestedBy': suggestedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a [VenueModel] instance from Firestore map.
  factory VenueModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final sportsList =
        (map['sports'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [];

    return VenueModel(
      id: docId ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      area: map['area'] as String? ?? '',
      sports: sportsList,
      priceRange: map['priceRange'] as String?,
      status: map['status'] as String? ?? 'pending',
      suggestedBy: map['suggestedBy'] as String?,
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  /// Returns a copy of [VenueModel] with updated fields.
  VenueModel copyWith({
    String? id,
    String? name,
    String? address,
    String? area,
    List<String>? sports,
    String? priceRange,
    String? status,
    String? suggestedBy,
    DateTime? createdAt,
  }) {
    return VenueModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      area: area ?? this.area,
      sports: sports ?? this.sports,
      priceRange: priceRange ?? this.priceRange,
      status: status ?? this.status,
      suggestedBy: suggestedBy ?? this.suggestedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
