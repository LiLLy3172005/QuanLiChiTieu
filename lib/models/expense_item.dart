import 'package:flutter/material.dart';

/// Enum phân loại các hạng mục chi tiêu theo quy chuẩn bài giảng VKU Slide 14.
/// Tận dụng tính năng mạnh mẽ của **Dart 3 Switch Expression** để map màu sắc và icon.
enum ExpenseCategory {
  food, // Ăn uống
  transport, // Đi lại
  shopping, // Mua sắm
  utilities, // Hóa đơn & Tiện ích
  entertainment, // Giải trí
  other, // Khác
}

/// Extension mở rộng để lấy tên hiển thị tiếng Việt, icon và màu sắc cho từng danh mục
extension ExpenseCategoryExt on ExpenseCategory {
  String get vietnameseName => switch (this) {
        ExpenseCategory.food => 'Ăn uống',
        ExpenseCategory.transport => 'Di chuyển',
        ExpenseCategory.shopping => 'Mua sắm',
        ExpenseCategory.utilities => 'Hóa đơn & Điện nước',
        ExpenseCategory.entertainment => 'Giải trí',
        ExpenseCategory.other => 'Khác',
      };

  Color get color => switch (this) {
        ExpenseCategory.food => Colors.orange,
        ExpenseCategory.transport => Colors.blue,
        ExpenseCategory.shopping => Colors.purple,
        ExpenseCategory.utilities => Colors.teal,
        ExpenseCategory.entertainment => Colors.pinkAccent,
        ExpenseCategory.other => Colors.blueGrey,
      };

  IconData get icon => switch (this) {
        ExpenseCategory.food => Icons.restaurant,
        ExpenseCategory.transport => Icons.directions_car,
        ExpenseCategory.shopping => Icons.shopping_bag,
        ExpenseCategory.utilities => Icons.receipt_long,
        ExpenseCategory.entertainment => Icons.movie,
        ExpenseCategory.other => Icons.category,
      };

  static ExpenseCategory fromString(String? name) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == (name ?? '').toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }
}

/// Model ExpenseItem theo đặc tả VKU Slide 15 & Slide 42.
/// Hỗ trợ immutability, const constructor và chuyển đổi dữ liệu với Local SQLite.
class ExpenseItem {
  final String id;
  final String title; // Tên cửa hàng / merchant hoặc nội dung chuyển tiền
  final double amount; // Số tiền (VNĐ)
  final DateTime timestamp; // Thời gian phát sinh chi tiêu
  final ExpenseCategory category; // Phân loại chi tiêu
  final String? imagePath; // Đường dẫn ảnh hóa đơn lưu local (để đối soát offline)
  final String? rawOcrText; // Nội dung văn bản OCR gốc phục vụ debug hoặc Gemini phân tích

  const ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.timestamp,
    this.category = ExpenseCategory.other,
    this.imagePath,
    this.rawOcrText,
  });

  /// Named constructor dạng draft khởi tạo nhanh khi người dùng vừa scan hóa đơn
  ExpenseItem.draft({
    required this.title,
    required this.amount,
    this.category = ExpenseCategory.other,
    this.imagePath,
    this.rawOcrText,
  })  : id = 'exp_${DateTime.now().millisecondsSinceEpoch}',
        timestamp = DateTime.now();

  /// Chuyển đối tượng thành Map để lưu vào SQLite (sqflite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'category': category.name,
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
    String? imagePath,
    String? rawOcrText,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
    );
  }
}
