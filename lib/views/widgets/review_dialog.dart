import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense_item.dart';
import '../../services/regex_parser_engine.dart';

/// Hộp thoại Review & Manual Correction (Slide 42: UI/UX Polish Rubric)
/// Cho phép người dùng kiểm tra lại thông tin máy vừa bóc tách và sửa tay trước khi lưu SQLite
class ReviewExpenseDialog extends StatefulWidget {
  final ParsedReceiptData initialData;
  final String? imagePath;
  final Function(ExpenseItem item) onSave;

  const ReviewExpenseDialog({
    super.key,
    required this.initialData,
    this.imagePath,
    required this.onSave,
  });

  @override
  State<ReviewExpenseDialog> createState() => _ReviewExpenseDialogState();
}

class _ReviewExpenseDialogState extends State<ReviewExpenseDialog> {
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(text: widget.initialData.merchant);
    _amountController = TextEditingController(
      text: widget.initialData.total.toStringAsFixed(0),
    );
    _selectedDate = widget.initialData.date;
    _selectedCategory = widget.initialData.category;
  }

  @override
  void dispose() {
    // Luôn giải phóng TextEditingController theo chuẩn Slide 29 & 46
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.fact_check, color: Color(0xFF2C4570)),
          SizedBox(width: 8),
          Text('Xác nhận & Kiểm tra'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview ảnh hóa đơn nếu có (tương thích cả Web lẫn Mobile)
            if (widget.imagePath != null && widget.imagePath!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: kIsWeb
                      ? Image.network(
                          widget.imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                          ),
                        )
                      : Image.file(
                          io.File(widget.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                          ),
                        ),
                ),
              ),
            const SizedBox(height: 12),

            // Nhập / Sửa tên cửa hàng
            TextField(
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: 'Tên nơi bán / Nội dung GD',
                prefixIcon: Icon(Icons.storefront),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Nhập / Sửa số tiền
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền (VNĐ)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Chọn phân loại chi tiêu
            DropdownButtonFormField<ExpenseCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Hạng mục chi tiêu',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: ExpenseCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Row(
                    children: [
                      Icon(cat.icon, color: cat.color, size: 18),
                      const SizedBox(width: 8),
                      Text(cat.vietnameseName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (cat) {
                if (cat != null) setState(() => _selectedCategory = cat);
              },
            ),
            const SizedBox(height: 12),

            // Chọn ngày tháng
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Ngày giao dịch',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2C4570),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final amt = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
            final item = ExpenseItem.draft(
              title: _merchantController.text.trim().isEmpty
                  ? 'Chi tiêu'
                  : _merchantController.text.trim(),
              amount: amt,
              category: _selectedCategory,
              imagePath: widget.imagePath,
            );
            widget.onSave(item);
            Navigator.of(context).pop();
          },
          child: const Text('Lưu vào CSDL'),
        ),
      ],
    );
  }
}
