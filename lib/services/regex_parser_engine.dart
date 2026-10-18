import '../models/expense_item.dart';

/// Kết quả bóc tách dữ liệu từ OCR bằng Dart 3 Record (theo quy chuẩn Slide 13)
/// `(String merchant, double total, DateTime date, ExpenseCategory category)`
typedef ParsedReceiptData = ({
  String merchant,
  double total,
  DateTime date,
  ExpenseCategory category,
});

/// Động cơ phân tích Heuristic Regex (Dart Regex Parser Engine)
/// Xử lý cả 2 tình huống:
/// 1. Hóa đơn bán lẻ/siêu thị/nhà hàng (Receipt scan)
/// 2. Tin nhắn SMS/thông báo biến động số dư ngân hàng (Vietcombank, MB, Techcombank, MoMo...)
class RegexParserEngine {
  /// Hàm phân tích chính, nhận chuỗi OCR thô từ Google ML Kit và trả về Record dữ liệu đã chuẩn hóa
  static ParsedReceiptData parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return (
        merchant: 'Không xác định',
        total: 0.0,
        date: DateTime.now(),
        category: ExpenseCategory.other,
      );
    }

    final lines = rawText
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // 1. Trích xuất Tên cửa hàng (Merchant)
    final merchant = _extractMerchant(lines, rawText);

    // 2. Trích xuất Ngày giao dịch (Date)
    final date = _extractDate(rawText);

    // 3. Trích xuất Tổng tiền (Total amount)
    final total = _extractTotalAmount(lines, rawText);

    // 4. Dự đoán Danh mục (Category) dựa trên từ khóa trong hóa đơn
    final category = _guessCategory(rawText, merchant);

    return (
      merchant: merchant,
      total: total,
      date: date,
      category: category,
    );
  }

  /// Trích xuất tên đơn vị bán hàng / đối tượng nhận tiền
  static String _extractMerchant(List<String> lines, String rawText) {
    // A. Kiểm tra trước các dòng đầu tiên (Đặc thù hóa đơn bán lẻ)
    for (int i = 0; i < lines.length && i < 3; i++) {
      final line = lines[i];
      final normalized = _removeDiacritics(line).toLowerCase();
      // Bỏ qua dòng tiêu đề hóa đơn, số điện thoại, ngày tháng hoặc số dư SMS
      if (RegExp(r'^(hoa don|receipt|phieu thu|ngay|so|date|bill|vat|so du|sd|tk|tai khoan|giao dich)', caseSensitive: false).hasMatch(normalized)) {
        continue;
      }
      if (line.length >= 3 &&
          !RegExp(r'^\d+$').hasMatch(line) &&
          !line.startsWith('-') &&
          !RegExp(r'(\d+[\.,]\d+|\bvnd\b|vnđ|\bđ\b)', caseSensitive: false).hasMatch(line)) {
        return _cleanMerchantName(line);
      }
    }

    // B. Kiểm tra format SMS ngân hàng (VD: "ND: Co.op Mart", "tai HIGHLANDS...", "GD tai...")
    final smsPatterns = [
      RegExp(r'\b(?:ND|Noi dung|GD tai|chuyen toi)\b\s*[:\-]?\s*([^\n\r,\.]+)', caseSensitive: false),
      RegExp(r'\b(?:Merchant|Nha cung cap)\b\s*[:\-]?\s*([^\n\r]+)', caseSensitive: false),
      RegExp(r'\btai\s+([A-Za-z0-9\s\.\-_]+)', caseSensitive: false),
    ];

    for (final reg in smsPatterns) {
      final match = reg.firstMatch(rawText);
      if (match != null && match.groupCount >= 1) {
        final captured = match.group(1)?.trim();
        if (captured != null && captured.length > 2 && captured.length < 50) {
          return _cleanMerchantName(captured);
        }
      }
    }

    return lines.isNotEmpty ? _cleanMerchantName(lines.first) : 'Cửa hàng';
  }

  /// Làm sạch chuỗi tên merchant
  static String _cleanMerchantName(String text) {
    return text.replaceAll(RegExp(r'[*#:;]+'), '').trim();
  }

  /// Trích xuất ngày tháng (dd/MM/yyyy, dd-MM-yyyy, yyyy-MM-dd)
  static DateTime _extractDate(String text) {
    // Các regex ngày phổ biến ở Việt Nam
    final dateRegexes = [
      // dd/mm/yyyy hoặc dd-mm-yyyy hoặc dd.mm.yyyy
      RegExp(r'\b(0?[1-9]|[12][0-9]|3[01])[\/\-\.](0?[1-9]|1[012])[\/\-\.](20\d\d)\b'),
      // yyyy/mm/dd hoặc yyyy-mm-dd
      RegExp(r'\b(20\d\d)[\/\-\.](0?[1-9]|1[012])[\/\-\.](0?[1-9]|[12][0-9]|3[01])\b'),
    ];

    for (final reg in dateRegexes) {
      final match = reg.firstMatch(text);
      if (match != null) {
        try {
          if (match.group(1)!.length == 4) {
            // yyyy-mm-dd
            final year = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final day = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          } else {
            // dd-mm-yyyy
            final day = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final year = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          }
        } catch (_) {}
      }
    }

    return DateTime.now();
  }

  /// Trích xuất tổng tiền hóa đơn (VND)
  static double _extractTotalAmount(List<String> lines, String rawText) {
    // Mẫu 1: Ưu tiên phát hiện biến động số dư trừ tiền trong SMS ngân hàng (VD: "SD: -120,000VND" hoặc "GD: -50.000")
    final debitPattern = RegExp(r'-\s*(\d{1,3}(?:[.,]\d{3})+)', caseSensitive: false);
    for (final line in lines) {
      // Bỏ qua dòng số dư khả dụng / số dư hiện tại
      final normLine = _removeDiacritics(line).toLowerCase();
      if (normLine.contains('kha dung') || normLine.contains('so du hien tai') || normLine.contains('so du cuoi')) {
        continue;
      }
      final debitMatch = debitPattern.firstMatch(line);
      if (debitMatch != null) {
        final amt = _parseNumberString(debitMatch.group(1)!);
        if (amt > 0) return amt;
      }
    }

    // Mẫu 2: Ưu tiên dòng có từ khóa "Tổng cộng", "Thành tiền", "Tong tien", "TOTAL", "Thanh toan"
    final totalKeywords = RegExp(
      r'(tong\s*cong|tong\s*tien|thanh\s*tien|tong\s*thanh\s*toan|total|grand\s*total|so\s*tien|thanh\s*toan|amount)',
      caseSensitive: false,
    );

    for (final line in lines) {
      final normLine = _removeDiacritics(line).toLowerCase();
      if (normLine.contains('kha dung') || normLine.contains('tien mat') || normLine.contains('tien thua')) {
        continue;
      }
      if (totalKeywords.hasMatch(normLine)) {
        final amount = _findLargestNumberInLine(line);
        if (amount != null && amount > 0) {
          return amount;
        }
      }
    }

    // Mẫu 3: Tìm các định dạng tiền tệ hợp lệ trong toàn bộ văn bản (loại trừ số dư tài khoản)
    final currencyPattern = RegExp(
      r'(\b\d{1,3}(?:[.,]\d{3})+(?:\s*(?:VND|VNĐ|đ|d))?\b)',
      caseSensitive: false,
    );

    final matches = currencyPattern.allMatches(rawText);
    double maxAmount = 0.0;

    for (final m in matches) {
      final str = m.group(1);
      if (str != null) {
        final parsedVal = _parseNumberString(str);
        if (parsedVal > maxAmount && parsedVal < 500000000) {
          maxAmount = parsedVal;
        }
      }
    }

    return maxAmount;
  }

  /// Tìm số tiền trong một dòng cụ thể
  static double? _findLargestNumberInLine(String line) {
    final numRegex = RegExp(r'(\d{1,3}(?:[.,]\d{3})*|\d+)');
    final matches = numRegex.allMatches(line);
    double? highest;
    for (final m in matches) {
      final val = _parseNumberString(m.group(0)!);
      if (val > 0 && (highest == null || val > highest)) {
        highest = val;
      }
    }
    return highest;
  }

  /// Chuyển đổi các định dạng số '50.000', '50,000', '50000' sang kiểu double
  static double _parseNumberString(String raw) {
    var cleaned = raw
        .replaceAll(RegExp(r'[^\d]'), '') // Xóa toàn bộ ký tự không phải số
        .trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Phân loại chi tiêu tự động dựa trên từ khóa ngữ nghĩa
  static ExpenseCategory _guessCategory(String text, String merchant) {
    final combined = _removeDiacritics('$text $merchant').toLowerCase();

    if (RegExp(r'(cafe|coffee|tra sua|quan an|nha hang|bun|pho|com|food|highlands|phuc long|kfc|lotteria|starbucks|bakery)').hasMatch(combined)) {
      return ExpenseCategory.food;
    }
    if (RegExp(r'(grab|be|xang|petrol|xe buyt|taxi|ve xe|ve tau|flight|transport|gui xe)').hasMatch(combined)) {
      return ExpenseCategory.transport;
    }
    if (RegExp(r'(sieu thi|mart|co\.op|winmart|circle k|shopee|lazada|tiki|quan ao|fashion|shopping)').hasMatch(combined)) {
      return ExpenseCategory.shopping;
    }
    if (RegExp(r'(tien dien|tien nuoc|internet|wifi|dien thoai|viettel|fpt|vnpt|rac|hoa don)').hasMatch(combined)) {
      return ExpenseCategory.utilities;
    }
    if (RegExp(r'(rap phim|cgv|lotte cinema|game|billiards|karaoke|du lich|ticket)').hasMatch(combined)) {
      return ExpenseCategory.entertainment;
    }

    return ExpenseCategory.other;
  }

  /// Hàm loại bỏ dấu tiếng Việt để regex tiếng Việt không phân biệt dấu chính xác
  static String _removeDiacritics(String str) {
    const vietnamese = 'aAeEoOuUiIdDyY';
    final vietnameseRegex = [
      RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'),
      RegExp(r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]'),
      RegExp(r'[èéẹẻẽêềếệểễ]'),
      RegExp(r'[ÈÉẸẺẼÊỀẾỆỂỄ]'),
      RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'),
      RegExp(r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]'),
      RegExp(r'[ùúụủũưừứựửữ]'),
      RegExp(r'[ÙÚỤỦŨƯỪỨỰỬỮ]'),
      RegExp(r'[ìíịỉĩ]'),
      RegExp(r'[ÌÍỊỈĨ]'),
      RegExp(r'[đ]'),
      RegExp(r'[Đ]'),
      RegExp(r'[ỳýỵỷỹ]'),
      RegExp(r'[ỲÝỴỶỸ]'),
    ];

    var result = str;
    for (int i = 0; i < vietnameseRegex.length; i++) {
      result = result.replaceAll(vietnameseRegex[i], vietnamese[i]);
    }
    return result;
  }
}
