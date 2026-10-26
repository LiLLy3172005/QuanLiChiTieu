import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense_item.dart';
import '../../services/platform_channel_service.dart';
import '../../services/regex_parser_engine.dart';

/// Hộp thoại Review & Form Validation (Slide 26-28 VKU Week 8)
/// Cho phép người dùng kiểm tra lại thông tin máy vừa bóc tách,
/// sửa tay, chuyển đổi loại [Thu / Chi] và validate trước khi lưu vào CSDL.
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
  // Form architecture (Slide 26 VKU)
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  final FocusNode _merchantFocus = FocusNode();
  final FocusNode _amountFocus = FocusNode();

  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;
  late TransactionType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialData.type;
    _merchantController = TextEditingController(text: widget.initialData.merchant);
    _amountController = TextEditingController(
      text: widget.initialData.total > 0
          ? widget.initialData.total.toStringAsFixed(0)
          : '',
    );
    _selectedDate = widget.initialData.date;
    _selectedCategory = widget.initialData.category;
  }

  @override
  void dispose() {
    // Giải phóng bộ nhớ controller & focus node theo Slide 29 VKU
    _merchantController.dispose();
    _amountController.dispose();
    _merchantFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submitForm() {
    // Form validation theo Slide 28 VKU
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final amt = double.parse(_amountController.text.replaceAll(',', '').trim());
      final title = _merchantController.text.trim();

      // Kích hoạt rung phản hồi xúc giác native qua Platform Channels (Slide 37)
      PlatformChannelService.triggerHaptic();

      final item = ExpenseItem.draft(
        title: title,
        amount: amt,
        category: _selectedCategory,
        type: _selectedType,
        imagePath: widget.imagePath,
      );

      widget.onSave(item);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Danh sách danh mục tương ứng theo loại giao dịch
    final availableCategories = ExpenseCategory.values.where((cat) {
      if (_selectedType == TransactionType.income) {
        return cat.isIncomeCategory || cat == ExpenseCategory.other;
      } else {
        return !cat.isIncomeCategory;
      }
    }).toList();

    if (!availableCategories.contains(_selectedCategory)) {
      _selectedCategory = availableCategories.first;
    }

    final isIncome = _selectedType == TransactionType.income;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isIncome ? Icons.add_circle : Icons.receipt_long,
            color: isIncome ? Colors.green.shade700 : const Color(0xFF2C4570),
          ),
          const SizedBox(width: 8),
          Text(isIncome ? 'Xác nhận Khoản Thu' : 'Xác nhận Khoản Chi'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction, // Slide 27 VKU
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Chuyển đổi Loại giao dịch (Khoản Chi vs Khoản Thu)
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Tiền Chi (-)'),
                    icon: Icon(Icons.arrow_downward, color: Colors.red),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Tiền Thu (+)'),
                    icon: Icon(Icons.arrow_upward, color: Colors.green),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (set) {
                  setState(() {
                    _selectedType = set.first;
                  });
                },
              ),
              const SizedBox(height: 14),

              // 2. Preview ảnh hóa đơn nếu có
              if (widget.imagePath != null && widget.imagePath!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: kIsWeb
                        ? Image.network(
                            widget.imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.receipt_long, size: 40, color: Colors.grey),
                            ),
                          )
                        : Image.file(
                            io.File(widget.imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.receipt_long, size: 40, color: Colors.grey),
                            ),
                          ),
                  ),
                ),
              if (widget.imagePath != null && widget.imagePath!.isNotEmpty)
                const SizedBox(height: 12),

              // 3. TextFormField tên đơn vị / đối tác với validation (Slide 27)
              TextFormField(
                controller: _merchantController,
                focusNode: _merchantFocus,
                decoration: InputDecoration(
                  labelText: isIncome ? 'Nguồn thu / Người gửi' : 'Nơi bán / Nội dung GD',
                  prefixIcon: Icon(isIncome ? Icons.person : Icons.storefront),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên giao dịch' : null,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_amountFocus),
              ),
              const SizedBox(height: 12),

              // 4. TextFormField số tiền với custom validation (Slide 27)
              TextFormField(
                controller: _amountController,
                focusNode: _amountFocus,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isIncome ? 'Số tiền thu (VNĐ)' : 'Số tiền chi (VNĐ)',
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: 'đ',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = double.tryParse(v?.replaceAll(',', '').trim() ?? '');
                  return (n == null || n <= 0) ? 'Nhập số tiền hợp lệ (> 0)' : null;
                },
              ),
              const SizedBox(height: 12),

              // 5. Chọn phân loại danh mục
              DropdownButtonFormField<ExpenseCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Hạng mục phân loại',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: availableCategories.map((cat) {
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

              // 6. Chọn ngày tháng
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Thời gian giao dịch',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isIncome ? Colors.green.shade700 : const Color(0xFF2C4570),
            foregroundColor: Colors.white,
          ),
          onPressed: _submitForm, // Slide 28
          child: const Text('Lưu vào CSDL'),
        ),
      ],
    );
  }
}
