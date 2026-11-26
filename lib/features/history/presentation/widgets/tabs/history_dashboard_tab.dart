import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/history/data/models/history_overview.dart';
import 'package:carpe_diem/features/history/presentation/widgets/activity_section.dart';
import 'package:carpe_diem/features/history/presentation/widgets/overview_stat_card.dart';
import 'package:carpe_diem/features/history/presentation/widgets/project_breakdown_item.dart';
import 'package:carpe_diem/features/history/presentation/widgets/section_header.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryDashboardTab extends ConsumerWidget {
  final HistoryOverview? overview;
  final DateTimeRange range;

  const HistoryDashboardTab({
    required this.overview,
    required this.range,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (overview == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        OverviewStatCard(
          label: 'Total Completed',
          value: overview!.totalCompleted.toString(),
          icon: Icons.check_circle_outline,
          color: AppColors.accent,
          isLarge: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OverviewStatCard(
                label: 'Created',
                value: overview!.totalCreated.toString(),
                icon: Icons.add_task,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OverviewStatCard(
                label: 'Overdue',
                value: overview!.completedLate.toString(),
                icon: Icons.history,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OverviewStatCard(
                label: 'Missed',
                value: overview!.missedDeadlines.toString(),
                icon: Icons.error_outline,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const ActivitySection(),
        const SectionHeader('PROJECT BREAKDOWN'),
        ..._buildProjectBreakdown(context, ref),
      ],
    );
  }

  List<Widget> _buildProjectBreakdown(BuildContext context, WidgetRef ref) {
    final projectState = ref.read(projectProvider);
    final sortedProjects = overview!.tasksByProject.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedProjects.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Center(
            child: Text(
              'No project data',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ];
    }

    final maxTasks = sortedProjects.first.value;

    return sortedProjects.map((entry) {
      final project = entry.key != 'none'
          ? projectState.getById(entry.key)
          : null;
      final projectName = project?.name ?? 'No Project';
      final projectColor = project != null
          ? project.color
          : Theme.of(context).colorScheme.onSurfaceVariant;

      return ProjectBreakdownItem(
        projectName: projectName,
        taskCount: entry.value,
        projectColor: projectColor,
        widthFactor: maxTasks > 0 ? entry.value / maxTasks : 0,
      );
    }).toList();
  }
}
