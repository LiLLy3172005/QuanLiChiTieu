import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_item.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../services/ocr_service.dart';
import '../services/regex_parser_engine.dart';

/// Trạng thái của toàn bộ luồng quản lý chi tiêu & thu nhập (State Pattern)
class ExpenseState {
  final List<ExpenseItem> items;
  final bool isLoading;
  final bool isScanning;
  final String? errorMessage;
  final String? aiAdvice;
  final bool isAiLoading;

  const ExpenseState({
    this.items = const [],
    this.isLoading = false,
    this.isScanning = false,
    this.errorMessage,
    this.aiAdvice,
    this.isAiLoading = false,
  });

  ExpenseState copyWith({
    List<ExpenseItem>? items,
    bool? isLoading,
    bool? isScanning,
    String? errorMessage,
    String? aiAdvice,
    bool? isAiLoading,
  }) {
    return ExpenseState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isScanning: isScanning ?? this.isScanning,
      errorMessage: errorMessage,
      aiAdvice: aiAdvice ?? this.aiAdvice,
      isAiLoading: isAiLoading ?? this.isAiLoading,
    );
  }
}

/// Riverpod 2 Notifier quản lý nghiệp vụ và trạng thái (Chuẩn Week 8 Slide 14 & 15 VKU)
class ExpenseNotifier extends Notifier<ExpenseState> {
  late final DatabaseService _db = DatabaseService.instance;
  late final OcrService _ocrService = OcrService();
  GeminiService _geminiService = GeminiService();

  @override
  ExpenseState build() {
    ref.onDispose(() {
      _ocrService.dispose();
    });
    Future.microtask(() => loadAllExpenses());
    return const ExpenseState();
  }

  /// Cấu hình Gemini API key
  void setApiKey(String key) {
    _geminiService = GeminiService(apiKey: key);
  }

  /// Tải toàn bộ danh sách giao dịch từ SQLite / Web Storage
  Future<void> loadAllExpenses() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _db.getAllExpenses();
      state = state.copyWith(items: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi tải cơ sở dữ liệu: $e',
      );
    }
  }

  /// Quét ảnh bằng OCR -> bóc tách qua Regex Engine -> tự động xác định Thu / Chi
  Future<ParsedReceiptData?> processImageWithOcr(String imagePath) async {
    state = state.copyWith(isScanning: true);
    try {
      final rawText = await _ocrService.recognizeTextFromImagePath(imagePath);
      final parsed = RegexParserEngine.parse(rawText);
      state = state.copyWith(isScanning: false);
      return parsed;
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: 'Lỗi trong quá trình quét OCR: $e',
      );
      return null;
    }
  }

  /// Thêm giao dịch mới (Thu nhập hoặc Chi tiêu)
  Future<void> addExpense(ExpenseItem item) async {
    await _db.insertExpense(item);
    await loadAllExpenses();
  }

  /// Xóa giao dịch
  Future<void> removeExpense(String id) async {
    await _db.deleteExpense(id);
    await loadAllExpenses();
  }

  /// Cập nhật giao dịch
  Future<void> updateExpense(ExpenseItem item) async {
    await _db.updateExpense(item);
    await loadAllExpenses();
  }

  /// Phân tích tình hình tài chính tổng thể (Cả Thu & Chi) và hỏi mẹo tiết kiệm
  Future<void> requestAiAdvice({String? customPrompt}) async {
    state = state.copyWith(isAiLoading: true);
    try {
      final advice = await _geminiService.analyzeExpensesAndAdvise(
        state.items,
        userQuestion: customPrompt,
      );
      state = state.copyWith(aiAdvice: advice, isAiLoading: false);
    } catch (e) {
      state = state.copyWith(
        isAiLoading: false,
        aiAdvice: 'Không thể phân tích lúc này: $e',
      );
    }
  }
}

/// Provider toàn cục dạng Riverpod 2 Compile-Safe NotifierProvider (Slide 15 VKU)
final expenseProvider = NotifierProvider<ExpenseNotifier, ExpenseState>(
  ExpenseNotifier.new,
);

/// Provider tính tổng số tiền đã CHI TIÊU
final totalExpenseAmountProvider = Provider<double>((ref) {
  final state = ref.watch(expenseProvider);
  return state.items
      .where((item) => item.isExpense)
      .fold(0.0, (sum, item) => sum + item.amount);
});

/// Provider tính tổng số tiền THU NHẬP
final totalIncomeProvider = Provider<double>((ref) {
  final state = ref.watch(expenseProvider);
  return state.items
      .where((item) => item.isIncome)
      .fold(0.0, (sum, item) => sum + item.amount);
});

/// Provider tính SỐ DƯ RÒNG = Tổng Thu - Tổng Chi
final netBalanceProvider = Provider<double>((ref) {
  final income = ref.watch(totalIncomeProvider);
  final expense = ref.watch(totalExpenseAmountProvider);
  return income - expense;
});

/// Provider phân bổ chi tiêu theo danh mục (cho Donut Chart Chi tiêu)
final categoryBreakdownProvider = Provider<Map<ExpenseCategory, double>>((ref) {
  final state = ref.watch(expenseProvider);
  final map = <ExpenseCategory, double>{};
  for (final item in state.items) {
    if (item.isExpense) {
      map[item.category] = (map[item.category] ?? 0.0) + item.amount;
    }
  }
  return map;
});

/// Provider phân bổ thu nhập theo danh mục (cho Donut Chart Thu nhập)
final incomeCategoryBreakdownProvider = Provider<Map<ExpenseCategory, double>>((ref) {
  final state = ref.watch(expenseProvider);
  final map = <ExpenseCategory, double>{};
  for (final item in state.items) {
    if (item.isIncome) {
      map[item.category] = (map[item.category] ?? 0.0) + item.amount;
    }
  }
  return map;
});

/// Provider tính chi tiêu 7 ngày gần nhất (cho Weekly Bar Chart)
final weeklyExpensesProvider = Provider<Map<int, double>>((ref) {
  final state = ref.watch(expenseProvider);
  final now = DateTime.now();
  final Map<int, double> daily = {for (int i = 0; i < 7; i++) i: 0.0};

  for (final item in state.items) {
    if (item.isExpense) {
      final diff = now.difference(item.timestamp).inDays;
      final dayIndex = 6 - diff;
      if (dayIndex >= 0 && dayIndex < 7) {
        daily[dayIndex] = (daily[dayIndex] ?? 0.0) + item.amount;
      }
    }
  }
  return daily;
});

/// Family Provider tìm kiếm giao dịch theo ID (phục vụ GoRouter path parameters /expense/:id)
final singleExpenseProvider = Provider.family<ExpenseItem?, String>((ref, id) {
  final state = ref.watch(expenseProvider);
  try {
    return state.items.firstWhere((item) => item.id == id);
  } catch (_) {
    return null;
  }
});
