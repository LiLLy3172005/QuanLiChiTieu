import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_item.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../services/ocr_service.dart';
import '../services/regex_parser_engine.dart';

/// Trạng thái của toàn bộ luồng quản lý chi tiêu (State Pattern)
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

/// Riverpod 2 StateNotifier quản lý nghiệp vụ và trạng thái (Slide 42)
class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final DatabaseService _db = DatabaseService.instance;
  final OcrService _ocrService = OcrService();
  GeminiService _geminiService = GeminiService();

  ExpenseNotifier() : super(const ExpenseState()) {
    loadAllExpenses();
  }

  /// Cấu hình Gemini API key (nếu người dùng có key)
  void setApiKey(String key) {
    _geminiService = GeminiService(apiKey: key);
  }

  /// Tải toàn bộ danh sách chi tiêu từ SQLite (Offline)
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

  /// Quét ảnh bằng ML Kit OCR offline -> bóc tách qua Regex Engine -> trả về dữ liệu đề xuất
  Future<ParsedReceiptData?> processImageWithOcr(String imagePath) async {
    state = state.copyWith(isScanning: true);
    try {
      // 1. Nhận diện chữ On-device ML Kit (hoặc Web simulator)
      final rawText = await _ocrService.recognizeTextFromImagePath(imagePath);
      // 2. Chạy Dart Regex Engine
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

  /// Thêm khoản chi mới vào SQLite và cập nhật UI ngay lập tức
  Future<void> addExpense(ExpenseItem item) async {
    await _db.insertExpense(item);
    await loadAllExpenses();
  }

  /// Xóa khoản chi
  Future<void> removeExpense(String id) async {
    await _db.deleteExpense(id);
    await loadAllExpenses();
  }

  /// Cập nhật khoản chi
  Future<void> updateExpense(ExpenseItem item) async {
    await _db.updateExpense(item);
    await loadAllExpenses();
  }

  /// Phân tích chi tiêu và hỏi cách tiết kiệm tiền qua Gemini AI
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

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}

/// Provider toàn cục cho ứng dụng
final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {
  return ExpenseNotifier();
});

/// Provider tính tổng số tiền đã chi tiêu
final totalExpenseAmountProvider = Provider<double>((ref) {
  final state = ref.watch(expenseProvider);
  return state.items.fold(0.0, (sum, item) => sum + item.amount);
});

/// Provider phân bổ chi tiêu theo danh mục (cho Donut Chart)
final categoryBreakdownProvider = Provider<Map<ExpenseCategory, double>>((ref) {
  final state = ref.watch(expenseProvider);
  final map = <ExpenseCategory, double>{};
  for (final item in state.items) {
    map[item.category] = (map[item.category] ?? 0.0) + item.amount;
  }
  return map;
});

/// Provider tính chi tiêu 7 ngày gần nhất (cho Weekly Bar Chart)
final weeklyExpensesProvider = Provider<Map<int, double>>((ref) {
  final state = ref.watch(expenseProvider);
  final now = DateTime.now();
  final Map<int, double> daily = {for (int i = 0; i < 7; i++) i: 0.0};

  for (final item in state.items) {
    final diff = now.difference(item.timestamp).inDays;
    final dayIndex = 6 - diff;
    if (dayIndex >= 0 && dayIndex < 7) {
      daily[dayIndex] = (daily[dayIndex] ?? 0.0) + item.amount;
    }
  }
  return daily;
});
