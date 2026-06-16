import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterBar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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

    final projectState = ref.watch(projectProvider);
    final labelState = ref.watch(labelProvider);

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
          if (filter.prioritiesIncluded.isNotEmpty)
            ...filter.prioritiesIncluded.map((p) => _buildChip(context, p.label, p.color, isBypassed: isBypassed)),
          if (filter.prioritiesExcluded.isNotEmpty)
            ...filter.prioritiesExcluded.map(
              (p) => _buildChip(context, p.label, p.color, isExcluded: true, isBypassed: isBypassed),
            ),
          if (filter.projectIdsIncluded.isNotEmpty)
            Row(
              children: filter.projectIdsIncluded.map((id) {
                final project = projectState.getById(id);
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
            ),
          if (filter.projectIdsExcluded.isNotEmpty)
            Row(
              children: filter.projectIdsExcluded.map((id) {
                final project = projectState.getById(id);
                if (project == null) return const SizedBox.shrink();
                return _buildChip(
                  context,
                  project.name,
                  project.color,
                  isExcluded: true,
                  isIgnored: ignoreProjects || isBypassed,
                  isBypassed: isBypassed,
                  tooltip: isBypassed
                      ? 'Filters are temporarily bypassed (Shift+F)'
                      : (ignoreProjects ? 'Project filters are ignored in this screen' : null),
                );
              }).toList(),
            ),
          if (filter.labelIdsIncluded.isNotEmpty)
            Row(
              children: filter.labelIdsIncluded.map((id) {
                Label label = labelState.labels.firstWhere((l) => l.id == id, orElse: () => Label.empty());
                if (label.isEmpty) return const SizedBox.shrink();
                return _buildChip(context, label.name, label.color, isBypassed: isBypassed);
              }).toList(),
            ),
          if (filter.labelIdsExcluded.isNotEmpty)
            Row(
              children: filter.labelIdsExcluded.map((id) {
                Label label = labelState.labels.firstWhere((l) => l.id == id, orElse: () => Label.empty());
                if (label.isEmpty) return const SizedBox.shrink();
                return _buildChip(context, label.name, label.color, isExcluded: true, isBypassed: isBypassed);
              }).toList(),
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
    bool isExcluded = false,
    String? tooltip,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final includedColor = isDark ? Colors.greenAccent : Colors.green.shade700;
    final excludedColor = isDark ? Colors.redAccent : Colors.red.shade700;

    final displayLabel = isExcluded ? '- $label' : '+ $label';
    final textColor = (isIgnored || isBypassed)
        ? Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(150)
        : (isExcluded ? excludedColor : includedColor);

    final backgroundColor = (isIgnored || isBypassed)
        ? Theme.of(context).colorScheme.surfaceContainerHigh
        : (isExcluded ? excludedColor.withAlpha(30) : includedColor.withAlpha(30));

    final side = (isIgnored || isBypassed)
        ? BorderSide.none
        : BorderSide(color: isExcluded ? excludedColor : includedColor);

    final textStyle = TextStyle(
      fontSize: 12,
      fontWeight: (isIgnored || isBypassed) ? FontWeight.normal : FontWeight.bold,
      decoration: (isIgnored || isBypassed || isExcluded) ? TextDecoration.lineThrough : null,
      color: textColor,
    );

    final chip = Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(displayLabel, style: textStyle),
        avatar: CircleAvatar(backgroundColor: (isIgnored || isBypassed) ? color.withAlpha(128) : color, radius: 4),
        backgroundColor: backgroundColor,
        side: side,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        visualDensity: VisualDensity.compact,
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: chip);
    }
    return chip;
  }
}
