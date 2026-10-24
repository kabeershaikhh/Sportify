import 'package:flutter/material.dart';
import 'package:sportify/config/constants.dart';
import 'package:sportify/models/user_model.dart';
import 'package:sportify/services/matching_service.dart';

/// Explains the same saved-profile match score used in partner discovery.
class CompatibilitySummary extends StatelessWidget {
  final UserModel? currentUser;
  final UserModel otherUser;
  final bool compact;

  const CompatibilitySummary({
    super.key,
    required this.currentUser,
    required this.otherUser,
    this.compact = false,
  });

  String _timeLabel(String overlap) {
    final parts = overlap.split(' ');
    final day = AppConstants.daysOfWeek
        .where((entry) => entry['key'] == parts.first)
        .map((entry) => entry['label'])
        .firstOrNull;
    final slot = AppConstants.timeSlots
        .where((entry) => entry['key'] == parts.last)
        .map((entry) => entry['label'])
        .firstOrNull;
    return '${day ?? parts.first} · ${slot ?? parts.last}';
  }

  @override
  Widget build(BuildContext context) {
    final me = currentUser;
    if (me == null) {
      return const Text('Load your profile to see compatibility.');
    }
    final mine = me.sports.map(MatchingService.sportName).toSet();
    final common = otherUser.sports
        .map(MatchingService.sportName)
        .where((sport) => sport.isNotEmpty && mine.contains(sport))
        .toSet();
    final sameSkill = common
        .where(
          (sport) => me.sports.any(
            (a) =>
                MatchingService.sportName(a) == sport &&
                a['skillLevel'] != null &&
                otherUser.sports.any(
                  (b) =>
                      MatchingService.sportName(b) == sport &&
                      b['skillLevel'] == a['skillLevel'],
                ),
          ),
        )
        .toList();
    final overlaps = MatchingService.overlaps(me, otherUser);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${MatchingService.score(me, otherUser)}% compatibility',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          common.isEmpty
              ? 'No shared sports saved'
              : 'Shared sports: ${common.join(', ')}',
        ),
        if (sameSkill.isNotEmpty)
          Text('Matching skill levels: ${sameSkill.join(', ')}'),
        if (me.area.isNotEmpty && me.area == otherUser.area)
          Text('Same area: ${me.area}'),
        const SizedBox(height: 8),
        Text(
          overlaps.isEmpty ? 'No shared time slots saved' : 'Both free:',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (overlaps.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final overlap in (compact ? overlaps.take(3) : overlaps))
                Chip(
                  label: Text(_timeLabel(overlap)),
                  visualDensity: VisualDensity.compact,
                ),
              if (compact && overlaps.length > 3)
                Chip(
                  label: Text('+${overlaps.length - 3} more'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        if (!compact) ...[
          const SizedBox(height: 8),
          const Text(
            'Based on your saved sports, skill levels, area and weekly time slots. These slots are broad availability, not a confirmed game time.',
          ),
        ],
      ],
    );
  }
}
