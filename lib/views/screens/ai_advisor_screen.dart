import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/expense_provider.dart';

/// Màn hình Gemini AI Cố Vấn Tài Chính & Hướng dẫn Tiết kiệm tiền
class AiAdvisorScreen extends ConsumerStatefulWidget {
  const AiAdvisorScreen({super.key});

  @override
  ConsumerState<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends ConsumerState<AiAdvisorScreen> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  bool _showApiKeyInput = false;

  @override
  void dispose() {
    _questionController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _triggerAnalysis() {
    FocusScope.of(context).unfocus();
    final customPrompt = _questionController.text.trim();
    ref.read(expenseProvider.notifier).requestAiAdvice(
          customPrompt: customPrompt.isEmpty ? null : customPrompt,
        );
  }

  void _saveApiKey() {
    final key = _apiKeyController.text.trim();
    if (key.isNotEmpty) {
      ref.read(expenseProvider.notifier).setApiKey(key);
      setState(() => _showApiKeyInput = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật Gemini API Key!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini AI Tiết Kiệm Tiền'),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.key),
            tooltip: 'Cài đặt Gemini API Key',
            onPressed: () {
              setState(() => _showApiKeyInput = !_showApiKeyInput);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner chào đón
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trợ lý tài chính thông minh',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phân tích hóa đơn, phát hiện lãng phí và đưa ra lộ trình tiết kiệm tiền cá nhân hóa.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ô nhập API Key ẩn/hiện
            if (_showApiKeyInput)
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cấu hình Google Gemini API Key:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _apiKeyController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'Nhập API key từ Google AI Studio...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _showApiKeyInput = false),
                            child: const Text('Ẩn'),
                          ),
                          ElevatedButton(
                            onPressed: _saveApiKey,
                            child: const Text('Lưu Key'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Nhập câu hỏi tư vấn cụ thể
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'VD: Làm sao để tôi tiết kiệm 500k trong tuần tới?',
                prefixIcon: const Icon(Icons.help_outline),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  color: theme.colorScheme.primary,
                  onPressed: _triggerAnalysis,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _triggerAnalysis(),
            ),

            const SizedBox(height: 16),

            // Nút bấm phân tích nhanh
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C4570),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: expenseState.isAiLoading ? null : _triggerAnalysis,
              icon: expenseState.isAiLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.psychology),
              label: Text(
                expenseState.isAiLoading ? 'AI đang phân tích...' : 'Phân tích chi tiêu & Gợi ý tiết kiệm',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),

            // Khu vực hiển thị lời khuyên từ Gemini / Offline engine
            if (expenseState.aiAdvice != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tips_and_updates, color: Colors.amber, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Kế Hoạch Tiết Kiệm Tiền',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      SelectableText(
                        expenseState.aiAdvice!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
