import 'package:carpe_diem/features/history/data/models/history_insights.dart';
import 'package:carpe_diem/features/history/presentation/widgets/overview_stat_card.dart';
import 'package:carpe_diem/features/history/presentation/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PlanAccuracyCard extends StatelessWidget {
  static const _shownDays = 7;

  final HistoryInsights insights;

  const PlanAccuracyCard({required this.insights, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final since = insights.trackingSince;
    final plan = insights.planAccuracy;
    final format = DateFormat('MMM d');

    if (since == null || plan == null || plan.scheduled == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('PLAN ACCURACY'),
          Text(
            since == null
                ? 'Collecting data. Scheduling stats appear after a few days of use.'
                : 'Tracking since ${format.format(since)}. Nothing scheduled in this range yet.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      );
    }

    final days = plan.days.keys.toList()..sort();
    final recent = days.reversed.take(_shownDays).toList();
    final slips = insights.slips;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('PLAN ACCURACY'),
        Row(
          children: [
            Expanded(
              child: OverviewStatCard(
                label: 'Scheduled and done',
                value: '${(plan.done * 100 / plan.scheduled).round()}%',
                icon: Icons.event_available,
                color: scheme.primary,
              ),
            ),
            if (slips != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OverviewStatCard(
                  label: 'Moves per task',
                  value: slips.movesPerTask.toStringAsFixed(1),
                  icon: Icons.redo,
                  color: Colors.orange,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        for (final day in recent)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    format.format(day),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: plan.days[day]!.done / plan.days[day]!.scheduled,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: scheme.surfaceContainerHigh,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${plan.days[day]!.done} / ${plan.days[day]!.scheduled} scheduled',
                  style: TextStyle(color: scheme.onSurface, fontSize: 12),
                ),
              ],
            ),
          ),
        if (slips != null && slips.topTasks.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final t in slips.topTasks)
            Text(
              'Moved ${t.moves}× · ${t.title}',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
        ],
        const SizedBox(height: 8),
        Text(
          'Tracking since ${format.format(since)}.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }
}
