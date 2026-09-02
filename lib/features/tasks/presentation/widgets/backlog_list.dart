import 'package:carpe_diem/features/tasks/presentation/providers/subtask_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog_empty_placeholder.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/context_menu/task_card_context_menu.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/parent_group_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/blocker_indicator.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_hierarchy_indicator.dart';
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
import 'package:carpe_diem/core/utils/task_selection_utils.dart';

class BacklogList extends ConsumerWidget {
  final String searchQuery;
  final List<String> selectedTaskIds;
  final ValueChanged<Task> onSelectedChanged;
  final ValueChanged<Task> onEdit;
  final Map<String, FocusNode> itemFocusNodes;
  final ValueChanged<List<String>> onOrderedIdsChanged;
  final Widget Function(BuildContext, Task) trailingBuilder;

  const BacklogList({
    super.key,
    required this.searchQuery,
    required this.selectedTaskIds,
    required this.onSelectedChanged,
    required this.onEdit,
    required this.itemFocusNodes,
    required this.onOrderedIdsChanged,
    required this.trailingBuilder,
  });

  bool _isFiltering(TaskFilter filter) =>
      searchQuery.isNotEmpty || !filter.isEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(taskProvider);
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final projectState = ref.watch(projectProvider);
    final filter = ref.watch(filterProvider).activeFilter;
    var allTasks = provider.unscheduledTasks.where((t) {
      final project = t.projectId != null
          ? projectState.getById(t.projectId!)
          : null;
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
        isFiltering: _isFiltering(filter),
        onClearFilter: () => ref.read(filterProvider.notifier).clearFilter(),
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

    final List<String> orderedIds = [];
    for (final n in activeHierarchical) {
      if (n.task != null) {
        orderedIds.add(n.task!.id);
      }
    }
    for (final n in completedHierarchical) {
      if (n.task != null) {
        orderedIds.add(n.task!.id);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onOrderedIdsChanged(orderedIds);
    });

    Widget buildNode(TaskHierarchyNode n) {
      Widget child;
      if (n is ParentContainerNode) {
        final focusNode = itemFocusNodes.putIfAbsent(
          n.task.id,
          () => FocusNode(debugLabel: 'ParentTask_${n.task.id}'),
        );
        final subtasks = allTasks
            .where((t) => t.parentId == n.task.id)
            .toList();
        final isChecked = TaskSelectionUtils.getParentSelectionState(
          parentId: n.task.id,
          subtasks: subtasks,
          selectedTaskIds: selectedTaskIds.toSet(),
        );

        child = ParentGroupHeader(
          key: ValueKey('parent_${n.task.id}'),
          node: n,
          project: n.task.projectId != null
              ? projectState.getById(n.task.projectId!)
              : null,
          focusNode: focusNode,
          isChecked: isChecked,
          selectionMode: true,
          onToggle: (value) => onSelectedChanged(n.task),
          onTap: () {
            ref
                .read(collapsedSubtasksProvider.notifier)
                .toggleCollapse(n.task.id);
          },
          onContextMenu: (localPosition, renderBox) => showTaskCardContextMenu(
            context,
            ref,
            n.task,
            allTasks,
            localPosition,
            renderBox,
            onAction: () {
              if (selectedTaskIds.contains(n.task.id)) {
                onSelectedChanged(n.task);
              }
            },
          ),
          trailing: trailingBuilder(context, n.task),
        );
      } else if (n is TaskNode) {
        final isNested = n.isBundledUnderParent;
        final focusNode = itemFocusNodes.putIfAbsent(
          n.task.id,
          () => FocusNode(debugLabel: 'Task_${n.task.id}'),
        );

        child = TaskCard(
          key: ValueKey(n.task.id),
          task: n.task,
          project: n.task.projectId != null
              ? projectState.getById(n.task.projectId!)
              : null,
          hideProjectInfo: isNested,
          hideProjectGradient: false,
          isChecked: selectedTaskIds.contains(n.task.id),
          selectionMode: true,
          focusNode: focusNode,
          onToggle: (value) {
            onSelectedChanged(n.task);
          },
          onTap: () => onEdit(n.task),
          onContextMenu: (localPosition, renderBox) => showTaskCardContextMenu(
            context,
            ref,
            n.task,
            allTasks,
            localPosition,
            renderBox,
            onAction: () {
              if (selectedTaskIds.contains(n.task.id)) {
                onSelectedChanged(n.task);
              }
            },
          ),
          trailing: trailingBuilder(context, n.task),
        );
      } else if (n is BlockerIndicatorNode) {
        child = BlockerIndicator(
          blockerId: n.blockerId,
          blockerTitle: n.blockerTitle,
          blockedTaskId: n.blockedTaskId,
        );
      } else {
        return const SizedBox.shrink();
      }

      return TaskHierarchyIndicator(depth: n.depth, child: child);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: activeHierarchical.length,
          itemBuilder: (context, index) {
            final node = activeHierarchical[index];
            final child = buildNode(node);

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
                  } else {
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
                  }
                } else {
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
                }
              },
              child: draggableChild,
            );
          },
        );
      },
    );
  }
}
