import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

class CategoryBar extends StatelessWidget {
  final String category;
  final int amount;
  final double barWidth;
  final VoidCallback? onTap;

  const CategoryBar({
    super.key,
    required this.category,
    required this.amount,
    required this.barWidth,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category,
              style: const TextStyle(fontSize: 14),
            ),
            Row(
              children: [
                Container(
                  width: barWidth,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.accent300,
                    border: Border.all(color: AppColors.accent600, width: 1),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 88,
                  child: Text(
                    CurrencyFormatter.formatWithRp(amount),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
