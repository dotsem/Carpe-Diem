import 'package:carpe_diem/core/utils/fuzzy_search_utils.dart';
import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/core/utils/task_sort_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/subtask_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/task_list_components.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/task_list_done_section.dart';
import 'package:carpe_diem/core/utils/focus_utils.dart';

class TaskListView extends ConsumerStatefulWidget {
  final List<Task> tasks;
  final List<Task> overdueTasks;
  final Widget Function(BuildContext, Task)? trailingBuilder;
  final void Function(BuildContext, Task, Offset, RenderBox)? onContextMenu;
  final EdgeInsets padding;
  final bool showDateGroupHeaders;
  final Widget? emptyPlaceholder;
  final bool showScheduleDate;
  final String? searchQuery;
  final Set<String> selectedTaskIds;
  final bool selectionMode;
  final ValueChanged<Task>? onSelectedChanged;
  final ValueChanged<Task>? onEdit;
  final bool initialDoneExpanded;
  final bool isReadOnly;
  final FocusNode? firstNode;
  final Map<String, FocusNode>? itemFocusNodes;
  final ValueChanged<List<String>>? onOrderedIdsChanged;
  final bool enablePlanShortcut;
  final VoidCallback? onClearSelection;
  final bool asParentContainers;

  const TaskListView({
    super.key,
    required this.tasks,
    this.overdueTasks = const [],
    this.trailingBuilder,
    this.onContextMenu,
    EdgeInsets? padding,
    this.showDateGroupHeaders = true,
    this.emptyPlaceholder,
    this.showScheduleDate = false,
    this.searchQuery,
    this.selectionMode = false,
    this.selectedTaskIds = const {},
    this.onSelectedChanged,
    this.onEdit,
    this.initialDoneExpanded = false,
    this.isReadOnly = false,
    this.firstNode,
    this.itemFocusNodes,
    this.onOrderedIdsChanged,
    this.enablePlanShortcut = false,
    this.onClearSelection,
    this.asParentContainers = false,
  }) : padding = padding ?? const EdgeInsets.symmetric(vertical: 16);

  @override
  ConsumerState<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends ConsumerState<TaskListView> {
  late bool _isDoneExpanded;
  final Map<String, FocusNode> _localItemFocusNodes = {};
  Map<String, FocusNode> get _itemFocusNodes =>
      widget.itemFocusNodes ?? _localItemFocusNodes;
  final List<String> _orderedItemIds = [];

  @override
  void initState() {
    super.initState();
    _isDoneExpanded = widget.initialDoneExpanded;
  }

  @override
  void dispose() {
    for (final node in _localItemFocusNodes.values) {
      if (node != widget.firstNode) {
        node.dispose();
      }
    }
    super.dispose();
  }

  void _moveFocus(int delta) => FocusUtils.moveFocus(
    orderedItemIds: _orderedItemIds,
    itemFocusNodes: _itemFocusNodes,
    delta: delta,
    firstItemFocusNode: widget.firstNode,
    debugLabelPrefix: 'TaskListTask',
  );

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);

    bool isOverdue(Task t) => t.isOverdue;

    final allTasksMap = <String, Task>{};
    for (final t in widget.tasks) {
      allTasksMap[t.id] = t;
    }
    for (final t in widget.overdueTasks) {
      allTasksMap[t.id] = t;
    }

