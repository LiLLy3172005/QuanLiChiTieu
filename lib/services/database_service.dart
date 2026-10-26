import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/expense_item.dart';

/// Dịch vụ quản lý Cơ sở dữ liệu SQLite cục bộ (sqflite)
/// - Trên Mobile: Chạy 100% OFFLINE với sqflite database
/// - Trên Web / Cloudflare: Chạy In-Memory Storage tương thích đa nền tảng
class DatabaseService {
  DatabaseService._init();
  static final DatabaseService instance = DatabaseService._init();

  static Database? _database;

  // Bộ nhớ tạm trên Web (Fallback khi chạy trên Cloudflare Pages/Web)
  final List<ExpenseItem> _webItems = [
    ExpenseItem(
      id: 'demo_income_1',
      title: 'Lương trợ giảng VKU',
      amount: 2500000.0,
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      category: ExpenseCategory.salary,
      type: TransactionType.income,
      rawOcrText: 'Cong ty chuyen khoan +2,500,000VND. Luong thang',
    ),
    ExpenseItem(
      id: 'demo_1',
      title: 'Highlands Coffee VKU',
      amount: 65000.0,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      category: ExpenseCategory.food,
      type: TransactionType.expense,
      rawOcrText: 'HIGHLANDS COFFEE\nTong cong: 65.000 VND',
    ),
    ExpenseItem(
      id: 'demo_income_2',
      title: 'Ba mẹ gửi tiền sinh hoạt',
      amount: 1500000.0,
      timestamp: DateTime.now().subtract(const Duration(days: 4)),
      category: ExpenseCategory.allowance,
      type: TransactionType.income,
      rawOcrText: 'TK 1234 +1,500,000VND tu HUYNH VAN B',
    ),
    ExpenseItem(
      id: 'demo_2',
      title: 'Đổ xăng Petrolimex',
      amount: 50000.0,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      category: ExpenseCategory.transport,
      type: TransactionType.expense,
      rawOcrText: 'PETROLIMEX\nTong thanh toan: 50.000 đ',
    ),
    ExpenseItem(
      id: 'demo_3',
      title: 'Sách giáo trình VKU',
      amount: 120000.0,
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      category: ExpenseCategory.shopping,
      type: TransactionType.expense,
      rawOcrText: 'NHA SACH VKU\nThanh tien: 120.000 đ',
    ),
  ];

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('sqflite does not run on web directly.');
    }
    if (_database != null) return _database!;
    _database = await _initDB('vku_expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        timestamp TEXT NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'expense',
        image_path TEXT,
        raw_ocr_text TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE expenses ADD COLUMN type TEXT NOT NULL DEFAULT 'expense'");
      } catch (_) {}
    }
  }

  // --- CÁC THAO TÁC CRUD CƠ BẢN ---

  /// Thêm mới một giao dịch (Thu hoặc Chi)
  Future<int> insertExpense(ExpenseItem item) async {
    if (kIsWeb) {
      _webItems.removeWhere((e) => e.id == item.id);
      _webItems.insert(0, item);
      return 1;
    }
    final db = await database;
    return await db.insert(
      'expenses',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lấy danh sách tất cả các giao dịch, sắp xếp theo thời gian mới nhất trước
  Future<List<ExpenseItem>> getAllExpenses() async {
    if (kIsWeb) {
      _webItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return List.unmodifiable(_webItems);
    }
    final db = await database;
    final maps = await db.query(
      'expenses',
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => ExpenseItem.fromMap(map)).toList();
  }

  /// Cập nhật thông tin giao dịch
  Future<int> updateExpense(ExpenseItem item) async {
    if (kIsWeb) {
      final idx = _webItems.indexWhere((e) => e.id == item.id);
      if (idx != -1) {
        _webItems[idx] = item;
      }
      return 1;
    }
    final db = await database;
    return await db.update(
      'expenses',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Xóa giao dịch theo ID
  Future<int> deleteExpense(String id) async {
    if (kIsWeb) {
      _webItems.removeWhere((e) => e.id == id);
      return 1;
    }
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CÁC HÀM TRUY VẤN THỐNG KÊ PHỤC VỤ CUSTOM PAINTER CHARTS ---

  /// Thống kê tỷ trọng theo danh mục của một loại giao dịch (Chi tiêu hoặc Thu nhập)
  Future<Map<ExpenseCategory, double>> getCategoryBreakdown({TransactionType? type}) async {
    if (kIsWeb) {
      final breakdown = <ExpenseCategory, double>{};
      for (final item in _webItems) {
        if (type == null || item.type == type) {
          breakdown[item.category] = (breakdown[item.category] ?? 0.0) + item.amount;
        }
      }
      return breakdown;
    }

    final db = await database;
    final String whereClause = type != null ? "WHERE type = '${type.name}'" : '';
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM expenses
      $whereClause
      GROUP BY category
    ''');

    final breakdown = <ExpenseCategory, double>{};
    for (final row in result) {
      final category = ExpenseCategoryExt.fromString(row['category'] as String?);
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      breakdown[category] = total;
    }
    return breakdown;
  }

  /// Thống kê chi tiêu của 7 ngày gần nhất (Dành cho Weekly Bar Chart)
  Future<Map<int, double>> getWeeklyExpenses() async {
    final now = DateTime.now();
    final Map<int, double> dailyTotals = {for (int i = 0; i < 7; i++) i: 0.0};

    if (kIsWeb) {
      for (final item in _webItems) {
        if (item.isExpense) {
          final diffDays = now.difference(item.timestamp).inDays;
          final dayIndex = 6 - diffDays;
          if (dayIndex >= 0 && dayIndex < 7) {
            dailyTotals[dayIndex] = (dailyTotals[dayIndex] ?? 0.0) + item.amount;
          }
        }
      }
      return dailyTotals;
    }

    final db = await database;
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final startDay = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);

    final result = await db.rawQuery('''
      SELECT timestamp, amount
      FROM expenses
      WHERE timestamp >= ? AND type = 'expense'
    ''', [startDay.toIso8601String()]);

    for (final row in result) {
      final date = DateTime.tryParse(row['timestamp'] as String? ?? '');
      if (date != null) {
        final diffDays = now.difference(date).inDays;
        final dayIndex = 6 - diffDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          final amt = (row['amount'] as num?)?.toDouble() ?? 0.0;
          dailyTotals[dayIndex] = (dailyTotals[dayIndex] ?? 0.0) + amt;
        }
      }
    }

    return dailyTotals;
  }

  /// Đóng kết nối database
  Future<void> close() async {
    if (!kIsWeb && _database != null) {
      final db = await database;
      db.close();
    }
  }
}
