import 'package:flutter/material.dart';
import 'package:sportify/config/constants.dart';
import 'package:sportify/config/theme.dart';

class AvailabilityGrid extends StatelessWidget {
  final Map<String, List<String>> availability;
  final Function(String day, String slot)? onToggle;
  final bool isEditable;

  const AvailabilityGrid({
    super.key,
    required this.availability,
    this.onToggle,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (!isEditable && constraints.maxWidth < 640) {
        final days = AppConstants.daysOfWeek
            .where((day) => availability[day['key']]?.isNotEmpty ?? false)
            .toList();
        if (days.isEmpty) {
          return const Text('No weekly availability shared yet.');
        }
        return Column(
          children: [
            for (final day in days)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 48,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          day['label']!,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final slot in AppConstants.timeSlots)
                            if (availability[day['key']]!.contains(slot['key']))
                              Chip(
                                avatar: const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                                backgroundColor: AppColors.lavender,
                                label: Text(slot['label']!),
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      }
      final dayWidth = MediaQuery.textScalerOf(context).scale(12) * 3.5;
      final minWidth = 80 + 7 * dayWidth.clamp(44, double.infinity);
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: constraints.maxWidth
              .clamp(minWidth, double.infinity)
              .toDouble(),
          child: _grid(context),
        ),
      );
    },
  );

  Widget _grid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row (Days)
        Row(
          children: [
            const SizedBox(width: 80), // Space for time slot labels
            ...AppConstants.daysOfWeek.map(
              (day) => Expanded(
                child: Text(
                  day['label']!.substring(0, 3), // e.g. Mon
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Rows for Time Slots
        ...AppConstants.timeSlots.map((slot) {
          final slotKey = slot['key']!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    slot['label']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                ...AppConstants.daysOfWeek.map((day) {
                  final dayKey = day['key']!;
                  final isSelected =
                      availability[dayKey]?.contains(slotKey) ?? false;

                  return Expanded(
                    child: Semantics(
                      label: '${day['label']} ${slot['label']}',
                      selected: isSelected,
                      button: isEditable,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: isEditable && onToggle != null
                            ? () => onToggle!(dayKey, slotKey)
                            : null,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.background,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }
}
