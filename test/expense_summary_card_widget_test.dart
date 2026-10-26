import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/expense_item.dart';
import 'package:vku_expense_ocr/views/widgets/expense_summary_card.dart';

void main() {
  testWidgets('ExpenseSummaryCard hiển thị đúng thông tin Tiền Chi (-) và ink ripple', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseSummaryCard(
            merchant: 'Highlands Coffee VKU',
            amount: 55000.0,
            date: DateTime(2026, 10, 12, 9, 0),
            category: ExpenseCategory.food,
            type: TransactionType.expense,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Highlands Coffee VKU'), findsOneWidget);
    expect(find.textContaining('- 55.000'), findsOneWidget);
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Chi'), findsOneWidget);

    await tester.tap(find.byType(InkWell));
    expect(tapped, isTrue);
  });

  testWidgets('ExpenseSummaryCard hiển thị đúng thông tin Tiền Thu (+) màu xanh', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseSummaryCard(
            merchant: 'Lương thực tập VKU',
            amount: 2000000.0,
            date: DateTime(2026, 10, 15, 10, 0),
            category: ExpenseCategory.salary,
            type: TransactionType.income,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Lương thực tập VKU'), findsOneWidget);
    expect(find.textContaining('+ 2.000.000'), findsOneWidget);
    expect(find.text('Lương'), findsOneWidget);
    expect(find.text('Thu'), findsOneWidget);
  });
}
