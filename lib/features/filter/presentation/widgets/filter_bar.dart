import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/common/tri_state_filter_chip.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
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
      final errColor = Theme.of(
        context,
      ).colorScheme.error.withValues(alpha: 0.5);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ActionChip(
              avatar: Icon(
                isBypassed ? Icons.filter_list_off : Icons.filter_list,
                size: 16,
                color: isBypassed ? errColor : null,
              ),
              label: Text(
                isBypassed ? 'Filters Disabled' : 'Filter',
                style: TextStyle(
                  color: isBypassed ? errColor : null,
                  decoration: isBypassed ? TextDecoration.lineThrough : null,
                ),
              ),
              onPressed: isBypassed ? null : onFilterTap,
              mouseCursor: isBypassed
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.click,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHigh,
              side: BorderSide.none,
            ),
          ],
        ),
      );
    }

    final projectState = ref.watch(projectProvider);
    final labelState = ref.watch(labelProvider);
    final tagState = ref.watch(tagProvider);
    final filterNotifier = ref.read(filterProvider.notifier);
    final errColor9 = Theme.of(
      context,
    ).colorScheme.error.withValues(alpha: 0.9);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ActionChip(
            avatar: Icon(
              isBypassed ? Icons.filter_list_off : Icons.filter_list,
              size: 16,
              color: isBypassed ? errColor9 : AppColors.accent,
            ),
            label: Text(
              isBypassed ? 'Filters Disabled' : 'Filter',
              style: TextStyle(
                color: isBypassed ? errColor9 : AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: isBypassed ? null : onFilterTap,
            mouseCursor: isBypassed
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            backgroundColor: isBypassed
                ? Theme.of(context).colorScheme.errorContainer
                : AppColors.accent.withAlpha(50),
            side: BorderSide(
              color: isBypassed ? Colors.red : AppColors.accent.withAlpha(50),
            ),
          ),
          const SizedBox(width: 8),
          if (filter.isUrgent == true)
            _buildChip(
              context,
              'Urgent',
              AppColors.error,
              isBypassed: isBypassed,
              onTap: () => filterNotifier.setUrgentFilter(null),
            ),
          if (filter.isUrgent == false)
            _buildChip(
              context,
              'Urgent',
              AppColors.error,
              isExcluded: true,
              isBypassed: isBypassed,
              onTap: () => filterNotifier.setUrgentFilter(null),
            ),
          if (filter.projectIdsIncluded.isNotEmpty)
            ...filter.projectIdsIncluded.map((id) {
              final project = projectState.getById(id);
              if (project == null) return const SizedBox.shrink();
              return _buildChip(
                context,
                project.name,
                project.color,
                isIgnored: ignoreProjects || isBypassed,
                isBypassed: isBypassed,
                onTap: () => filterNotifier.removeProjectFilter(id),
                tooltip: _projectTooltip(ignoreProjects, isBypassed),
              );
            }),
          if (filter.projectIdsExcluded.isNotEmpty)
            ...filter.projectIdsExcluded.map((id) {
              final project = projectState.getById(id);
              if (project == null) return const SizedBox.shrink();
              return _buildChip(
                context,
                project.name,
                project.color,
                isExcluded: true,
                isIgnored: ignoreProjects || isBypassed,
                isBypassed: isBypassed,
                onTap: () => filterNotifier.removeProjectFilter(id),
                tooltip: _projectTooltip(ignoreProjects, isBypassed),
              );
            }),
          if (filter.labelIdsIncluded.isNotEmpty)
            ...filter.labelIdsIncluded.map((id) {
              final label = labelState.labels.firstWhere(
                (l) => l.id == id,
                orElse: () => Label.empty(),
              );
              if (label.isEmpty) return const SizedBox.shrink();
              return _buildChip(
                context,
                label.name,
                label.color,
                isBypassed: isBypassed,
                onTap: () => filterNotifier.removeLabelFilter(id),
              );
            }),
          if (filter.labelIdsExcluded.isNotEmpty)
            ...filter.labelIdsExcluded.map((id) {
              final label = labelState.labels.firstWhere(
                (l) => l.id == id,
                orElse: () => Label.empty(),
              );
              if (label.isEmpty) return const SizedBox.shrink();
              return _buildChip(
                context,
                label.name,
                label.color,
                isExcluded: true,
                isBypassed: isBypassed,
                onTap: () => filterNotifier.removeLabelFilter(id),
              );
            }),
          if (filter.tagIdsIncluded.isNotEmpty)
            ...filter.tagIdsIncluded.map((id) {
              final tag = tagState.tags.firstWhere(
                (t) => t.id == id,
                orElse: () => const Tag(id: '', name: ''),
              );
              if (tag.isEmpty) return const SizedBox.shrink();
              return _buildChip(
                context,
                tag.name,
                Theme.of(context).colorScheme.primary,
                isBypassed: isBypassed,
                onTap: () => filterNotifier.removeTagFilter(id),
              );
            }),
          if (filter.tagIdsExcluded.isNotEmpty)
            ...filter.tagIdsExcluded.map((id) {
              final tag = tagState.tags.firstWhere(
                (t) => t.id == id,
                orElse: () => const Tag(id: '', name: ''),
              );
              if (tag.isEmpty) return const SizedBox.shrink();
              return _buildChip(
                context,
                tag.name,
                Theme.of(context).colorScheme.primary,
                isExcluded: true,
                isBypassed: isBypassed,
                onTap: () => filterNotifier.removeTagFilter(id),
              );
            }),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TriStateFilterChip(
        label: label,
        isIncluded: !isExcluded,
        isExcluded: isExcluded,
        isIgnored: isIgnored,
        isBypassed: isBypassed,
        color: color,
        onTap: onTap,
        tooltip: tooltip,
      ),
    );
  }

  String? _projectTooltip(bool ignoreProjects, bool isBypassed) => isBypassed
      ? 'Filters are temporarily bypassed (Shift+F)'
      : (ignoreProjects
            ? 'Project filters are ignored in this screen'
            : 'Click to remove filter');
}
