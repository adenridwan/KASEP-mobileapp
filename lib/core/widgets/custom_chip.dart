import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isSmall;

  const CustomChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 11 : 13,
          vertical: isSmall ? 5 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent100 : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isSmall ? 11 : 13,
            color: isSelected ? AppColors.accent700 :
                   isSmall ? AppColors.neutral700 : AppColors.text,
          ),
        ),
      ),
    );
  }
}
