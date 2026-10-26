import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense_item.dart';

/// In-Class Lab Exercise: Expense & Income Summary Card (Slide 45 VKU)
/// Hiển thị trực quan giao dịch Thu nhập (+) và Chi tiêu (-)
class ExpenseSummaryCard extends StatelessWidget {
  final String merchant;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final TransactionType type;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ExpenseSummaryCard({
    super.key,
    required this.merchant,
    required this.amount,
    required this.date,
    this.category = ExpenseCategory.other,
    this.type = TransactionType.expense,
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
    final isIncome = type == TransactionType.income;

    // Wrap inside a Material 3 Card with elevation and ink ripple InkWell tap callback (Slide 45)
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
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
                  color: isIncome
                      ? Colors.green.withOpacity(0.15)
                      : category.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category.icon,
                  color: isIncome ? Colors.green.shade700 : category.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // 2. Store name and date stacked vertically with CrossAxisAlignment.start
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            merchant,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isIncome
                                ? Colors.green.withOpacity(0.12)
                                : Colors.red.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isIncome ? 'Thu' : 'Chi',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isIncome ? Colors.green.shade800 : Colors.red.shade800,
                            ),
                          ),
                        ),
                      ],
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
                    '${isIncome ? '+' : '-'} ${currencyFormatter.format(amount)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
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
