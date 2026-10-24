import 'package:sportify/models/user_model.dart';

/// Compatibility uses only saved interests, area and broad availability slots.
/// It deliberately does not invent distances or reputation scores.
class MatchingService {
  static String timeLabel(String overlap) {
    const days = {
      'mon': 'Mon',
      'tue': 'Tue',
      'wed': 'Wed',
      'thu': 'Thu',
      'fri': 'Fri',
      'sat': 'Sat',
      'sun': 'Sun',
    };
    const slots = {
      'morning': 'Morning',
      'afternoon': 'Afternoon',
      'evening': 'Evening',
    };
    final parts = overlap.split(' ');
    return '${days[parts.first] ?? parts.first} · ${slots[parts.last] ?? parts.last}';
  }

  static String sportName(Map<String, dynamic> sport) =>
      (sport['sport'] ?? sport['name'] ?? '').toString();

  static List<String> overlaps(UserModel a, UserModel b) => [
    for (final day in a.availability.keys)
      for (final slot in a.availability[day]!.toSet())
        if (b.availability[day]?.contains(slot) ?? false) '$day $slot',
  ];

  static int score(UserModel a, UserModel b) {
    final interests = a.sports.map(sportName).toSet();
    final common = b.sports
        .where((s) => interests.contains(sportName(s)))
        .toList();
    if (common.isEmpty) return 0;
    final total = a.availability.values.fold<int>(
      0,
      (n, slots) => n + slots.toSet().length,
    );
    final time = total == 0 ? 0.0 : overlaps(a, b).length / total;
    final sameSkill = common.any(
      (s) => a.sports.any(
        (mine) =>
            sportName(mine) == sportName(s) &&
            mine['skillLevel'] == s['skillLevel'],
      ),
    );
    return (40 * time +
            35 * common.length / interests.length +
            (a.area.isNotEmpty && a.area == b.area ? 15 : 0) +
            (sameSkill ? 10 : 0))
        .round()
        .clamp(0, 100);
  }
}
