import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/common/sized_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/range_date_picker.dart';
import 'package:flutter/material.dart';

class PickDateRangeDialog extends StatefulWidget {
  final DateTimeRange initialDateRange;
  final DateTime firstDate;
  final DateTime lastDate;

  const PickDateRangeDialog({
    super.key,
    required this.initialDateRange,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<PickDateRangeDialog> createState() => _PickDateRangeDialogState();
}

class _PickDateRangeDialogState extends State<PickDateRangeDialog> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDateRange.start;
    _endDate = widget.initialDateRange.end;
  }

  void _submit() {
    Navigator.of(context).pop(DateTimeRange(start: _startDate, end: _endDate));
  }

  @override
  Widget build(BuildContext context) {
    return SizedDialog(
      onSubmit: _submit,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: 330,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _DateTab(label: 'START', date: _startDate, isSelected: true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DateTab(label: 'END', date: _endDate, isSelected: true),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: RangeDatePicker(
                initialStart: _startDate,
                initialEnd: _endDate,
                firstDate: widget.firstDate,
                lastDate: widget.lastDate,
                onRangeSelected: (range) {
                  setState(() {
                    _startDate = range.start;
                    _endDate = range.end;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTab extends StatelessWidget {
  final String label;
  final DateTime date;
  final bool isSelected;

  const _DateTab({required this.label, required this.date, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: isSelected ? AppColors.accent : Colors.transparent, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.accent : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${date.day}/${date.month}/${date.year}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
