import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/flutter_ext/dialogs/pick_date_range_dialog.dart';
import 'package:carpe_diem/features/history/presentation/providers/first_completed_task_date_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DateRangeButton extends ConsumerWidget {
  final DateTimeRange dateRange;
  final Function(DateTimeRange) onDatePicked;

  const DateRangeButton({
    super.key,
    required this.dateRange,
    required this.onDatePicked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return InkWell(
      onTap: () => _selectDateRange(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 16, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              '${dateFormat.format(dateRange.start)} - ${dateFormat.format(dateRange.end)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final initialDateRange = dateRange;
    final minDate = await ref.read(firstCompletedTaskDateProvider.future);
    final firstDate = minDate ?? now.subtract(const Duration(days: 365 * 10));
    if (!context.mounted) return;

    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => PickDateRangeDialog(
        initialDateRange: initialDateRange,
        firstDate: firstDate,
        lastDate: now,
      ),
    );

    if (picked != null && picked != dateRange) {
      onDatePicked(picked);
    }
  }
}
