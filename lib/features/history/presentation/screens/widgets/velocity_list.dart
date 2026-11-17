import 'package:carpe_diem/features/history/data/models/history_insights.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VelocityList extends ConsumerWidget {
  final List<ProjectVelocity> items;

  const VelocityList({super.key, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectProvider);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        for (final v in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color:
                        projects.getById(v.projectId)?.color ??
                        scheme.onSurfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        projects.getById(v.projectId)?.name ?? 'Project',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'usually ${_perWeek(v.usualPerWeek)}/wk, '
                        'now ${_perWeek(v.recentPerWeek)}/wk',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '~${v.shortfall.round()} behind',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _perWeek(double v) =>
      v >= 10 ? v.round().toString() : v.toStringAsFixed(1);
}
