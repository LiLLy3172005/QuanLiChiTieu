# MINI-PROJECT SHORT TECHNICAL REPORT
**Course:** Cross-Platform Mobile App Development (VKU)  
**Mini-Project Title:** Mini-Project 3: Receipt OCR & Expense Tracker  
**Student Name:** Huỳnh Lưu Ly  
**Student ID (MSSV):** 23IT.B129  
**Class (Lớp học phần):** Phát triển ứng dụng di động đa nền tảng (4)  
**Email:** lyhl.23itb@vku.udn.vn  
**Submission Date:** 19/10/2026  

---

## 1. GENERAL INFORMATION & DELIVERABLE LINKS
* **Student Information:**
  * **Huỳnh Lưu Ly** — MSSV: **23IT.B129** — Role: **Full-Stack Mobile Engineer** — Contribution: **100%**
* **🔗 Live Demo URL:** [https://quanlichitieu1.pages.dev/](https://quanlichitieu1.pages.dev/)
* **💻 GitHub Repository:** [https://github.com/LiLLy3172005/QuanLiChiTieu.git](https://github.com/LiLLy3172005/QuanLiChiTieu.git)
* **📦 Android APK Debug:** Sẵn sàng tại `build/app/outputs/flutter-apk/app-debug.apk`

---

## 2. FEATURE IMPLEMENTATION CHECKLIST (VKU 10-POINT RUBRIC)

| # | Required Feature (Theo Rubric Slide 42) | Status | Implementation Details & Acceptance Level |
|:---:|---|:---:|---|
| 1 | **On-Device OCR & Heuristics (3.5 pts)** | ✅ Complete | Tích hợp `google_mlkit_text_recognition` On-Device OCR hoàn toàn offline. Động cơ `RegexParserEngine` bóc tách tự động: Tên cửa hàng (Merchant), Tổng tiền (Total), Ngày giao dịch (Date), hỗ trợ cả hóa đơn in và tin nhắn SMS biến động số dư (Vietcombank, MB, Techcombank, MoMo). |
| 2 | **Custom Canvas Visualization (2.5 pts)** | ✅ Complete | Tự xây dựng 2 biểu đồ vẽ trực tiếp qua Skia/Impeller Canvas bằng `CustomPainter`: Biểu đồ tròn **Animated Donut Chart** phân bổ chi tiêu theo danh mục và biểu đồ cột **Weekly Bar Chart** trực quan hóa biến động 7 ngày gần nhất. |
| 3 | **State Management & Local DB (2.0 pts)** | ✅ Complete | Kiến trúc **Riverpod 2** (`StateNotifierProvider`) phân tách tầng Presentation và Data. Lưu trữ cục bộ SQLite (`sqflite`) 100% Offline với CRUD đầy đủ; tích hợp bộ nhớ thích ứng In-Memory mượt mà trên Web. |
| 4 | **UI/UX Polish & Review Dialog (1.0 pt)** | ✅ Complete | Giao diện chuẩn **Material Design 3** với tone màu chủ đạo VKU Navy (`#2C4570`), hỗ trợ Light/Dark Theme, danh sách ảo hóa `ListView.builder` kèm thao tác vuốt xóa `Dismissible`. Hộp thoại `ReviewExpenseDialog` cho phép người dùng kiểm tra và hiệu chỉnh thủ công dữ liệu trước khi lưu. |
| 5 | **AI Financial Advisor (Gemini API & Offline)** | ✅ Complete | Tích hợp **Google Gemini 1.5 Flash API** phân tích thói quen tài chính và đề xuất 3 giải pháp tiết kiệm theo quy tắc 50/30/20; tự động chuyển sang bộ quy tắc Heuristics Rule-based khi máy ngoại tuyến (Offline). |

---

## 3. TECHNICAL ARCHITECTURE & PROJECT STRUCTURE

Ứng dụng được tổ chức theo kiến trúc phân lớp sạch sẽ (**Clean Layered Architecture**):

```text
lib/
├── models/
│   └── expense_item.dart         # Model bất biến (const), Dart 3 Records & Switch Expressions
├── services/
│   ├── regex_parser_engine.dart  # Động cơ Regex bóc tách Merchant, Amount, Date & Category
│   ├── ocr_service.dart          # Dịch vụ OCR On-Device Google ML Kit (Mobile) & Web fallback
│   ├── database_service.dart     # SQLite Database Service (Mobile) & In-Memory Web Storage
│   └── gemini_service.dart       # Gemini 1.5 Flash API & Offline Financial Heuristic Engine
├── providers/
│   └── expense_provider.dart     # Riverpod 2 StateNotifier quản lý luồng trạng thái Reactive
├── views/
│   ├── widgets/
│   │   ├── expense_summary_card.dart     # Thẻ hiển thị chi tiêu bài thực hành Slide 45 VKU
│   │   ├── donut_chart_painter.dart      # CustomPainter vẽ Animated Donut Chart
│   │   ├── weekly_bar_chart_painter.dart # CustomPainter vẽ Animated Weekly Bar Chart
│   │   └── review_dialog.dart            # Modal xác thực & chỉnh sửa dữ liệu OCR
│   └── screens/
│       ├── expense_home_screen.dart      # Màn hình chính (Scaffold, FAB Scan, ListView)
│       ├── reports_screen.dart           # Màn hình báo cáo biểu đồ CanvasKit
│       └── ai_advisor_screen.dart        # Màn hình Cố vấn tài chính Gemini AI
└── main.dart                             # Entry point, ThemeData M3 VKU Navy & NavigationBar
```

* **State Lifecycle & Memory Management:** Áp dụng nghiêm ngặt quy tắc bài giảng Slide 28–29: Giải phóng toàn bộ `TextEditingController`, `AnimationController`, `FocusNode` trong hàm `dispose()` để triệt tiêu hiện tượng rò rỉ bộ nhớ (Memory Leak).
* **Kiểm thử tự động:** Xây dựng bộ Unit & Widget Tests với 100% tỷ lệ vượt qua (`All 8 tests passed!`), kiểm thử toàn diện động cơ Regex, tính tương thích của Model và khả năng render thẻ `ExpenseSummaryCard`.

---

## 4. EMPIRICAL EVIDENCE & SCREENSHOTS

1. **Giao diện Màn hình chính (`ExpenseHomeScreen`):**
   * Hiển thị thẻ tóm tắt tổng số dư chi tiêu gradient VKU Navy.
   * Danh sách các khoản chi tiêu ảo hóa hiệu năng cao (`ListView.builder`) với hiệu ứng vuốt xóa `Dismissible`.
   * FloatingActionButton hỗ trợ chụp ảnh trực tiếp từ Camera hoặc chọn ảnh từ thư viện.

2. **Hộp thoại Kiểm tra & Sửa tay (`ReviewExpenseDialog`):**
   * Cho phép xem trước ảnh hóa đơn sau khi quét ML Kit.
   * Người dùng có thể đối soát và chỉnh sửa tên đơn vị bán, số tiền VNĐ, ngày tháng và danh mục trước khi ghi xuống SQLite.

3. **Màn hình Báo cáo Biểu đồ (`ReportsScreen`):**
   * Biểu đồ **Donut Chart** (`CustomPainter`) vẽ động với tâm hiển thị tổng chi tiêu.
   * Biểu đồ cột **Weekly Bar Chart** trực quan hóa biến động ngân sách 7 ngày trong tuần theo thời gian thực.

4. **Trợ lý Tài chính Cá nhân (`AiAdvisorScreen`):**
   * Phân tích lịch sử chi tiêu, cảnh báo các khoản phát sinh bất thường và đưa ra lời khuyên tiết kiệm tiền thiết thực bằng Gemini AI.

---

## 5. TECHNICAL CHALLENGES & RESOLUTIONS

### 1. Thách thức trong xử lý Regex cho Hóa đơn & SMS Ngân hàng
* **Vấn đề:** Các hóa đơn bán lẻ tại Việt Nam thường có chữ viết hoa, viết tắt (`HIGHLANDS`, `CO.OP MART`), trong khi SMS ngân hàng (Vietcombank, MB, Techcombank) thường chứa cả số tiền giao dịch (`-65.000VND`) lẫn số dư khả dụng (`5.450.000VND`). Nếu dùng Regex đơn giản sẽ dễ bị nhầm số dư khả dụng thành số tiền chi tiêu, hoặc từ viết tắt `ND` (Nội dung) bị trùng với chữ `ND` trong `HIGHLANDS`.
* **Giải pháp:** Xây dựng cơ chế Heuristic 2 bước:
  1. Thêm Word Boundary `\bND\b` kết hợp dấu phân cách `:` để chống nhận dạng nhầm tên cửa hàng.
  2. Ưu tiên bóc tách các mẫu số âm biến động số dư (`-\s*\d+`), đồng thời loại trừ triệt để các dòng chứa cụm từ `"kha dung"`, `"so du hien tai"`, `"so du cuoi"`.

### 2. Thách thức tương thích Đa nền tảng (Cross-Platform Web & Mobile)
* **Vấn đề:** Các plugin `google_mlkit_text_recognition` và `sqflite` là native plugin dành riêng cho Android/iOS. Khi đưa mã nguồn lên Cloudflare Pages (Web), app sẽ gặp lỗi runtime crash `MissingPluginException` hoặc `UnsupportedError` dẫn đến màn hình trắng.
* **Giải pháp:** Triển khai **Platform Abstraction Adapter**:
  1. Trong `DatabaseService`: Tích hợp cờ `kIsWeb` để tự động chuyển sang bộ nhớ `In-Memory Storage` khi chạy trên Web/Cloudflare và dùng `sqflite` khi chạy trên thiết bị di động Android.
  2. Trong `OcrService`: Kiểm tra môi trường để tránh khởi tạo đối tượng `TextRecognizer` trên trình duyệt, đồng thời nạp dữ liệu hóa đơn mẫu giúp ban giám khảo có thể trải nghiệm đầy đủ luồng OCR trên Live Demo.
