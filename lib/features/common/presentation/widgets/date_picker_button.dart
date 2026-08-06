import 'package:carpe_diem/core/constants/app_constants.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/custom_date_picker_dialog.dart';
import 'package:flutter/material.dart';

class DatePickerButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime?> onChanged;
  final IconData? icon;

  const DatePickerButton({
    super.key,
    required this.label,
    required this.date,
    this.firstDate,
    this.lastDate,
    this.icon = Icons.calendar_today,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFirstDate = firstDate ?? AppConstants.appFirstDate;
    final effectiveLastDate = lastDate ?? AppConstants.appLastDate;

    return InkWell(
      onTap: () async {
        DateTime initialDate = date ?? DateTime.now();

        if (initialDate.isBefore(effectiveFirstDate)) {
          initialDate = effectiveFirstDate;
        } else if (initialDate.isAfter(effectiveLastDate)) {
          initialDate = effectiveLastDate;
        }

        final picked = await showDialog<DateTime>(
          context: context,
          builder: (context) => CustomDatePickerDialog(
            initialDate: initialDate,
            firstDate: effectiveFirstDate,
            lastDate: effectiveLastDate,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          suffixIcon: date != null
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => onChanged(null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        child: Text(
          date != null ? '${date!.day}/${date!.month}/${date!.year}' : label,
          style: TextStyle(
            color: date != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
