import 'package:flutter/material.dart';

/// Loại giao dịch: Tiền chi (Expense) hoặc Tiền thu (Income)
enum TransactionType {
  expense, // Tiền chi (-)
  income,  // Tiền thu (+)
}

/// Extension mở rộng cho TransactionType bằng Dart 3 Switch Expression
extension TransactionTypeExt on TransactionType {
  String get vietnameseName => switch (this) {
        TransactionType.expense => 'Khoản chi',
        TransactionType.income => 'Khoản thu',
      };

  Color get color => switch (this) {
        TransactionType.expense => Colors.red.shade600,
        TransactionType.income => Colors.green.shade600,
      };

  IconData get icon => switch (this) {
        TransactionType.expense => Icons.arrow_downward,
        TransactionType.income => Icons.arrow_upward,
      };

  static TransactionType fromString(String? name) {
    return TransactionType.values.firstWhere(
      (e) => e.name.toLowerCase() == (name ?? '').toLowerCase(),
      orElse: () => TransactionType.expense,
    );
  }
}

/// Enum phân loại các hạng mục chi tiêu & thu nhập (Slide 14 VKU).
enum ExpenseCategory {
  // Nhóm Chi tiêu (Expense)
  food, // Ăn uống
  transport, // Đi lại
  shopping, // Mua sắm
  utilities, // Hóa đơn & Tiện ích
  entertainment, // Giải trí

  // Nhóm Thu nhập (Income)
  salary, // Lương
  bonus, // Thưởng & Hoa hồng
  allowance, // Trợ cấp / Ba mẹ cho
  selling, // Bán hàng / Thanh lý
  refund, // Hoàn tiền

  other, // Khác
}

/// Extension mở rộng cho ExpenseCategory bằng Dart 3 Switch Expression
extension ExpenseCategoryExt on ExpenseCategory {
  String get vietnameseName => switch (this) {
        ExpenseCategory.food => 'Ăn uống',
        ExpenseCategory.transport => 'Di chuyển',
        ExpenseCategory.shopping => 'Mua sắm',
        ExpenseCategory.utilities => 'Hóa đơn & Điện nước',
        ExpenseCategory.entertainment => 'Giải trí',
        ExpenseCategory.salary => 'Lương',
        ExpenseCategory.bonus => 'Thưởng & Tiền tip',
        ExpenseCategory.allowance => 'Trợ cấp / Ba mẹ gửi',
        ExpenseCategory.selling => 'Bán hàng / Kinh doanh',
        ExpenseCategory.refund => 'Hoàn tiền',
        ExpenseCategory.other => 'Khác',
      };

  Color get color => switch (this) {
        ExpenseCategory.food => Colors.orange,
        ExpenseCategory.transport => Colors.blue,
        ExpenseCategory.shopping => Colors.purple,
        ExpenseCategory.utilities => Colors.teal,
        ExpenseCategory.entertainment => Colors.pinkAccent,
        ExpenseCategory.salary => Colors.green.shade700,
        ExpenseCategory.bonus => Colors.amber.shade800,
        ExpenseCategory.allowance => Colors.cyan.shade700,
        ExpenseCategory.selling => Colors.indigo,
        ExpenseCategory.refund => Colors.lightGreen.shade700,
        ExpenseCategory.other => Colors.blueGrey,
      };

  IconData get icon => switch (this) {
        ExpenseCategory.food => Icons.restaurant,
        ExpenseCategory.transport => Icons.directions_car,
        ExpenseCategory.shopping => Icons.shopping_bag,
        ExpenseCategory.utilities => Icons.receipt_long,
        ExpenseCategory.entertainment => Icons.movie,
        ExpenseCategory.salary => Icons.account_balance_wallet,
        ExpenseCategory.bonus => Icons.stars,
        ExpenseCategory.allowance => Icons.volunteer_activism,
        ExpenseCategory.selling => Icons.storefront,
        ExpenseCategory.refund => Icons.replay,
        ExpenseCategory.other => Icons.category,
      };

  bool get isIncomeCategory => switch (this) {
        ExpenseCategory.salary ||
        ExpenseCategory.bonus ||
        ExpenseCategory.allowance ||
        ExpenseCategory.selling ||
        ExpenseCategory.refund =>
          true,
        _ => false,
      };

  static ExpenseCategory fromString(String? name) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == (name ?? '').toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }
}

/// Model giao dịch chi tiêu & thu nhập theo đặc tả VKU Slide 15 & Slide 42.
class ExpenseItem {
  final String id;
  final String title; // Tên cửa hàng, đối tác hoặc nội dung giao dịch
  final double amount; // Số tiền (VNĐ)
  final DateTime timestamp; // Thời gian phát sinh giao dịch
  final ExpenseCategory category; // Phân loại danh mục
  final TransactionType type; // Tiền chi (expense) hoặc Tiền thu (income)
  final String? imagePath; // Đường dẫn ảnh hóa đơn / bằng chứng chuyển khoản
  final String? rawOcrText; // Nội dung văn bản OCR gốc

  const ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.timestamp,
    this.category = ExpenseCategory.other,
    this.type = TransactionType.expense,
    this.imagePath,
    this.rawOcrText,
  });

  /// Named constructor dạng draft khởi tạo nhanh khi vừa scan hóa đơn / SMS
  ExpenseItem.draft({
    required this.title,
    required this.amount,
    this.category = ExpenseCategory.other,
    this.type = TransactionType.expense,
    this.imagePath,
    this.rawOcrText,
  })  : id = 'tx_${DateTime.now().millisecondsSinceEpoch}',
        timestamp = DateTime.now();

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  /// Chuyển đối tượng thành Map để lưu vào SQLite (sqflite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'category': category.name,
      'type': type.name,
      'image_path': imagePath,
      'raw_ocr_text': rawOcrText,
    };
  }

  /// Khôi phục đối tượng từ SQLite record
  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      category: ExpenseCategoryExt.fromString(map['category'] as String?),
      type: TransactionTypeExt.fromString(map['type'] as String?),
      imagePath: map['image_path'] as String?,
      rawOcrText: map['raw_ocr_text'] as String?,
    );
  }

  /// Tạo bản sao có cập nhật trường (Immutability pattern)
  ExpenseItem copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? timestamp,
    ExpenseCategory? category,
    TransactionType? type,
    String? imagePath,
    String? rawOcrText,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      type: type ?? this.type,
      imagePath: imagePath ?? this.imagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
    );
  }
}
