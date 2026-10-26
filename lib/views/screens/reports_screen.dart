import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/expense_item.dart';
import '../../providers/expense_provider.dart';
import '../widgets/donut_chart_painter.dart';
import '../widgets/weekly_bar_chart_painter.dart';

/// Màn hình Báo cáo và Trực quan hóa Biểu đồ CustomPainter (Slide 29-34 VKU Week 8)
/// Hỗ trợ chuyển đổi linh hoạt giữa Biểu đồ Chi tiêu và Biểu đồ Thu nhập
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _chartTypeIndex = 0; // 0: Chi tiêu (-), 1: Thu nhập (+)

  @override
  Widget build(BuildContext context) {
    final expenseCategoryData = ref.watch(categoryBreakdownProvider);
    final incomeCategoryData = ref.watch(incomeCategoryBreakdownProvider);
    final weeklyData = ref.watch(weeklyExpensesProvider);

    final totalSpent = ref.watch(totalExpenseAmountProvider);
    final totalIncome = ref.watch(totalIncomeProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    final isIncomeMode = _chartTypeIndex == 1;
    final currentCategoryData = isIncomeMode ? incomeCategoryData : expenseCategoryData;
    final currentTotal = isIncomeMode ? totalIncome : totalSpent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo Cáo Tài Chính'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh chuyển đổi Chế độ xem biểu đồ Donut: Chi tiêu vs Thu nhập
            Center(
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Tỷ trọng Chi tiêu'),
                    icon: Icon(Icons.pie_chart, color: Colors.red),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Tỷ trọng Thu nhập'),
                    icon: Icon(Icons.donut_large, color: Colors.green),
                  ),
                ],
                selected: {_chartTypeIndex},
                onSelectionChanged: (set) {
                  setState(() => _chartTypeIndex = set.first);
                },
              ),
            ),
            const SizedBox(height: 16),

            // 1. Khối Biểu đồ Donut Chart CustomPainter (Slide 33 & 34 VKU)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      isIncomeMode
                          ? 'Cơ cấu nguồn Thu nhập'
                          : 'Tỷ trọng Chi tiêu theo danh mục',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedDonutChart(
                      data: currentCategoryData,
                      totalAmount: currentTotal,
                    ),
                    const SizedBox(height: 20),

                    // Chú thích (Legend)
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: ExpenseCategory.values.map((cat) {
                        final amt = currentCategoryData[cat] ?? 0.0;
                        if (amt <= 0 && currentTotal > 0) return const SizedBox.shrink();
                        final percent = currentTotal > 0 ? (amt / currentTotal * 100).toStringAsFixed(1) : '0';

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

            // 2. Khối Biểu đồ Cột Weekly Bar Chart (Biến động chi tiêu 7 ngày)
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
                      'Thống kê chu kỳ từng ngày trong tuần bằng CustomPainter (Skia/Impeller Canvas)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
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
                      isIncomeMode ? 'Chi tiết các nguồn thu' : 'Chi tiết các khoản chi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 10),
                    ...ExpenseCategory.values.map((cat) {
                      final amount = currentCategoryData[cat] ?? 0.0;
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isIncomeMode ? Colors.green.shade700 : Colors.red.shade700,
                          ),
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
