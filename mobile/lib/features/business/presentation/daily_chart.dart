import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/business_models.dart';

/// Sales and expenses for each day, as pairs of bars, oldest on the left.
class DailyChart extends StatelessWidget {
  const DailyChart({super.key, required this.days, this.height = 120});

  final List<DayTotals> days;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      // The figures above the chart give the same information to screen
      // readers; the bars themselves are decorative.
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _DailyChartPainter(
            days: days,
            salesColor: scheme.primary,
            expensesColor: scheme.tertiary,
            baselineColor: scheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class _DailyChartPainter extends CustomPainter {
  _DailyChartPainter({
    required this.days,
    required this.salesColor,
    required this.expensesColor,
    required this.baselineColor,
  });

  final List<DayTotals> days;
  final Color salesColor;
  final Color expensesColor;
  final Color baselineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final peak = days.fold<int>(
      0,
      (m, d) => math.max(m, math.max(d.sales, d.expenses)),
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()
        ..color = baselineColor
        ..strokeWidth = 1,
    );
    if (peak == 0) return;

    final slot = size.width / days.length;
    final barWidth = math.max(1.5, slot * 0.36);
    final radius = Radius.circular(math.min(3, barWidth / 2));
    void bar(double left, int value, Color color) {
      if (value == 0) return;
      final h = math.max(2.0, size.height * value / peak);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, size.height - h, barWidth, h),
          topLeft: radius,
          topRight: radius,
        ),
        Paint()..color = color,
      );
    }

    for (var i = 0; i < days.length; i++) {
      final center = slot * i + slot / 2;
      bar(center - barWidth - 0.5, days[i].sales, salesColor);
      bar(center + 0.5, days[i].expenses, expensesColor);
    }
  }

  @override
  bool shouldRepaint(_DailyChartPainter old) =>
      old.days != days ||
      old.salesColor != salesColor ||
      old.expensesColor != expensesColor;
}
