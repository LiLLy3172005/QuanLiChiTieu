import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/expense_item.dart';
import 'package:vku_expense_ocr/services/regex_parser_engine.dart';

void main() {
  group('RegexParserEngine Unit Tests - Bóc tách hóa đơn & SMS', () {
    test('1. Bóc tách hóa đơn Highlands Coffee thành công', () {
      const rawText = '''
        HIGHLANDS COFFEE
        Dia chi: 234 Nguyen Van Linh, Da Nang
        Ngay: 22/10/2026 08:30
        1. Ca phe sua da     39,000
        2. Banh mi que       26,000
        Tong cong: 65.000 VND
        Tien mat: 100.000
        Tien thua: 35.000
      ''';

      final result = RegexParserEngine.parse(rawText);

      // Kiểm tra tên nơi bán
      expect(result.merchant.toUpperCase(), contains('HIGHLANDS COFFEE'));
      // Kiểm tra tổng tiền
      expect(result.total, equals(65000.0));
      // Kiểm tra ngày tháng
      expect(result.date.day, equals(22));
      expect(result.date.month, equals(10));
      expect(result.date.year, equals(2026));
      // Kiểm tra phân loại ngành hàng
      expect(result.category, equals(ExpenseCategory.food));
    });

    test('2. Bóc tách tin nhắn biến động số dư ngân hàng Vietcombank', () {
      const smsText = '''
        SD: -120,000VND vao 15/10/2026.
        ND: Co.op Mart Da Nang thanh toan don hang.
        So du kha dung: 5,450,000VND.
      ''';

      final result = RegexParserEngine.parse(smsText);

      expect(result.total, equals(120000.0));
      expect(result.date.day, equals(15));
      expect(result.date.month, equals(10));
      expect(result.date.year, equals(2026));
      expect(result.category, equals(ExpenseCategory.shopping));
    });

    test('3. Bóc tách hóa đơn đổ xăng Petrolimex (Danh mục di chuyển)', () {
      const receipt = '''
        PETROLIMEX CUA HANG SO 12
        Ngay ban: 10/10/2026
        Xang RON 95-III: 70.000 đ
        Tong thanh toan: 70.000 đ
      ''';

      final result = RegexParserEngine.parse(receipt);

      expect(result.total, equals(70000.0));
      expect(result.category, equals(ExpenseCategory.transport));
    });

    test('4. Xử lý an toàn khi chuỗi OCR rỗng hoặc nhiễu ký tự', () {
      const dirtyText = '';
      final result = RegexParserEngine.parse(dirtyText);

      expect(result.total, equals(0.0));
      expect(result.merchant, equals('Không xác định'));
      expect(result.category, equals(ExpenseCategory.other));
    });
  });
}
