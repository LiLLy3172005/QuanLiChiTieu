import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/expense_item.dart';
import '../../providers/expense_provider.dart';
import '../../services/platform_channel_service.dart';
import '../../services/regex_parser_engine.dart';
import '../widgets/expense_summary_card.dart';
import '../widgets/review_dialog.dart';

/// Màn hình chính quản lý Thu - Chi (Scaffold Architecture Slide 33 & 34 VKU)
class ExpenseHomeScreen extends ConsumerStatefulWidget {
  const ExpenseHomeScreen({super.key});

  @override
  ConsumerState<ExpenseHomeScreen> createState() => _ExpenseHomeScreenState();
}

class _ExpenseHomeScreenState extends ConsumerState<ExpenseHomeScreen> {
  final ImagePicker _picker = ImagePicker();
  int _filterIndex = 0; // 0: Tất cả, 1: Chi tiêu (-), 2: Thu nhập (+)
  int _batteryLevel = -1;

  @override
  void initState() {
    super.initState();
    _checkBattery();
  }

  Future<void> _checkBattery() async {
    final level = await PlatformChannelService.getBatteryLevel();
    if (mounted) {
      setState(() => _batteryLevel = level);
    }
  }

  /// Xử lý chụp ảnh hóa đơn hoặc chọn ảnh từ bộ sưu tập
  Future<void> _handleScanReceipt(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (pickedFile == null) return;
      final imagePath = pickedFile.path;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              SizedBox(width: 16),
              Text('Đang quét OCR trên thiết bị (ML Kit)...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final parsed = await ref.read(expenseProvider.notifier).processImageWithOcr(imagePath);

      if (parsed != null && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => ReviewExpenseDialog(
            initialData: parsed,
            imagePath: imagePath,
            onSave: (newItem) {
              ref.read(expenseProvider.notifier).addExpense(newItem);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    newItem.isIncome
                        ? 'Đã ghi nhận Khoản Thu vào CSDL!'
                        : 'Đã lưu Khoản Chi vào CSDL!',
                  ),
                ),
              );
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể quét ảnh: $e')),
        );
      }
    }
  }

  /// Dán tin nhắn SMS biến động số dư ngân hàng (Tự động nhận diện Thu / Chi)
  void _handlePasteSms() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dán tin nhắn SMS Ngân hàng'),
        content: TextField(
          controller: textController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Ví dụ:\n- Chi: SD: -65.000VND tai HIGHLANDS...\n- Thu: SD: +2.000.000VND tu CTY ABC...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final raw = textController.text.trim();
              Navigator.pop(ctx);
              if (raw.isNotEmpty) {
                final parsed = RegexParserEngine.parse(raw);
                showDialog(
                  context: context,
                  builder: (_) => ReviewExpenseDialog(
                    initialData: parsed,
                    onSave: (item) {
                      ref.read(expenseProvider.notifier).addExpense(item);
                    },
                  ),
                );
              }
            },
            child: const Text('Phân tích'),
          ),
        ],
      ),
    );
  }

  /// Thêm thủ công nhanh
  void _handleManualAdd() {
    showDialog(
      context: context,
      builder: (_) => ReviewExpenseDialog(
        initialData: (
          merchant: '',
          total: 0.0,
          date: DateTime.now(),
          category: ExpenseCategory.other,
          type: TransactionType.expense,
        ),
        onSave: (item) {
          ref.read(expenseProvider.notifier).addExpense(item);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final totalSpent = ref.watch(totalExpenseAmountProvider);
    final totalIncome = ref.watch(totalIncomeProvider);
    final netBalance = ref.watch(netBalanceProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Lọc danh sách theo Tab
    final filteredItems = expenseState.items.where((item) {
      if (_filterIndex == 1) return item.isExpense;
      if (_filterIndex == 2) return item.isIncome;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('VKU Expense & Income'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_batteryLevel >= 0)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Row(
                  children: [
                    const Icon(Icons.battery_std, size: 18),
                    Text('$_batteryLevel%', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm giao dịch thủ công',
            onPressed: _handleManualAdd,
          ),
          IconButton(
            icon: const Icon(Icons.sms_outlined),
            tooltip: 'Phân tích SMS biến động số dư',
            onPressed: _handlePasteSms,
          ),
        ],
      ),
      body: expenseState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. Thẻ Tóm tắt Số dư Ví & Cán cân Thu - Chi
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C4570), Color(0xFF1E88E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Số dư ròng khả dụng (Net Balance)',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currencyFormatter.format(netBalance),
                        style: TextStyle(
                          color: netBalance >= 0 ? Colors.white : Colors.amberAccent,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Tổng thu
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Tổng Thu', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  Text(
                                    currencyFormatter.format(totalIncome),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Tổng chi
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_downward, color: Colors.redAccent, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Tổng Chi', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  Text(
                                    currencyFormatter.format(totalSpent),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Thanh lọc: Tất cả / Chi tiêu / Thu nhập
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Tất cả')),
                      ButtonSegment(value: 1, label: Text('Khoản Chi')),
                      ButtonSegment(value: 2, label: Text('Khoản Thu')),
                    ],
                    selected: {_filterIndex},
                    onSelectionChanged: (set) {
                      setState(() => _filterIndex = set.first);
                    },
                  ),
                ),

                const SizedBox(height: 6),

                // 3. Danh sách giao dịch ảo hóa ListView.builder (Slide 38 VKU)
                Expanded(
                  child: filteredItems.isEmpty
                      ? Center(
                          child: Text(
                            _filterIndex == 2
                                ? 'Chưa có khoản thu nào.\nHãy thêm hoặc dán SMS nhận tiền nhé!'
                                : 'Chưa có giao dịch nào.\nHãy quét hóa đơn để bắt đầu!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return Dismissible(
                              key: ValueKey(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.red.shade400,
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              onDismissed: (_) {
                                ref.read(expenseProvider.notifier).removeExpense(item.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đã xóa "${item.title}"')),
                                );
                              },
                              child: ExpenseSummaryCard(
                                merchant: item.title,
                                amount: item.amount,
                                date: item.timestamp,
                                category: item.category,
                                type: item.type,
                                onTap: () {
                                  // Điều hướng sang màn hình chi tiết qua GoRouter (Slide 22 VKU Week 8)
                                  context.push('/expense/${item.id}');
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

      // FAB Quét hóa đơn (Slide 34)
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2C4570),
        foregroundColor: Colors.white,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (ctx) => SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Chụp ảnh hóa đơn mới'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleScanReceipt(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Chọn ảnh hóa đơn từ thư viện'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleScanReceipt(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ),
          );
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan Receipt'),
      ),
    );
  }
}
