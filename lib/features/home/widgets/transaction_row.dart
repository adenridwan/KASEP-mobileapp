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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${transaction.category} · ${transaction.formattedTime}',
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
