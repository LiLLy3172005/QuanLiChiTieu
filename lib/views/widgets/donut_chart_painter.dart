import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense_item.dart';

/// CustomPainter vẽ biểu đồ bánh Donut (Donut Chart) phân bổ chi tiêu
/// Chuẩn kỹ thuật Slide 22, 42: Sử dụng trực tiếp Skia/Impeller Canvas với Paint() & drawArc()
class DonutChartPainter extends CustomPainter {
  final Map<ExpenseCategory, double> data;
  final double animationValue; // Giá trị từ AnimationController (0.0 -> 1.0)
  final Color emptyColor;

  DonutChartPainter({
    required this.data,
    required this.animationValue,
    this.emptyColor = const Color(0xFFE0E0E0),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 16;
    const strokeWidth = 28.0;

    final total = data.values.fold(0.0, (sum, val) => sum + val);

    // Nếu chưa có dữ liệu chi tiêu, vẽ 1 vòng tròn rỗng màu xám
    if (total == 0) {
      final basePaint = Paint()
        ..color = emptyColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, basePaint);
      return;
    }

    // Góc bắt đầu quét: -pi / 2 (đỉnh 12h)
    double startAngle = -math.pi / 2;

    // Duyệt qua từng danh mục để vẽ các cung tròn (Arc)
    data.forEach((category, amount) {
      if (amount <= 0) return;

      // Tính góc quét tương ứng với tỷ lệ phần trăm và nhân với tiến trình animation
      final sweepAngle = (amount / total) * 2 * math.pi * animationValue;

      final paint = Paint()
        ..color = category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Trừ 1 khoảng nhỏ để tạo khe hở giữa các lát bánh nếu có nhiều danh mục
      final segmentSweep = (data.length > 1) ? math.max(0.0, sweepAngle - 0.04) : sweepAngle;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    });
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.data != data;
  }
}

/// Widget hoàn chỉnh bọc Animated Donut Chart kèm tâm hiển thị tổng chi tiêu
class AnimatedDonutChart extends StatefulWidget {
  final Map<ExpenseCategory, double> data;
  final double totalAmount;

  const AnimatedDonutChart({
    super.key,
    required this.data,
    required this.totalAmount,
  });

  @override
  State<AnimatedDonutChart> createState() => _AnimatedDonutChartState();
}

class _AnimatedDonutChartState extends State<AnimatedDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Khởi tạo AnimationController theo chu kỳ frame 120Hz của Flutter (Slide 9 & 28)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalAmount != widget.totalAmount) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    // Luôn dispose AnimationController để tránh Memory Leak (Slide 29)
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.compactCurrency(locale: 'vi_VN', symbol: 'đ');

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(220, 220),
              painter: DonutChartPainter(
                data: widget.data,
                animationValue: _animation.value,
              ),
            ),
            // Text hiển thị ở tâm của Donut Chart
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tổng chi',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(widget.totalAmount),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
