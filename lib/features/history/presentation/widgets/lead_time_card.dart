import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/history/data/models/history_insights.dart';
import 'package:carpe_diem/features/history/presentation/widgets/overview_stat_card.dart';
import 'package:carpe_diem/features/history/presentation/widgets/section_header.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeadTimeCard extends ConsumerWidget {
  final LeadTimeStats stats;

  const LeadTimeCard({required this.stats, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectProvider);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('LEAD TIME'),
        Row(
          children: [
            Expanded(
              child: OverviewStatCard(
                label: 'Idea → scheduled',
                value: _format(stats.medianIncubationDays),
                icon: Icons.lightbulb_outline,
                color: muted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OverviewStatCard(
                label: 'Scheduled → done',
                value: _format(stats.medianExecutionDays),
                icon: Icons.speed,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Median of ${stats.sample} tasks completed since tracking began.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        for (final p in stats.slowestProjects)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Slowest: ${projects.getById(p.projectId)?.name ?? 'Project'} '
              '(${_format(p.days)})',
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ),
      ],
    );
  }

  String _format(double days) => days < 1 ? '<1d' : '${days.round()}d';
}