    var allTasks = allTasksMap.values.toList();
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      allTasks = FuzzySearchUtils.search<Task>(
        query: widget.searchQuery!,
        items: allTasks,
        itemToString: (t) => '${t.title} ${t.description ?? ''}',
      );
    } else {
      TaskSortUtils.sortTasks(allTasks, ref.read(settingsProvider));
    }

    final activeTasks = allTasks.where((t) => !t.status.isDone).toList();
    final doneCategory = allTasks.where((t) => t.status.isDone).toList();

    if (activeTasks.isEmpty && doneCategory.isEmpty) {
      return TaskListEmptyPlaceholder(
        customPlaceholder: widget.emptyPlaceholder,
      );
    }

    _orderedItemIds.clear();

    List<TaskHierarchyNode> getHierarchyNodes(List<Task> categoryTasks) {
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        return categoryTasks.map((t) => TaskNode(t, 0)).toList();
      }
      final allAvailableTasks = {for (var t in taskState.tasks) t.id: t}
        ..addAll({for (var t in taskState.overdueTasks) t.id: t})
        ..addAll({for (var t in taskState.unscheduledTasks) t.id: t});
      final collapsedParentIds = ref.watch(collapsedSubtasksProvider);
      return TaskHierarchyUtils.buildHierarchy(
        categoryTasks,
        allTasks: allAvailableTasks,
        collapsedParentIds: collapsedParentIds,
        asParentContainers: widget.asParentContainers,
      );
    }

    void addTasksToOrder(List<Task> categoryTasks) {
      for (final n in getHierarchyNodes(categoryTasks)) {
        if (n.task != null) _orderedItemIds.add(n.task!.id);
      }
    }

    addTasksToOrder(activeTasks);
    if (_isDoneExpanded) addTasksToOrder(doneCategory);

    if (widget.onOrderedIdsChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onOrderedIdsChanged!(List.from(_orderedItemIds));
      });
    }

    int nodeIndex = 0;
    Widget buildNode(TaskHierarchyNode node, bool Function(Task) overdueFn) {
      final task = node.task;
      FocusNode? focusNode;
      bool autofocus = false;

      if (task != null) {
        final isFirst = nodeIndex == 0;
        autofocus =
            nodeIndex == 0 &&
            widget.searchQuery == null &&
            widget.firstNode == null;
        focusNode = (isFirst && widget.firstNode != null)
            ? widget.firstNode!
            : _itemFocusNodes.putIfAbsent(
                task.id,
                () => FocusNode(debugLabel: 'Task_${task.id}'),
              );

        if (isFirst && widget.firstNode != null) {
          _itemFocusNodes[task.id] = widget.firstNode!;
        }
        nodeIndex++;
      }

      return TaskHierarchyItem(
        node: node,
        taskIsOverdue: task != null ? overdueFn(task) : false,
        showScheduleDate: task != null ? widget.showScheduleDate : false,
        autofocus: autofocus,
        focusNode: focusNode,
        isReadOnly: widget.isReadOnly,
        selectionMode: widget.selectionMode,
        selectedTaskIds: widget.selectedTaskIds,
        onSelectedChanged: widget.onSelectedChanged,
        onEdit: widget.onEdit,
        onContextMenu: widget.onContextMenu,
        trailingBuilder: widget.trailingBuilder,
      );
    }

    final activeNodes = getHierarchyNodes(activeTasks);

    return TaskListKeyboardShortcuts(
      enablePlanShortcut: widget.enablePlanShortcut,
      onMoveNext: () => _moveFocus(1),
      onMovePrev: () => _moveFocus(-1),
      onPlanToday: () {
        final taskNotifier = ref.read(taskProvider.notifier);
        if (widget.selectedTaskIds.isNotEmpty) {
          taskNotifier
              .scheduleTasksForToday(widget.selectedTaskIds.toList())
              .then((_) {
                widget.onClearSelection?.call();
              });
        } else {
          final taskId = _getFocusedTaskId();
          if (taskId != null) taskNotifier.scheduleTasksForToday([taskId]);
        }
      },
      onPlanTomorrow: () {
        final taskNotifier = ref.read(taskProvider.notifier);
        if (widget.selectedTaskIds.isNotEmpty) {
          taskNotifier
              .scheduleTasksForTomorrow(widget.selectedTaskIds.toList())
              .then((_) {
                widget.onClearSelection?.call();
              });
        } else {
          final taskId = _getFocusedTaskId();
          if (taskId != null) {
            taskNotifier.scheduleTasksForTomorrow([taskId]);
          }
        }
      },
      child: ListView(
        padding: widget.padding,
        children: [
          if (activeTasks.isNotEmpty)
            ActiveTaskReorderableList(
              nodes: activeNodes,
              widgets: activeNodes.map((n) => buildNode(n, isOverdue)).toList(),
              selectedTaskIds: widget.selectedTaskIds,
              isReorderEnabled:
                  widget.searchQuery == null || widget.searchQuery!.isEmpty,
              onReorder: (task, newSortOrder) => ref
                  .read(taskProvider.notifier)
                  .reorderTask(task, newSortOrder),
              onMultiReorder: (newSortOrders) => ref
                  .read(taskProvider.notifier)
                  .bulkReorderTasks(newSortOrders),
            ),
          if (doneCategory.isNotEmpty) ...[
            TaskListDoneSection(
              count: doneCategory.length,
              isExpanded: _isDoneExpanded,
              onToggle: () =>
                  setState(() => _isDoneExpanded = !_isDoneExpanded),
              children: getHierarchyNodes(
                doneCategory,
              ).map((n) => buildNode(n, (_) => false)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String? _getFocusedTaskId() => FocusUtils.getFocusedId(
    orderedItemIds: _orderedItemIds,
    itemFocusNodes: _itemFocusNodes,
    firstItemFocusNode: widget.firstNode,
  );
}
