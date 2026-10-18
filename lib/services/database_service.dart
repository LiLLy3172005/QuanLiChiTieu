import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/expense_item.dart';

/// Dịch vụ quản lý Cơ sở dữ liệu SQLite cục bộ (sqflite)
/// Đảm bảo ứng dụng hoạt động 100% OFFLINE không cần internet.
class DatabaseService {
  DatabaseService._init();
  static final DatabaseService instance = DatabaseService._init();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vku_expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
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
        image_path TEXT,
        raw_ocr_text TEXT
      )
    ''');
  }

  // --- CÁC THAO TÁC CRUD CƠ BẢN ---

  /// Thêm mới một khoản chi tiêu
  Future<int> insertExpense(ExpenseItem item) async {
    final db = await database;
    return await db.insert(
      'expenses',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lấy danh sách tất cả các khoản chi, sắp xếp theo thời gian mới nhất trước
  Future<List<ExpenseItem>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => ExpenseItem.fromMap(map)).toList();
  }

  /// Cập nhật thông tin chi tiêu sau khi người dùng sửa thủ công
  Future<int> updateExpense(ExpenseItem item) async {
    final db = await database;
    return await db.update(
      'expenses',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Xóa khoản chi tiêu theo ID
  Future<int> deleteExpense(String id) async {
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CÁC HÀM TRUY VẤN THỐNG KÊ PHỤC VỤ CUSTOM PAINTER CHARTS ---

  /// Thống kê tỷ trọng chi tiêu theo từng danh mục (Dành cho Biểu đồ Donut Chart)
  Future<Map<ExpenseCategory, double>> getCategoryBreakdown() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM expenses
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
    final db = await database;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final startDay = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);

    final result = await db.rawQuery('''
      SELECT timestamp, amount
      FROM expenses
      WHERE timestamp >= ?
    ''', [startDay.toIso8601String()]);

    // Map 0..6 tương ứng từ (hôm nay - 6 ngày) đến hôm nay
    final Map<int, double> dailyTotals = {for (int i = 0; i < 7; i++) i: 0.0};

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
    final db = await database;
    db.close();
  }
}
