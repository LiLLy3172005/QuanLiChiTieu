import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/expense_item.dart';
import '../../providers/expense_provider.dart';
import '../../services/platform_channel_service.dart';

/// Màn hình Chi tiết Giao dịch hỗ trợ GoRouter Dynamic Path Parameter `/expense/:id` (Slide 21 VKU Week 8)
class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const ExpenseDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  int _batteryLevel = -1;

  @override
  void initState() {
    super.initState();
    _loadBatteryInfo();
  }

  Future<void> _loadBatteryInfo() async {
    // Đọc mức pin qua Native Platform Channel (Slide 37 VKU Week 8)
    final level = await PlatformChannelService.getBatteryLevel();
    if (mounted) {
      setState(() => _batteryLevel = level);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(singleExpenseProvider(widget.id));
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormatter = DateFormat('EEEE, dd/MM/yyyy - HH:mm', 'vi_VN');

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết giao dịch')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Không tìm thấy giao dịch này hoặc đã bị xóa.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.pop(), // Slide 22
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    final isIncome = item.isIncome;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isIncome ? 'Chi tiết Khoản Thu' : 'Chi tiết Khoản Chi'),
        backgroundColor: theme.colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(), // GoRouter Navigation Slide 22
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Xóa giao dịch',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xác nhận xóa'),
                  content: Text('Bạn có chắc muốn xóa "${item.title}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                ref.read(expenseProvider.notifier).removeExpense(item.id);
                context.pop(); // Quay lại trang trước qua GoRouter
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Thẻ số tiền nổi bật
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isIncome ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                    child: Icon(
                      item.category.icon,
                      size: 32,
                      color: isIncome ? Colors.green.shade700 : item.category.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.title,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${isIncome ? '+' : '-'} ${currencyFormatter.format(item.amount)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Chip(
                    label: Text(
                      isIncome ? 'Khoản Thu Nhập' : 'Khoản Chi Tiêu',
                      style: TextStyle(
                        color: isIncome ? Colors.green.shade900 : Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Thẻ thông tin chi tiết
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: const Text('Hạng mục'),
                      trailing: Text(
                        item.category.vietnameseName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text('Thời gian'),
                      subtitle: Text(dateFormatter.format(item.timestamp)),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.fingerprint),
                      title: const Text('Mã giao dịch (ID)'),
                      subtitle: Text(item.id, style: const TextStyle(fontSize: 12)),
                    ),
                    if (_batteryLevel >= 0) ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.battery_charging_full, color: Colors.teal),
                        title: const Text('Trạng thái pin thiết bị (Native MethodChannel)'),
                        trailing: Text(
                          '$_batteryLevel%',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Văn bản OCR gốc nếu có
            if (item.rawOcrText != null && item.rawOcrText!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.document_scanner, size: 20),
                          SizedBox(width: 8),
                          Text('Văn bản OCR / SMS gốc', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.rawOcrText!,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
