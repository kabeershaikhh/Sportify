import 'package:flutter/material.dart';
import 'package:sportify/config/theme.dart';

class SportChip extends StatelessWidget {
  final String sportName;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const SportChip({
    super.key,
    required this.sportName,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(sportName),
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : AppColors.primary,
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.lavender,
      surfaceTintColor: Colors.transparent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.primaryDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      showCheckmark: false,
    );
  }
}
