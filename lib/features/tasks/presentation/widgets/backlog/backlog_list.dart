import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/backlog_label_tab_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/subtask_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog/backlog_draggable_item.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog/backlog_empty_placeholder.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/task_empty_space_drop_zone.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/task_reorder_corridor.dart';
import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_utils.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_item.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_scope.dart';
import 'package:carpe_diem/core/utils/fuzzy_search_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BacklogList extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<BacklogList> createState() => _BacklogListState();
}

class _BacklogListState extends ConsumerState<BacklogList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isFiltering(TaskFilter filter, BacklogLabelTabState labelTab) =>
      widget.searchQuery.isNotEmpty ||
      !filter.isEmpty ||
      labelTab.scope != BacklogLabelTabScope.all;

  void _handleDrop(Task task, int newIndex, List<TaskHierarchyNode> nodes) {
    TaskReorderUtils.dispatchReorder(
      notifier: ref.read(taskProvider.notifier),
      nodes: nodes,
      draggedTask: task,
      newIndex: newIndex,
      selectedTaskIds: widget.selectedTaskIds.toSet(),
      settings: ref.read(settingsProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    if (widget.searchQuery.isNotEmpty) {
      allTasks = FuzzySearchUtils.search<Task>(
        query: widget.searchQuery,
        items: allTasks,
        itemToString: (t) => '${t.title} ${t.description ?? ''}',
        threshold: 0.3,
      );
    }

    final activeTasks = allTasks.where((t) => !t.isCompleted).toList();
    final completedTasks = allTasks.where((t) => t.isCompleted).toList();

    if (activeTasks.isEmpty && completedTasks.isEmpty) {
      widget.onOrderedIdsChanged([]);
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
      widget.onOrderedIdsChanged(orderedIds);
    });

    return TaskReorderScope(
      nodes: activeHierarchical,
      onDrop: (task, index) => _handleDrop(task, index, activeHierarchical),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return TaskReorderCorridor(
            scrollController: _scrollController,
            nodes: activeHierarchical,
            padding: const EdgeInsets.symmetric(vertical: 16),
            onDrop: (task, index) =>
                _handleDrop(task, index, activeHierarchical),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  sliver: Builder(
                    builder: (context) {
                      final scope = TaskReorderScope.of(context);
                      return ValueListenableBuilder<TaskReorderActiveDrop?>(
                        valueListenable: scope!.activeDropNotifier,
                        builder: (context, activeDrop, _) {
                          final slotInfo = TaskReorderListSlot.from(
                            itemCount: activeHierarchical.length,
                            activeDrop: activeDrop,
                          );
                          return SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              if (slotInfo.isPlaceholder(index)) {
                                return TaskReorderPlaceholderItem(
                                  slotIndex: slotInfo.placeholderIndex!,
                                  task: slotInfo.task!,
                                );
                              }
                              final actualIndex = slotInfo.toOriginalIndex(
                                index,
                              );
                              return BacklogDraggableItem(
                                node: activeHierarchical[actualIndex],
                                index: actualIndex,
                                allTasks: allTasks,
                                selectedTaskIds: widget.selectedTaskIds,
                                highlightedTaskId: widget.highlightedTaskId,
                                itemFocusNodes: widget.itemFocusNodes,
                                onSelectedChanged: widget.onSelectedChanged,
                                onEdit: widget.onEdit,
                                trailingBuilder: widget.trailingBuilder,
                                maxWidth: constraints.maxWidth,
                                onDrop: (task, newIndex) => _handleDrop(
                                  task,
                                  newIndex,
                                  activeHierarchical,
                                ),
                              );
                            }, childCount: slotInfo.totalCount),
                          );
                        },
                      );
                    },
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: const TaskEmptySpaceDropZone(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
