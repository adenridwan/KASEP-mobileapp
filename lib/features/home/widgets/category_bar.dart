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
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  CurrencyFormatter.formatWithRp(amount),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Container(
                    width: (constraints.maxWidth * (barWidth / 100)).clamp(
                      10.0,
                      constraints.maxWidth,
                    ),
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.accent300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
