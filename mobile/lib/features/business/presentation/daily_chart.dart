import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../data/business_models.dart';

/// Sales and expenses for each day, as pairs of bars, oldest on the left,
/// with day labels underneath.
class DailyChart extends StatelessWidget {
  const DailyChart({super.key, required this.days, this.height = 120});

  final List<DayTotals> days;
  final double height;

  /// Weekday names for a week; for longer periods, the date once a week
  /// (counted back from the last day), so labels don't crowd.
  String? _label(int i, String locale) {
    final day = days[i].date;
    if (days.length <= 7) return DateFormat.E(locale).format(day);
    return (days.length - 1 - i) % 7 == 0 ? '${day.day}' : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.localeName == 'en' ? 'en_GB' : context.localeName;
    return Semantics(
      // The figures above the chart give the same information to screen
      // readers; the bars themselves are decorative.
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _DailyChartPainter(
                days: days,
                salesColor: AppColors.deepGreen,
                expensesColor: AppColors.chartExpense,
                baselineColor: AppColors.line,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Row(
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: Text(
                    _label(i, locale) ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: i == days.length - 1
                          ? AppColors.ink
                          : AppColors.muted,
                      fontWeight: i == days.length - 1
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
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
    final barWidth = math.min(12.0, math.max(1.5, slot * 0.36));
    final radius = Radius.circular(math.min(4, barWidth / 2));
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
      bar(center - barWidth - 1.5, days[i].sales, salesColor);
      bar(center + 1.5, days[i].expenses, expensesColor);
    }
  }

  @override
  bool shouldRepaint(_DailyChartPainter old) =>
      old.days != days ||
      old.salesColor != salesColor ||
      old.expensesColor != expensesColor;
}
