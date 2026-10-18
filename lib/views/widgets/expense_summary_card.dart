import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense_item.dart';

/// In-Class Lab Exercise: Expense Summary Card (Theo đúng đặc tả Slide 45 VKU)
/// Yêu cầu:
/// 1. An icon inside a circular container indicating category.
/// 2. Store name and date stacked vertically with CrossAxisAlignment.start.
/// 3. Highlighted monetary amount formatted as Vietnamese Dong (###.### đ).
/// 4. Wrap inside a Material 3 Card with elevation and ink ripple InkWell tap callback.
class ExpenseSummaryCard extends StatelessWidget {
  final String merchant;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ExpenseSummaryCard({
    super.key,
    required this.merchant,
    required this.amount,
    required this.date,
    this.category = ExpenseCategory.other,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    // 4. Wrap inside a Material 3 Card with elevation and ink ripple InkWell tap callback
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias, // Cho phép hiệu ứng Ink ripple tràn đều viền bo góc
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              // 1. An icon inside a circular container indicating category
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // 2. Store name and date stacked vertically with CrossAxisAlignment.start
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormatter.format(date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // 3. Highlighted monetary amount formatted as Vietnamese Dong (###.### đ)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormatter.format(amount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category.vietnameseName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: category.color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
