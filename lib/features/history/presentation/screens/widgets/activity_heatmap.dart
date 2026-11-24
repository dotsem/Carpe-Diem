import 'dart:math';

import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:carpe_diem/features/history/data/models/history_insights.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActivityHeatmap extends StatelessWidget {
  static const _cell = 14.0;
  static const double _column = _cell + 4;
  static const _headerHeight = 16.0;
  static const _fadeWidth = 20.0;

  final ActivityData data;
  final int firstDayOfWeek;

  const ActivityHeatmap({
    required this.data,
    required this.firstDayOfWeek,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final start = data.start.normalize;
    final end = data.end.normalize;
    final maxCount = data.dailyCounts.values.fold(1, max);
    final dayFormat = DateFormat('MMM d');
    final monthFormat = DateFormat('MMM');
    final weekdays = DateFormat().dateSymbols.SHORTWEEKDAYS;
    final background = Theme.of(context).scaffoldBackgroundColor;

    final weeks = <Widget>[];
    var previousMonth = -1;
    for (
      var weekStart = start.startOfWeek(firstDayOfWeek);
      !weekStart.isAfter(end);
      weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day + 7)
    ) {
      // why: a week belongs to the month of its middle day so adjacent labels never overlap
      final middle = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day + 3,
      );
      final label = middle.month != previousMonth
          ? monthFormat.format(middle)
          : null;
      previousMonth = middle.month;

      weeks.add(
        Column(
          children: [
            SizedBox(
              width: _column,
              height: _headerHeight,
              child: label == null
                  ? null
                  : OverflowBox(
                      maxWidth: 40,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        softWrap: false,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ),
            ),
            for (var i = 0; i < 7; i++)
              _cellFor(
                DateTime(weekStart.year, weekStart.month, weekStart.day + i),
                start,
                end,
                maxCount,
                scheme,
                dayFormat,
              ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: _headerHeight),
            for (var i = 0; i < 7; i++)
              SizedBox(
                height: _column,
                child: Center(
                  child: Text(
                    weekdays[(firstDayOfWeek + i) % 7],
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(children: weeks),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _fadeWidth,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [background, background.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cellFor(
    DateTime day,
    DateTime start,
    DateTime end,
    int maxCount,
    ColorScheme scheme,
    DateFormat format,
  ) {
    if (day.isBefore(start) || day.isAfter(end)) {
      return const SizedBox(width: _column, height: _column);
    }
    final count = data.dailyCounts[day] ?? 0;
    return Tooltip(
      message: '${format.format(day)}: $count',
      child: Container(
        width: _cell,
        height: _cell,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: count == 0
              ? scheme.surfaceContainerHigh
              : AppColors.accent.withValues(
                  alpha: 0.3 + 0.7 * count / maxCount,
                ),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
