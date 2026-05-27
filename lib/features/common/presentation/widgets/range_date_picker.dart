import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/utils/date_time_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RangeDatePicker extends StatefulWidget {
  final DateTime initialStart;
  final DateTime initialEnd;
  final DateTime firstDate;
  final DateTime lastDate;
  final Function(DateTimeRange) onRangeSelected;

  const RangeDatePicker({
    super.key,
    required this.initialStart,
    required this.initialEnd,
    required this.firstDate,
    required this.lastDate,
    required this.onRangeSelected,
  });

  @override
  State<RangeDatePicker> createState() => _RangeDatePickerState();
}

class _RangeDatePickerState extends State<RangeDatePicker> {
  late DateTime _viewMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _hoveredDate;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(widget.initialEnd.year, widget.initialEnd.month);
    _startDate = widget.initialStart;
    _endDate = widget.initialEnd;
  }

  void _onDateTap(DateTime date) {
    setState(() {
      if (!_isSelecting) {
        _startDate = date;
        _endDate = null;
        _isSelecting = true;
      } else {
        DateTime start = _startDate!;
        DateTime end = date;
        if (end.isBefore(start)) {
          final temp = start;
          start = end;
          end = temp;
        }
        _startDate = start;
        _endDate = end;
        _isSelecting = false;
        widget.onRangeSelected(DateTimeRange(start: _startDate!, end: _endDate!));
      }
    });
  }

  void _onDateHover(DateTime? date) {
    if (_isSelecting) {
      setState(() {
        _hoveredDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [_buildHeader(), const SizedBox(height: 16), _buildWeekdays(), _buildCalendarGrid()],
    );
  }

  Widget _buildHeader() {
    final title = DateFormat('MMMM yyyy').format(_viewMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.onSurfaceVariant),
          onPressed: _viewMonth.isAfter(widget.firstDate.startOfMonth())
              ? () => setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1))
              : null,
        ),
        Text(
          title,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
          onPressed: _viewMonth.isBefore(widget.lastDate.startOfMonth())
              ? () => setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1))
              : null,
        ),
      ],
    );
  }

  Widget _buildWeekdays() {
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays
          .map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = _viewMonth.startOfMonth();
    final lastDay = _viewMonth.endOfMonth();
    // Monday = 1, Sunday = 7. If Monday is first, offset is weekday - 1.
    final offset = firstDay.weekday - 1;
    final totalDays = lastDay.day;
    final totalCells = offset + totalDays;
    const rows = 6;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4),
      itemCount: rows * 7,
      itemBuilder: (context, index) {
        if (index < offset || index >= totalCells) {
          return const SizedBox.shrink();
        }

        final day = index - offset + 1;
        final date = DateTime(_viewMonth.year, _viewMonth.month, day);
        final isEnabled =
            (date.isAfter(widget.firstDate) || date.isSameDay(widget.firstDate)) &&
            (date.isBefore(widget.lastDate) || date.isSameDay(widget.lastDate));

        return _CalendarDay(
          date: date,
          isEnabled: isEnabled,
          isStart: date.isSameDay(_startDate),
          isEnd: date.isSameDay(_endDate),
          isInRange: _isInRange(date),
          isHovered: _isSelecting && date.isSameDay(_hoveredDate),
          onTap: () => _onDateTap(date),
          onHover: (hovering) => _onDateHover(hovering ? date : null),
        );
      },
    );
  }

  bool _isInRange(DateTime date) {
    if (_startDate != null && _endDate != null) {
      return date.isBetween(_startDate!, _endDate!);
    }
    if (_isSelecting && _startDate != null && _hoveredDate != null) {
      DateTime start = _startDate!;
      DateTime end = _hoveredDate!;
      if (end.isBefore(start)) {
        final temp = start;
        start = end;
        end = temp;
      }
      return date.isBetween(start, end);
    }
    return false;
  }
}

class _CalendarDay extends StatelessWidget {
  final DateTime date;
  final bool isEnabled;
  final bool isStart;
  final bool isEnd;
  final bool isInRange;
  final bool isHovered;
  final VoidCallback onTap;
  final Function(bool) onHover;

  const _CalendarDay({
    required this.date,
    required this.isEnabled,
    required this.isStart,
    required this.isEnd,
    required this.isInRange,
    required this.isHovered,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = date.isSameDay(DateTime.now());

    Color? textColor;
    if (!isEnabled) {
      textColor = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3);
    } else if (isStart || isEnd) {
      textColor = Colors.white;
    } else if (isInRange) {
      textColor = AppColors.accent;
    } else if (isToday) {
      textColor = AppColors.accent;
    } else {
      textColor = Theme.of(context).colorScheme.onSurface;
    }

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            color: _getBackgroundColor(context),
            borderRadius: _getBorderRadius(),
            border: isToday && !isStart && !isEnd ? Border.all(color: AppColors.accent.withValues(alpha: 0.5)) : null,
          ),
          child: Center(
            child: Text(
              date.day.toString(),
              style: TextStyle(
                color: textColor,
                fontWeight: (isStart || isEnd || isToday) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color? _getBackgroundColor(BuildContext context) {
    if (isStart || isEnd) return AppColors.accent;
    if (isInRange) return AppColors.accent.withValues(alpha: 0.2);
    if (isHovered) return Theme.of(context).colorScheme.surfaceContainerHigh;
    return null;
  }

  BorderRadius? _getBorderRadius() {
    if (isStart && isEnd) return BorderRadius.circular(20);
    if (isStart) return const BorderRadius.horizontal(left: Radius.circular(20));
    if (isEnd) return const BorderRadius.horizontal(right: Radius.circular(20));
    if (isInRange) return null;
    return BorderRadius.circular(20);
  }
}
