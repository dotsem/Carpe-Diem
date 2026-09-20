import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/backlog_label_tab_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/subtask_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog/backlog_empty_placeholder.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog/backlog_hierarchy_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_drag_proxy.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_drop_zone.dart';
import 'package:carpe_diem/features/common/presentation/widgets/platform_draggable.dart';
import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/core/utils/task_reorder_utils.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/core/utils/fuzzy_search_utils.dart';

class BacklogList extends ConsumerWidget {
  final String searchQuery;
  final List<String> selectedTaskIds;
  final ValueChanged<Task> onSelectedChanged;
  final ValueChanged<Task> onEdit;
  final Map<String, FocusNode> itemFocusNodes;
  final ValueChanged<List<String>> onOrderedIdsChanged;
  final Widget Function(BuildContext, Task)? trailingBuilder;
  final String? highlightedTaskId;

  const BacklogList({
    super.key,
    required this.searchQuery,
    required this.selectedTaskIds,
    required this.onSelectedChanged,
    required this.onEdit,
    required this.itemFocusNodes,
    required this.onOrderedIdsChanged,
    this.trailingBuilder,
    this.highlightedTaskId,
  });

  bool _isFiltering(TaskFilter filter, BacklogLabelTabState labelTab) =>
      searchQuery.isNotEmpty ||
      !filter.isEmpty ||
      labelTab.scope != BacklogLabelTabScope.all;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(taskProvider);
    final projectState = ref.watch(projectProvider);
    final filter = ref.watch(filterProvider).activeFilter;
    final labelTab = ref.watch(backlogLabelTabProvider);

    var allTasks = provider.unscheduledTasks.where((t) {
      final project = t.projectId != null
          ? projectState.getById(t.projectId!)
          : null;
      final combinedLabels = {...t.labelIds, ...?project?.labelIds};

      final matchesLabelScope = switch (labelTab.scope) {
        BacklogLabelTabScope.all => true,
        BacklogLabelTabScope.inbox => combinedLabels.isEmpty,
        BacklogLabelTabScope.label => combinedLabels.contains(labelTab.labelId),
      };
      if (!matchesLabelScope) return false;

      return filter.applyToTask(t, project?.labelIds ?? []);
    }).toList();

    if (searchQuery.isNotEmpty) {
      allTasks = FuzzySearchUtils.search<Task>(
        query: searchQuery,
        items: allTasks,
        itemToString: (t) => '${t.title} ${t.description ?? ''}',
        threshold: 0.3,
      );
    }

    final activeTasks = allTasks.where((t) => !t.isCompleted).toList();
    final completedTasks = allTasks.where((t) => t.isCompleted).toList();

    if (activeTasks.isEmpty && completedTasks.isEmpty) {
      onOrderedIdsChanged([]);
      return BacklogEmptyPlaceholder(
        isFiltering: _isFiltering(filter, labelTab),
        onClearFilter: () {
          ref.read(filterProvider.notifier).clearFilter();
          ref.read(backlogLabelTabProvider.notifier).selectAll();
        },
      );
    }

    final allAvailableTasks = {for (var t in provider.tasks) t.id: t}
      ..addAll({for (var t in provider.overdueTasks) t.id: t})
      ..addAll({for (var t in provider.unscheduledTasks) t.id: t});

    final collapsedParentIds = ref.watch(collapsedSubtasksProvider);
    final activeHierarchical = TaskHierarchyUtils.buildHierarchy(
      activeTasks,
      allTasks: allAvailableTasks,
      collapsedParentIds: collapsedParentIds,
      asParentContainers: true,
    );
    final completedHierarchical = TaskHierarchyUtils.buildHierarchy(
      completedTasks,
      allTasks: allAvailableTasks,
      collapsedParentIds: collapsedParentIds,
      asParentContainers: true,
    );

    final orderedIds = [
      ...activeHierarchical,
      ...completedHierarchical,
    ].map((n) => n.task?.id).whereType<String>().toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onOrderedIdsChanged(orderedIds);
    });

    final urgentSectionEnd = TaskReorderUtils.getUrgentSectionEndIndex(
      activeHierarchical,
    );

    return TaskDropZoneScope(
      urgentSectionEndIndex: urgentSectionEnd,
      itemCount: activeHierarchical.length,
      isPositionUnchanged: (task, targetIndex) =>
          TaskReorderUtils.isPositionUnchangedInNodes(
            draggedTask: task,
            targetIndex: targetIndex,
            nodes: activeHierarchical,
          ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: activeHierarchical.length,
            itemBuilder: (context, index) {
              final node = activeHierarchical[index];
              final child = BacklogHierarchyItem(
                node: node,
                allTasks: allTasks,
                selectedTaskIds: selectedTaskIds,
                highlightedTaskId: highlightedTaskId,
                itemFocusNodes: itemFocusNodes,
                onSelectedChanged: onSelectedChanged,
                onEdit: onEdit,
                trailingBuilder: trailingBuilder,
              );

              Widget draggableChild = child;
              if (node.task != null) {
                final task = node.task!;
                final isSelected = selectedTaskIds.contains(task.id);
                draggableChild = PlatformDraggable<Task>(
                  data: task,
                  feedback: TaskDragProxy(
                    task: task,
                    selectedCount: isSelected ? selectedTaskIds.length : 1,
                    width: constraints.maxWidth - 32,
                  ),
                  childWhenDragging: Opacity(opacity: 0.3, child: child),
                  child: child,
                );
              }

              return TaskDropZoneWrapper(
                index: index,
                onDrop: (task, newIndex) {
                  final settings = ref.read(settingsProvider);
                  if (selectedTaskIds.isNotEmpty) {
                    final newSortOrders = TaskReorderUtils.handleMultiReorder(
                      nodes: activeHierarchical,
                      draggedTask: task,
                      newIndex: newIndex,
                      selectedTaskIds: selectedTaskIds.toSet(),
                      settings: settings,
                    );
                    if (newSortOrders != null && newSortOrders.isNotEmpty) {
                      ref
                          .read(taskProvider.notifier)
                          .bulkReorderTasks(newSortOrders);
                      return;
                    }
                  }
                  final newSortOrder = TaskReorderUtils.handleReorder(
                    nodes: activeHierarchical,
                    draggedTask: task,
                    newIndex: newIndex,
                    settings: settings,
                  );
                  if (newSortOrder != null) {
                    ref
                        .read(taskProvider.notifier)
                        .reorderTask(task, newSortOrder);
                  }
                },
                child: draggableChild,
              );
            },
          );
        },
      ),
    );
  }
}
