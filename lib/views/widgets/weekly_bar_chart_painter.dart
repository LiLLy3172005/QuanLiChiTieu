import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// CustomPainter vẽ biểu đồ cột biến động chi tiêu 7 ngày trong tuần
/// Đáp ứng yêu cầu kỹ thuật Slide 42 VKU Rubric (Custom Canvas Visualization)
class WeeklyBarChartPainter extends CustomPainter {
  final Map<int, double> dailyExpenses; // Map index 0..6 tương ứng 7 ngày
  final double animationValue;
  final Color barColor;
  final Color gridColor;

  WeeklyBarChartPainter({
    required this.dailyExpenses,
    required this.animationValue,
    required this.barColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const bottomPadding = 24.0;
    const topPadding = 16.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final chartWidth = size.width;

    // Tìm giá trị chi tiêu lớn nhất trong tuần để làm mốc tính tỷ lệ chiều cao cột
    double maxExpense = 1.0;
    for (final val in dailyExpenses.values) {
      if (val > maxExpense) maxExpense = val;
    }

    final barWidth = chartWidth / 7 * 0.45;
    final stepX = chartWidth / 7;

    // 1. Vẽ các đường lưới phụ ngang (Grid lines)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 3; i++) {
      final y = topPadding + (chartHeight / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    // 2. Vẽ 7 cột chi tiêu
    final now = DateTime.now();
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < 7; i++) {
      final amount = dailyExpenses[i] ?? 0.0;
      final targetHeight = (amount / maxExpense) * chartHeight;
      final currentHeight = targetHeight * animationValue;

      final centerX = stepX * i + stepX / 2;
      final left = centerX - barWidth / 2;
      final top = topPadding + (chartHeight - currentHeight);

      // Tạo gradient màu cho cột
      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            barColor,
            barColor.withOpacity(0.4),
          ],
        ).createShader(Rect.fromLTWH(left, top, barWidth, currentHeight))
        ..style = PaintingStyle.fill;

      // Vẽ cột có bo tròn đầu trên
      final rrect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, top, barWidth, math.max(2.0, currentHeight)),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      canvas.drawRRect(rrect, barPaint);

      // 3. Vẽ nhãn thứ trong tuần ở chân cột
      final dayDate = now.subtract(Duration(days: 6 - i));
      final dayLabel = DateFormat('E', 'vi_VN').format(dayDate); // T2, T3, T4...

      textPainter.text = TextSpan(
        text: dayLabel,
        style: TextStyle(
          color: i == 6 ? barColor : Colors.grey.shade600,
          fontWeight: i == 6 ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, size.height - bottomPadding + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.dailyExpenses != dailyExpenses;
  }
}

/// Widget bọc WeeklyBarChart có gắn Animation mượt mà
class AnimatedWeeklyBarChart extends StatefulWidget {
  final Map<int, double> dailyExpenses;

  const AnimatedWeeklyBarChart({
    super.key,
    required this.dailyExpenses,
  });

  @override
  State<AnimatedWeeklyBarChart> createState() => _AnimatedWeeklyBarChartState();
}

class _AnimatedWeeklyBarChartState extends State<AnimatedWeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedWeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dailyExpenses != widget.dailyExpenses) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 180),
          painter: WeeklyBarChartPainter(
            dailyExpenses: widget.dailyExpenses,
            animationValue: _animation.value,
            barColor: theme.colorScheme.primary,
            gridColor: theme.colorScheme.outlineVariant.withOpacity(0.4),
          ),
        );
      },
    );
  }
}
