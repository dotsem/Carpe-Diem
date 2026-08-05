import 'package:carpe_diem/features/common/presentation/widgets/date_picker_button.dart';
import 'package:carpe_diem/features/common/presentation/widgets/section_card.dart';
import 'package:flutter/material.dart';

class PlanningSection extends StatelessWidget {
  final DateTime? scheduledDate;
  final ValueChanged<DateTime?> onScheduledChanged;
  final DateTime? deadline;
  final ValueChanged<DateTime?> onDeadlineChanged;
  final int maxPlanningDays;

  const PlanningSection({
    super.key,
    required this.scheduledDate,
    required this.onScheduledChanged,
    required this.deadline,
    required this.onDeadlineChanged,
    required this.maxPlanningDays,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      margin: const EdgeInsets.symmetric(vertical: 8),
      items: [
        SectionItem(
          icon: Icons.calendar_today_outlined,
          title: 'Planning & Dates',
          child: Row(
            children: [
              Expanded(
                child: DatePickerButton(
                  label: 'Scheduled',
                  date: scheduledDate,
                  onChanged: onScheduledChanged,
                  lastDate: DateTime.now().add(Duration(days: maxPlanningDays)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DatePickerButton(
                  label: 'Deadline',
                  icon: Icons.flag_outlined,
                  date: deadline,
                  onChanged: onDeadlineChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
