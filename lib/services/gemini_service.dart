import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import '../models/expense_item.dart';

/// Dịch vụ Trí tuệ nhân tạo Gemini AI phân tích thu chi và tư vấn tiết kiệm tài chính
/// Tích hợp Gemini API với chế độ Fallback tư vấn Rule-based khi OFFLINE không có mạng.
class GeminiService {
  final String? apiKey;
  GenerativeModel? _model;

  GeminiService({this.apiKey}) {
    if (apiKey != null && apiKey!.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey!,
      );
    }
  }

  /// Phân tích dữ liệu Thu - Chi và đưa ra chiến lược tiết kiệm tài chính cá nhân
  Future<String> analyzeExpensesAndAdvise(
    List<ExpenseItem> items, {
    String? userQuestion,
  }) async {
    if (items.isEmpty) {
      return 'Bạn chưa có giao dịch nào được ghi nhận. Hãy quét hoặc nhập một số khoản thu/chi để AI phân tích nhé!';
    }

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final totalExpense = items.where((e) => e.isExpense).fold<double>(0, (sum, i) => sum + i.amount);
    final totalIncome = items.where((e) => e.isIncome).fold<double>(0, (sum, i) => sum + i.amount);
    final netBalance = totalIncome - totalExpense;

    // Chuẩn bị tóm tắt danh sách Thu - Chi gần đây
    final summaryBuffer = StringBuffer();
    summaryBuffer.writeln('💰 TỔNG THU NHẬP: ${currencyFormat.format(totalIncome)}');
    summaryBuffer.writeln('💸 TỔNG CHI TIÊU: ${currencyFormat.format(totalExpense)}');
    summaryBuffer.writeln('⚖️ SỐ DƯ RÒNG: ${currencyFormat.format(netBalance)}');
    summaryBuffer.writeln('\nChi tiết các giao dịch gần đây:');
    for (final tx in items.take(15)) {
      final sign = tx.isIncome ? '[+ THU]' : '[- CHI]';
      summaryBuffer.writeln(
        '- Ngày ${DateFormat('dd/MM/yyyy').format(tx.timestamp)}: $sign ${tx.title} (${tx.category.vietnameseName}) - ${currencyFormat.format(tx.amount)}',
      );
    }

    // Nếu có API Key và có kết nối, gọi Gemini API
    if (_model != null) {
      try {
        final prompt = '''
Bạn là chuyên gia cố vấn tài chính cá nhân thông minh, thân thiện dành cho sinh viên và người trẻ tại Việt Nam.
Dưới đây là báo cáo lịch sử Thu nhập và Chi tiêu thực tế từ hóa đơn & SMS ngân hàng của người dùng:

$summaryBuffer

Câu hỏi của người dùng (nếu có): ${userQuestion ?? 'Hãy phân tích tình hình tài chính tổng thể của tôi, so sánh Thu - Chi và hướng dẫn cụ thể cách tiết kiệm tiền.'}

Hãy trả lời theo cấu trúc sau:
1. 📊 **Đánh giá cán cân Thu - Chi**: Đánh giá số dư ròng và tỷ lệ tiết kiệm (Thu nhập - Chi tiêu).
2. ⚠️ **Cảnh báo danh mục chi tiêu cần tối ưu**: Chỉ ra nhóm chi tiêu đang chiếm tỷ lệ quá cao hoặc không cần thiết.
3. 💡 **3 Lời khuyên tài chính thiết thực**: Áp dụng quy tắc 50/30/20 hoặc 6 chiếc lọ tài chính, cách gia tăng nguồn thu phụ hoặc cắt giảm lãng phí.
Phong cách gần gũi, súc tích bằng tiếng Việt.
''';

        final response = await _model!.generateContent([Content.text(prompt)]);
        if (response.text != null && response.text!.isNotEmpty) {
          return response.text!;
        }
      } catch (_) {}
    }

    // Chế độ FALLBACK OFFLINE (Hoạt động hoàn toàn không cần Internet)
    return _generateOfflineAdvice(items, totalIncome, totalExpense, netBalance, currencyFormat);
  }

  /// Thuật toán phân tích quy tắc tài chính Offline (Rule-based Heuristic)
  String _generateOfflineAdvice(
    List<ExpenseItem> items,
    double totalIncome,
    double totalExpense,
    double netBalance,
    NumberFormat currencyFormat,
  ) {
    final expenses = items.where((e) => e.isExpense).toList();
    final categoryTotals = <ExpenseCategory, double>{};
    for (final exp in expenses) {
      categoryTotals[exp.category] = (categoryTotals[exp.category] ?? 0) + exp.amount;
    }

    ExpenseCategory topCategory = ExpenseCategory.other;
    double maxAmount = 0.0;
    categoryTotals.forEach((cat, amt) {
      if (amt > maxAmount) {
        maxAmount = amt;
        topCategory = cat;
      }
    });

    final expensePercent = totalIncome > 0
        ? (totalExpense / totalIncome * 100).toStringAsFixed(1)
        : '100';

    return '''
📶 **Chế độ phân tích Offline (Không cần Internet)**

📊 **Cán cân Thu - Chi:**
- Tổng thu nhập: **${currencyFormat.format(totalIncome)}**
- Tổng chi tiêu: **${currencyFormat.format(totalExpense)}** ($expensePercent% thu nhập)
- Số dư ròng: **${currencyFormat.format(netBalance)}**
- Khoản chi lớn nhất: **${topCategory.vietnameseName}** (${currencyFormat.format(maxAmount)}).

💡 **Gợi ý tiết kiệm tiền tự động:**
1. **Kiểm soát khoản "${topCategory.vietnameseName}"**: Đang chiếm tỷ trọng lớn nhất trong các khoản chi, hãy đặt hạn mức không vượt quá 30% thu nhập.
2. **Quy tắc 50/30/20**: Dành 50% cho nhu cầu thiết yếu, 30% cho mục tiêu cá nhân, và trích ngay 20% (${currencyFormat.format(totalIncome * 0.2)}) vào quỹ tiết kiệm ngay khi có nguồn thu mới.
3. **Thói quen ghi chép cả Thu lẫn Chi**: Giúp bạn luôn làm chủ dòng tiền ròng và tránh rơi vào trạng thái bội chi.

*(Để nhận phân tích chi tiết bằng AI Generative, bạn có thể nhập Gemini API Key trong phần Cài đặt khi có kết nối Internet).*
''';
  }
}
