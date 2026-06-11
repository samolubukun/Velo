import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/transaction_record.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/number_formatter.dart';

/// A premium transaction tile used across the Velo app.
class TransactionCard extends StatelessWidget {
  final TransactionRecord transaction;
  final String categoryName;
  final String accountName;
  final bool isPrivate;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.categoryName,
    required this.accountName,
    this.isPrivate = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isExpense = transaction.type == TransactionType.expense;
    final isTransfer = transaction.type == TransactionType.transfer;
    final valueColor = isExpense
        ? AppColors.error
        : isTransfer
            ? AppColors.brand
            : AppColors.success;
    final prefix = isExpense ? '-' : isTransfer ? '⇄' : '+';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border, width: 0.5),
        ),
        child: Row(
          children: [
            // Icon badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: valueColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconFor(transaction.type), color: valueColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Title + category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: AppTextStyles.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        categoryName,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: colors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Text('·',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: colors.textTertiary)),
                      const SizedBox(width: 6),
                      Text(
                        accountName,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: colors.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount + date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isPrivate
                      ? '••••'
                      : '$prefix\$${NumberFormatter.formatDouble(transaction.value.abs())}',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.date),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),

            if (onDelete != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close_rounded,
                    size: 16, color: colors.textTertiary),
              ),
            ],
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  IconData _iconFor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.add_circle_outline_rounded;
      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
      case TransactionType.expense:
        return Icons.remove_circle_outline_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    }
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

/// A budget progress bar widget for the Analytics screen.
class BudgetProgressTile extends StatelessWidget {
  final String title;
  final double current;
  final double limit;
  final bool isPrivate;

  const BudgetProgressTile({
    super.key,
    required this.title,
    required this.current,
    required this.limit,
    this.isPrivate = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final pct = limit > 0 ? (current / limit).clamp(0.0, 1.0) : 0.0;
    final Color barColor = pct >= 1.0
        ? AppColors.error
        : pct >= 0.8
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(title, style: AppTextStyles.labelMedium)),
              Text(
                isPrivate
                    ? '••••'
                    : '\$${NumberFormatter.formatInt(current)} / \$${NumberFormatter.formatInt(limit)}',
                style:
                    AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: colors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
