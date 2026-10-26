import '../models/expense_item.dart';

/// Kết quả bóc tách dữ liệu từ OCR bằng Dart 3 Record (theo quy chuẩn Slide 13)
/// `(String merchant, double total, DateTime date, ExpenseCategory category, TransactionType type)`
typedef ParsedReceiptData = ({
  String merchant,
  double total,
  DateTime date,
  ExpenseCategory category,
  TransactionType type,
});

/// Động cơ phân tích Heuristic Regex (Dart Regex Parser Engine)
/// Xử lý cả 2 tình huống:
/// 1. Hóa đơn bán lẻ/siêu thị/nhà hàng (Receipt scan)
/// 2. Tin nhắn SMS/thông báo biến động số dư ngân hàng:
///    - Tiền CHI (Debit / -)
///    - Tiền THU (Credit / +)
class RegexParserEngine {
  /// Hàm phân tích chính, nhận chuỗi OCR thô từ Google ML Kit và trả về Record dữ liệu đã chuẩn hóa
  static ParsedReceiptData parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return (
        merchant: 'Không xác định',
        total: 0.0,
        date: DateTime.now(),
        category: ExpenseCategory.other,
        type: TransactionType.expense,
      );
    }

    final lines = rawText
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // 1. Nhận diện loại giao dịch: TIỀN THU (+) hay TIỀN CHI (-)
    final type = _detectTransactionType(lines, rawText);

    // 2. Trích xuất Tên cửa hàng hoặc Người chuyển/Nhận (Merchant / Partner)
    final merchant = _extractMerchant(lines, rawText, type);

    // 3. Trích xuất Ngày giao dịch (Date)
    final date = _extractDate(rawText);

    // 4. Trích xuất Số tiền tương ứng theo loại giao dịch
    final total = _extractTotalAmount(lines, rawText, type);

    // 5. Dự đoán Danh mục dựa trên từ khóa ngữ nghĩa và loại giao dịch
    final category = _guessCategory(rawText, merchant, type);

    return (
      merchant: merchant,
      total: total,
      date: date,
      category: category,
      type: type,
    );
  }

  /// Phân biệt Giao dịch Thu (Income) hay Chi (Expense)
  static TransactionType _detectTransactionType(List<String> lines, String rawText) {
    final lower = _removeDiacritics(rawText).toLowerCase();

    // A. Kiểm tra ký hiệu dấu cộng (+) ở dòng biến động số dư SMS (Ví dụ: "SD: +500,000", "GD: +1.000.000")
    final plusPattern = RegExp(r'\+\s*(\d{1,3}(?:[.,]\d{3})+)', caseSensitive: false);
    if (plusPattern.hasMatch(rawText)) {
      return TransactionType.income;
    }

    // B. Kiểm tra ký hiệu dấu trừ (-) ở dòng biến động số dư SMS (Ví dụ: "SD: -120,000", "GD: -50.000")
    final minusPattern = RegExp(r'-\s*(\d{1,3}(?:[.,]\d{3})+)', caseSensitive: false);
    if (minusPattern.hasMatch(rawText)) {
      return TransactionType.expense;
    }

    // C. Kiểm tra các từ khóa nhận tiền / thu nhập
    final incomeKeywords = RegExp(
      r'\b(nhan\s*tien|cong\s*tien|tien\s*vao|nap\s*tien|luong|thuong|tro\s*cap|phu\s*cap|hoan\s*tien|nhan\s*tu|tk\s*duoc\s*cong|credit|deposit|received)\b',
      caseSensitive: false,
    );
    if (incomeKeywords.hasMatch(lower)) {
      return TransactionType.income;
    }

    // D. Mặc định hóa đơn mua sắm thông thường là Chi tiêu
    return TransactionType.expense;
  }

  /// Trích xuất tên đơn vị bán hàng / đối tượng nhận tiền hoặc người gửi tiền
  static String _extractMerchant(List<String> lines, String rawText, TransactionType type) {
    // A. Kiểm tra format SMS ngân hàng (VD: "ND: Co.op Mart", "tu NGUYEN VAN A", "tai HIGHLANDS...")
    final smsPatterns = [
      RegExp(r'\b(?:ND|Noi dung|GD tai|chuyen toi)\b\s*[:\-]?\s*([^\n\r,\.]+)', caseSensitive: false),
      RegExp(r'\b(?:nhan tu|tu|from)\b\s*[:\-]?\s*([^\n\r,\.]+)', caseSensitive: false),
      RegExp(r'\b(?:Merchant|Nha cung cap|Nguoi gui|Nguoi nhan)\b\s*[:\-]?\s*([^\n\r]+)', caseSensitive: false),
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

    // B. Kiểm tra trước các dòng đầu tiên (Đặc thù hóa đơn in)
    for (int i = 0; i < lines.length && i < 3; i++) {
      final line = lines[i];
      final normalized = _removeDiacritics(line).toLowerCase();
      if (RegExp(r'^(hoa don|receipt|phieu thu|phieu chi|ngay|so|date|bill|vat|so du|sd|tk|tai khoan|giao dich)', caseSensitive: false).hasMatch(normalized)) {
        continue;
      }
      if (line.length >= 3 &&
          !RegExp(r'^\d+$').hasMatch(line) &&
          !line.startsWith('-') &&
          !line.startsWith('+') &&
          !RegExp(r'(\d+[\.,]\d+|\bvnd\b|vnđ|\bđ\b)', caseSensitive: false).hasMatch(line)) {
        return _cleanMerchantName(line);
      }
    }

    return lines.isNotEmpty
        ? _cleanMerchantName(lines.first)
        : (type == TransactionType.income ? 'Nguồn thu' : 'Cửa hàng');
  }

  /// Làm sạch chuỗi tên merchant
  static String _cleanMerchantName(String text) {
    return text.replaceAll(RegExp(r'[*#:;]+'), '').trim();
  }

  /// Trích xuất ngày tháng (dd/MM/yyyy, dd-MM-yyyy, yyyy-MM-dd)
  static DateTime _extractDate(String text) {
    final dateRegexes = [
      RegExp(r'\b(0?[1-9]|[12][0-9]|3[01])[\/\-\.](0?[1-9]|1[012])[\/\-\.](20\d\d)\b'),
      RegExp(r'\b(20\d\d)[\/\-\.](0?[1-9]|1[012])[\/\-\.](0?[1-9]|[12][0-9]|3[01])\b'),
    ];

    for (final reg in dateRegexes) {
      final match = reg.firstMatch(text);
      if (match != null) {
        try {
          if (match.group(1)!.length == 4) {
            final year = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final day = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          } else {
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

  /// Trích xuất số tiền giao dịch (VND)
  static double _extractTotalAmount(List<String> lines, String rawText, TransactionType type) {
    // 1. Nếu là TIỀN THU (Income): Ưu tiên dòng có dấu '+' (VD: "SD: +500,000VND" hoặc "PS: +1,200,000")
    if (type == TransactionType.income) {
      final creditPattern = RegExp(r'\+\s*(\d{1,3}(?:[.,]\d{3})+)', caseSensitive: false);
      for (final line in lines) {
        final normLine = _removeDiacritics(line).toLowerCase();
        if (normLine.contains('kha dung') || normLine.contains('so du hien tai') || normLine.contains('so du cuoi')) {
          continue;
        }
        final creditMatch = creditPattern.firstMatch(line);
        if (creditMatch != null) {
          final amt = _parseNumberString(creditMatch.group(1)!);
          if (amt > 0) return amt;
        }
      }
    }

    // 2. Nếu là TIỀN CHI (Expense): Ưu tiên dòng có dấu '-' (VD: "SD: -120,000VND")
    if (type == TransactionType.expense) {
      final debitPattern = RegExp(r'-\s*(\d{1,3}(?:[.,]\d{3})+)', caseSensitive: false);
      for (final line in lines) {
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
    }

    // 3. Ưu tiên dòng có từ khóa hóa đơn "Tổng cộng", "Thành tiền", "Tong tien", "TOTAL", "Thanh toan"
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

    // 4. Tìm các định dạng tiền tệ hợp lệ trong toàn bộ văn bản (loại trừ số dư tài khoản)
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
        .replaceAll(RegExp(r'[^\d]'), '')
        .trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Phân loại danh mục tự động thông minh theo Loại giao dịch (Income vs Expense)
  static ExpenseCategory _guessCategory(String text, String merchant, TransactionType type) {
    final combined = _removeDiacritics('$text $merchant').toLowerCase();

    // A. Nếu là TIỀN THU (Income)
    if (type == TransactionType.income) {
      if (RegExp(r'(luong|salary|payroll|cty tra|tra luong|thu nhap)').hasMatch(combined)) {
        return ExpenseCategory.salary;
      }
      if (RegExp(r'(thuong|bonus|hoa hong|tip|thuong le)').hasMatch(combined)) {
        return ExpenseCategory.bonus;
      }
      if (RegExp(r'(ba me|bo me|tro cap|phu cap|gia dinh|gui tien|ba gui|me gui)').hasMatch(combined)) {
        return ExpenseCategory.allowance;
      }
      if (RegExp(r'(ban hang|thanh ly|khach tra|don hang|shopee tra|order|store)').hasMatch(combined)) {
        return ExpenseCategory.selling;
      }
      if (RegExp(r'(hoan tien|refund|cashback|tra lai|voucher)').hasMatch(combined)) {
        return ExpenseCategory.refund;
      }
      return ExpenseCategory.other;
    }

    // B. Nếu là TIỀN CHI (Expense)
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
