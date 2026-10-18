import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/expense_item.dart';
import '../../providers/expense_provider.dart';
import '../../services/regex_parser_engine.dart';
import '../widgets/expense_summary_card.dart';
import '../widgets/review_dialog.dart';

/// Màn hình chính quản lý chi tiêu (Theo Scaffold Architecture Slide 33 & 34 VKU)
class ExpenseHomeScreen extends ConsumerStatefulWidget {
  const ExpenseHomeScreen({super.key});

  @override
  ConsumerState<ExpenseHomeScreen> createState() => _ExpenseHomeScreenState();
}

class _ExpenseHomeScreenState extends ConsumerState<ExpenseHomeScreen> {
  final ImagePicker _picker = ImagePicker();

  /// Xử lý chụp ảnh hóa đơn hoặc chọn ảnh từ bộ sưu tập
  Future<void> _handleScanReceipt(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      final file = File(pickedFile.path);

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

      // Gọi qua Riverpod Notifier để chạy Google ML Kit & Regex Parser
      final parsed = await ref.read(expenseProvider.notifier).processImageWithOcr(file);

      if (parsed != null && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => ReviewExpenseDialog(
            initialData: parsed,
            imageFile: file,
            onSave: (newItem) {
              ref.read(expenseProvider.notifier).addExpense(newItem);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã lưu chi tiêu vào CSDL Offline!')),
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

  /// Cho phép dán văn bản tin nhắn biến động số dư ngân hàng (Vietcombank, MB, MoMo...)
  void _handlePasteSms() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dán tin nhắn SMS ngân hàng'),
        content: TextField(
          controller: textController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Ví dụ: TK 1234 SD: -65.000VND tai HIGHLANDS COFFEE...',
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

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final totalSpent = ref.watch(totalExpenseAmountProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('VKU Expense Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.sms_outlined),
            tooltip: 'Phân tích SMS biến động số dư',
            onPressed: _handlePasteSms,
          ),
        ],
      ),
      // Body danh sách ảo hóa (Slide 38: ListView.builder)
      body: expenseState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Thẻ tóm tắt tổng số dư chi tiêu đầu trang
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
                        'Tổng chi tiêu tháng này',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormatter.format(totalSpent),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${expenseState.items.length} giao dịch được lưu cục bộ (SQLite)',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Tiêu đề danh sách
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lịch sử chi tiêu',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Vuốt để xóa',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),

                // Danh sách chi tiết Virtualized ListView
                Expanded(
                  child: expenseState.items.isEmpty
                      ? const Center(
                          child: Text(
                            'Chưa có khoản chi tiêu nào.\nHãy chụp hóa đơn để ghi lại nhé!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: expenseState.items.length,
                          itemBuilder: (context, index) {
                            final item = expenseState.items[index];
                            // Slide 24 & 38: Luôn gắn ValueKey(item.id) cho Dismissible
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
                                  SnackBar(
                                    content: Text('Đã xóa "${item.title}"'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: ExpenseSummaryCard(
                                merchant: item.title,
                                amount: item.amount,
                                date: item.timestamp,
                                category: item.category,
                                onTap: () {},
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

      // FAB quét hóa đơn (Slide 34 VKU: FloatingActionButton.extended)
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
