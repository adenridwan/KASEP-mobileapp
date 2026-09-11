import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/transaction.dart';

class TransactionRow extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final bool showDate;

  const TransactionRow({
    super.key,
    required this.transaction,
    this.onTap,
    this.showDate = false,
  });

  String _buildSubtitle() {
    final parts = <String>[transaction.category];

    // Add fund source info
    if (transaction.fundSource != null) {
      if (transaction.isIncome) {
        // For income: "ke [fund source]" (goes to)
        parts.add('ke ${transaction.fundSource}');
      } else {
        // For expense: "dari [fund source]" (from)
        parts.add('dari ${transaction.fundSource}');
      }
    }

    parts.add(transaction.formattedTime);
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: transaction.isIncome
                    ? AppColors.accent100
                    : AppColors.lavender,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                transaction.isIncome
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                size: 19,
                color: transaction.isIncome
                    ? AppColors.accent700
                    : AppColors.neutral700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _buildSubtitle(),
                    style: TextStyle(
                      fontSize: 11,
                      color: transaction.isIncome
                          ? AppColors.accent700
                          : AppColors.neutral700,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.formatWithSign(
                transaction.amount,
                isIncome: transaction.isIncome,
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: transaction.isIncome ? AppColors.accent700 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
