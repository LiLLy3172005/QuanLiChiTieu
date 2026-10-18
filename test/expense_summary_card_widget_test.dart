import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/expense_item.dart';
import 'package:vku_expense_ocr/views/widgets/expense_summary_card.dart';

void main() {
  testWidgets('ExpenseSummaryCard hiển thị đúng thông tin và định dạng tiền tệ', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseSummaryCard(
            merchant: 'Highlands Coffee VKU',
            amount: 55000.0,
            date: DateTime(2026, 10, 12, 9, 0),
            category: ExpenseCategory.food,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    // Kiểm tra hiển thị tên quán
    expect(find.text('Highlands Coffee VKU'), findsOneWidget);

    // Kiểm tra hiển thị số tiền có biểu tượng đ
    expect(find.textContaining('55.000'), findsOneWidget);

    // Kiểm tra tên danh mục tiếng Việt
    expect(find.text('Ăn uống'), findsOneWidget);

    // Kiểm tra tap callback InkWell
    await tester.tap(find.byType(InkWell));
    expect(tapped, isTrue);
  });
}
