import 'package:flutter/material.dart';

/// Application constants for Sportify.
class AppConstants {
  AppConstants._();

  /// Supported sports list with respective icons.
  static const List<Map<String, dynamic>> sports = [
    {'name': 'Cricket', 'icon': Icons.sports_cricket},
    {'name': 'Football', 'icon': Icons.sports_soccer},
    {'name': 'Badminton', 'icon': Icons.sports_tennis},
    {'name': 'Basketball', 'icon': Icons.sports_basketball},
    {'name': 'Tennis', 'icon': Icons.sports_tennis},
    {'name': 'Table Tennis', 'icon': Icons.table_bar},
    {'name': 'Gym/Fitness', 'icon': Icons.fitness_center},
    {'name': 'Running', 'icon': Icons.directions_run},
    {'name': 'Swimming', 'icon': Icons.pool},
    {'name': 'Volleyball', 'icon': Icons.sports_volleyball},
  ];

  /// List of major localities and areas in Hyderabad, Pakistan.
  static const List<String> hyderabadAreas = [
    'Latifabad',
    'Qasimabad',
    'Auto Bahn Road',
    'Bypass',
    'Heerabad',
    'Market',
    'Hussainabad',
    'Phuleli',
    'Cantonment',
    'Tilak Incline',
    'City Gate',
    'Jamshoro Road',
    'Sindh University',
    'MUET',
    'Naseem Nagar',
    'GOR Colony',
    'Gulistan-e-Sajjad',
    'Saddar',
    'Hirabad',
    'Fateh Chowk',
    'Pakka Qila',
    'Civil Hospital Area',
  ];

  /// Skill levels for players.
  static const List<String> skillLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  /// Available daily time slots for activities and availability.
  static const List<Map<String, String>> timeSlots = [
    {'key': 'morning', 'label': 'Morning', 'time': '6 AM - 12 PM'},
    {'key': 'afternoon', 'label': 'Afternoon', 'time': '12 PM - 5 PM'},
    {'key': 'evening', 'label': 'Evening', 'time': '5 PM - 10 PM'},
  ];

  /// Days of the week definitions.
  static const List<Map<String, String>> daysOfWeek = [
    {'key': 'mon', 'label': 'Mon'},
    {'key': 'tue', 'label': 'Tue'},
    {'key': 'wed', 'label': 'Wed'},
    {'key': 'thu', 'label': 'Thu'},
    {'key': 'fri', 'label': 'Fri'},
    {'key': 'sat', 'label': 'Sat'},
    {'key': 'sun', 'label': 'Sun'},
  ];
}
