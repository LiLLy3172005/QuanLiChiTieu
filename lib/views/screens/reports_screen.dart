import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/expense_item.dart';
import '../../providers/expense_provider.dart';
import '../widgets/donut_chart_painter.dart';
import '../widgets/weekly_bar_chart_painter.dart';

/// Màn hình Báo cáo và Trực quan hóa Biểu đồ (Slide 42: Custom Canvas Visualization)
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryData = ref.watch(categoryBreakdownProvider);
    final weeklyData = ref.watch(weeklyExpensesProvider);
    final totalSpent = ref.watch(totalExpenseAmountProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo Cáo Chi Tiêu'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Khối Biểu đồ Donut Chart theo Danh mục
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Tỷ trọng chi tiêu theo danh mục',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // Widget CustomPainter Donut
                    AnimatedDonutChart(
                      data: categoryData,
                      totalAmount: totalSpent,
                    ),
                    const SizedBox(height: 20),

                    // Danh sách chú thích (Legend)
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: ExpenseCategory.values.map((cat) {
                        final amt = categoryData[cat] ?? 0.0;
                        if (amt <= 0 && totalSpent > 0) return const SizedBox.shrink();
                        final percent = totalSpent > 0 ? (amt / totalSpent * 100).toStringAsFixed(1) : '0';

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: cat.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${cat.vietnameseName} ($percent%)',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. Khối Biểu đồ Cột Weekly Bar Chart
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biến động chi tiêu 7 ngày qua',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thống kê theo chu kỳ từng ngày trong tuần',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    // Widget CustomPainter Bar Chart
                    AnimatedWeeklyBarChart(dailyExpenses: weeklyData),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3. Danh sách chi tiết số tiền theo từng danh mục
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chi tiết theo nhóm',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 10),
                    ...ExpenseCategory.values.map((cat) {
                      final amount = categoryData[cat] ?? 0.0;
                      if (amount <= 0) return const SizedBox.shrink();
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: cat.color.withOpacity(0.15),
                          child: Icon(cat.icon, color: cat.color, size: 18),
                        ),
                        title: Text(cat.vietnameseName),
                        trailing: Text(
                          currencyFormatter.format(amount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
