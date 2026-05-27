import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/data/models/task_filter.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FilterBar extends StatelessWidget {
  final TaskFilter filter;
  final VoidCallback onFilterTap;
  final VoidCallback onClearFilter;
  final bool ignoreProjects;
  final bool isBypassed;

  const FilterBar({
    super.key,
    required this.filter,
    required this.onFilterTap,
    required this.onClearFilter,
    this.ignoreProjects = false,
    this.isBypassed = false,
  });

  @override
  Widget build(BuildContext context) {
    if (filter.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ActionChip(
              avatar: Icon(
                isBypassed ? Icons.filter_list_off : Icons.filter_list,
                size: 16,
                color: isBypassed ? Theme.of(context).colorScheme.error.withValues(alpha: 0.5) : null,
              ),
              label: Text(
                isBypassed ? 'Filters Disabled' : 'Filter',
                style: TextStyle(
                  color: isBypassed ? Theme.of(context).colorScheme.error.withValues(alpha: 0.5) : null,
                  decoration: isBypassed ? TextDecoration.lineThrough : null,
                ),
              ),
              onPressed: isBypassed ? null : onFilterTap,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              side: BorderSide.none,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ActionChip(
            avatar: Icon(
              isBypassed ? Icons.filter_list_off : Icons.filter_list,
              size: 16,
              color: isBypassed ? Theme.of(context).colorScheme.error.withValues(alpha: 0.9) : AppColors.accent,
            ),
            label: Text(
              isBypassed ? 'Filters Disabled' : 'Filter',
              style: TextStyle(
                color: isBypassed ? Theme.of(context).colorScheme.error.withValues(alpha: 0.9) : AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: isBypassed ? null : onFilterTap,
            backgroundColor: isBypassed ? Theme.of(context).colorScheme.errorContainer : AppColors.accent.withAlpha(50),
            side: BorderSide(color: isBypassed ? Colors.red : AppColors.accent.withAlpha(50)),
          ),
          const SizedBox(width: 8),
          if (filter.hasPriorityFilter)
            ...filter.priorities.map((p) => _buildChip(context, p.label, p.color, isBypassed: isBypassed)),
          if (filter.hasProjectFilter)
            Consumer<ProjectProvider>(
              builder: (context, provider, _) {
                return Row(
                  children: filter.projectIds.map((id) {
                    final project = provider.getById(id);
                    if (project == null) return const SizedBox.shrink();
                    return _buildChip(
                      context,
                      project.name,
                      project.color,
                      isIgnored: ignoreProjects || isBypassed,
                      isBypassed: isBypassed,
                      tooltip: isBypassed
                          ? 'Filters are temporarily bypassed (Shift+F)'
                          : (ignoreProjects ? 'Project filters are ignored in this screen' : null),
                    );
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
                    return _buildChip(context, label.name, label.color, isBypassed: isBypassed);
                  }).toList(),
                );
              },
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
            onPressed: onClearFilter,
            tooltip: 'Clear filters',
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    String label,
    Color color, {
    bool isIgnored = false,
    bool isBypassed = false,
    String? tooltip,
  }) {
    final chip = Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            decoration: (isIgnored || isBypassed) ? TextDecoration.lineThrough : null,
            color: (isIgnored || isBypassed) ? Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(150) : null,
          ),
        ),
        avatar: CircleAvatar(backgroundColor: (isIgnored || isBypassed) ? color.withAlpha(128) : color, radius: 4),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: chip);
    }
    return chip;
  }
}
