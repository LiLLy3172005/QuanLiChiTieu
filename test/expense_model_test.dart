import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/expense_item.dart';

void main() {
  group('ExpenseItem & Category Unit Tests (Dart 3 Features)', () {
    test('1. Kiểm thử Switch Expressions trên ExpenseCategoryExt', () {
      expect(ExpenseCategory.food.vietnameseName, equals('Ăn uống'));
      expect(ExpenseCategory.transport.vietnameseName, equals('Di chuyển'));
      expect(ExpenseCategory.shopping.vietnameseName, equals('Mua sắm'));
      expect(ExpenseCategory.utilities.vietnameseName, equals('Hóa đơn & Điện nước'));
    });

    test('2. Chuyển đổi qua lại giữa ExpenseItem và Map SQLite', () {
      final now = DateTime(2026, 10, 12, 10, 30);
      final item = ExpenseItem(
        id: 'test_123',
        title: 'Cà phê muối VKU',
        amount: 25000.0,
        timestamp: now,
        category: ExpenseCategory.food,
        rawOcrText: 'Ca phe muoi 25.000',
      );

      final map = item.toMap();
      expect(map['id'], equals('test_123'));
      expect(map['title'], equals('Cà phê muối VKU'));
      expect(map['amount'], equals(25000.0));
      expect(map['category'], equals('food'));

      // Phục hồi từ Map
      final restored = ExpenseItem.fromMap(map);
      expect(restored.id, equals(item.id));
      expect(restored.title, equals(item.title));
      expect(restored.amount, equals(item.amount));
      expect(restored.category, equals(ExpenseCategory.food));
    });

    test('3. Immutability copyWith method', () {
      final item = ExpenseItem.draft(
        title: 'Trà sữa',
        amount: 30000.0,
      );

      final updated = item.copyWith(amount: 35000.0);
      expect(updated.title, equals('Trà sữa'));
      expect(updated.amount, equals(35000.0));
      expect(item.amount, equals(30000.0)); // Bản gốc không đổi
    });
  });
}
