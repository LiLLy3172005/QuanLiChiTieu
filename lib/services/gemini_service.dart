import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import '../models/expense_item.dart';

/// Dịch vụ Trí tuệ nhân tạo Gemini AI phân tích chi tiêu và tư vấn tiết kiệm tài chính
/// Tích hợp Gemini API với chế độ Fallback tư vấn Rule-based khi OFFLINE không có mạng.
class GeminiService {
  // Người dùng có thể truyền vào Gemini API Key cá nhân
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

  /// Phân tích dữ liệu chi tiêu và đưa ra chiến lược tiết kiệm tài chính cá nhân
  Future<String> analyzeExpensesAndAdvise(
    List<ExpenseItem> expenses, {
    String? userQuestion,
  }) async {
    if (expenses.isEmpty) {
      return 'Bạn chưa có khoản chi tiêu nào được ghi nhận. Hãy quét hoặc nhập một số hóa đơn để AI phân tích nhé!';
    }

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final totalSpent = expenses.fold<double>(0, (sum, item) => sum + item.amount);

    // Chuẩn bị tóm tắt danh sách chi tiêu để gửi cho Gemini
    final summaryBuffer = StringBuffer();
    summaryBuffer.writeln('Tổng chi tiêu: ${currencyFormat.format(totalSpent)}');
    summaryBuffer.writeln('Chi tiết các khoản chi tiêu gần đây:');
    for (final exp in expenses.take(15)) {
      summaryBuffer.writeln(
        '- Ngày ${DateFormat('dd/MM/yyyy').format(exp.timestamp)}: ${exp.title} (${exp.category.vietnameseName}) - ${currencyFormat.format(exp.amount)}',
      );
    }

    // Nếu có API Key và có kết nối, gọi Gemini API
    if (_model != null) {
      try {
        final prompt = '''
Bạn là chuyên gia cố vấn tài chính cá nhân thông minh, thân thiện dành cho sinh viên và người trẻ tại Việt Nam.
Dưới đây là lịch sử chi tiêu thực tế được trích xuất từ hóa đơn và tin nhắn ngân hàng của người dùng:

$summaryBuffer

Câu hỏi của người dùng (nếu có): ${userQuestion ?? 'Hãy phân tích tình hình tài chính của tôi và hướng dẫn cụ thể cách tiết kiệm tiền.'}

Hãy trả lời theo cấu trúc sau:
1. 📊 **Đánh giá tổng quan**: Phân tích danh mục nào đang chiếm tỷ trọng lớn nhất và có dấu hiệu bất thường không.
2. ⚠️ **Cảnh báo các khoản chi dễ cắt giảm**: Chỉ ra 1-2 khoản chi tiêu không thiết yếu.
3. 💡 **3 Lời khuyên tiết kiệm thiết thực**: Áp dụng quy tắc tài chính thực tế (ví dụ quy tắc 50/30/20, hạn chế ăn ngoài, săn mã giảm giá, v.v.).
Hãy dùng phong cách động viên, gần gũi, súc tích bằng tiếng Việt.
''';

        final response = await _model!.generateContent([Content.text(prompt)]);
        if (response.text != null && response.text!.isNotEmpty) {
          return response.text!;
        }
      } catch (e) {
        // Gặp lỗi mạng hoặc lỗi API -> Tự động chuyển sang Bộ tư vấn Offline
      }
    }

    // Chế độ FALLBACK OFFLINE (Hoạt động hoàn toàn không cần Internet)
    return _generateOfflineAdvice(expenses, totalSpent, currencyFormat);
  }

  /// Thuật toán phân tích quy tắc tài chính Offline (Rule-based Heuristic)
  String _generateOfflineAdvice(
    List<ExpenseItem> expenses,
    double totalSpent,
    NumberFormat currencyFormat,
  ) {
    // Tính tổng theo từng danh mục
    final categoryTotals = <ExpenseCategory, double>{};
    for (final exp in expenses) {
      categoryTotals[exp.category] = (categoryTotals[exp.category] ?? 0) + exp.amount;
    }

    // Tìm danh mục chiếm nhiều nhất
    ExpenseCategory topCategory = ExpenseCategory.other;
    double maxAmount = 0.0;
    categoryTotals.forEach((cat, amt) {
      if (amt > maxAmount) {
        maxAmount = amt;
        topCategory = cat;
      }
    });

    final topPercentage = totalSpent > 0 ? (maxAmount / totalSpent * 100).toStringAsFixed(1) : '0';

    return '''
📶 **Chế độ phân tích Offline (Không cần Internet)**

📊 **Tổng quan chi tiêu:**
- Tổng ngân sách đã chi: ${currencyFormat.format(totalSpent)} trên ${expenses.length} giao dịch.
- Khoản chi lớn nhất hiện tại thuộc danh mục: **${topCategory.vietnameseName}** với ${currencyFormat.format(maxAmount)} (chiếm $topPercentage%).

💡 **Gợi ý tiết kiệm tiền tự động:**
1. **Kiểm soát khoản "${topCategory.vietnameseName}"**: Hãy thử đặt hạn mức mỗi tuần cho nhóm này và giảm bớt 15-20% tần suất chi tiêu.
2. **Áp dụng nguyên tắc 50/30/20**: 50% cho nhu cầu thiết yếu, 30% cho sở thích cá nhân, 20% gửi tiết kiệm ngay khi có nguồn thu.
3. **Thói quen ghi chép liên tục**: Quét hóa đơn ngay sau khi mua sắm sẽ giúp bạn kiểm soát tâm lý chi tiêu ngoài kế hoạch.

*(Để nhận phân tích chi tiết bằng AI Generative, bạn có thể nhập Gemini API Key trong phần Cài đặt khi có kết nối Internet).*
''';
  }
}
