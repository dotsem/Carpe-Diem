import 'package:carpe_diem/core/theme/app_theme.dart';

import 'package:carpe_diem/data/models/task_filter.dart';
import 'package:carpe_diem/providers/label_provider.dart';
import 'package:carpe_diem/providers/project_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FilterBar extends StatelessWidget {
  final TaskFilter filter;
  final VoidCallback onFilterTap;
  final VoidCallback onClearFilter;

  const FilterBar({super.key, required this.filter, required this.onFilterTap, required this.onClearFilter});

  @override
  Widget build(BuildContext context) {
    if (filter.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ActionChip(
              avatar: const Icon(Icons.filter_list, size: 16),
              label: const Text('Filter'),
              onPressed: onFilterTap,
              backgroundColor: AppColors.surfaceLight,
              side: BorderSide.none,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Row(
        children: [
          ActionChip(
            avatar: const Icon(Icons.filter_list, size: 16, color: AppColors.accent),
            label: const Text(
              'Filter',
              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
            ),
            onPressed: onFilterTap,
            backgroundColor: AppColors.accent.withAlpha(25),
            side: BorderSide(color: AppColors.accent.withAlpha(50)),
          ),
          const SizedBox(width: 8),
          if (filter.hasPriorityFilter) ...filter.priorities.map((p) => _buildChip(p.label, p.color)),
          if (filter.hasProjectFilter)
            Consumer<ProjectProvider>(
              builder: (context, provider, _) {
                return Row(
                  children: filter.projectIds.map((id) {
                    final project = provider.getById(id);
                    if (project == null) return const SizedBox.shrink();
                    return _buildChip(project.name, project.color);
                  }).toList(),
                );
              },
            ),
          if (filter.hasLabelFilter)
            Consumer<LabelProvider>(
              builder: (context, provider, _) {
                return Row(
                  children: filter.labelIds.map((id) {
                    final label = provider.labels.firstWhere(
                      (l) => l.id == id,
                      orElse: () => throw Exception('Label not found'),
                    );
                    return _buildChip(label.name, label.color);
                  }).toList(),
                );
              },
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
            onPressed: onClearFilter,
            tooltip: 'Clear filters',
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        avatar: CircleAvatar(backgroundColor: color, radius: 4),
        backgroundColor: AppColors.surfaceLight,
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
