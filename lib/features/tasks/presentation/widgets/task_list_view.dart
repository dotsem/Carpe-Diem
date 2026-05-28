import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/utils/fuzzy_search_utils.dart';
import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list_components.dart';

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
  }) : padding = padding ?? const EdgeInsets.symmetric(vertical: 16);

  @override
  ConsumerState<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends ConsumerState<TaskListView> {
  late bool _isDoneExpanded;
  final Map<String, FocusNode> _localItemFocusNodes = {};
  Map<String, FocusNode> get _itemFocusNodes => widget.itemFocusNodes ?? _localItemFocusNodes;
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

  void _moveFocus(int delta) {
    if (_orderedItemIds.isEmpty) return;

    int currentIndex = -1;
    for (int i = 0; i < _orderedItemIds.length; i++) {
      FocusNode? node;
      if (i == 0 && widget.firstNode != null) {
        node = widget.firstNode;
      } else {
        node = _itemFocusNodes[_orderedItemIds[i]];
      }
      if (node?.hasFocus ?? false) {
        currentIndex = i;
        break;
      }
    }

    if (currentIndex == -1) {
      final targetIndex = delta > 0 ? 0 : _orderedItemIds.length - 1;
      FocusNode? targetNode = (targetIndex == 0 && widget.firstNode != null)
          ? widget.firstNode
          : _itemFocusNodes[_orderedItemIds[targetIndex]];
      targetNode?.requestFocus();
    } else {
      final nextIndex = (currentIndex + delta).clamp(0, _orderedItemIds.length - 1);
      FocusNode? targetNode = (nextIndex == 0 && widget.firstNode != null)
          ? widget.firstNode
          : _itemFocusNodes[_orderedItemIds[nextIndex]];
      targetNode?.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);
    final taskNotifier = ref.read(taskProvider.notifier);

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
      allTasks.sort((a, b) {
        final settings = ref.read(settingsProvider);

        if (settings.prioritizeOverdue) {
          if (a.isOverdue && !b.isOverdue) return -1;
          if (!a.isOverdue && b.isOverdue) return 1;
        }

        final deadlineComp = () {
          if (a.deadline == b.deadline) return 0;
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        }();

        final priorityComp = b.priority.index.compareTo(a.priority.index);

        if (settings.prioritizeDeadlines) {
          if (deadlineComp != 0) return deadlineComp;
          if (priorityComp != 0) return priorityComp;
        } else {
          if (priorityComp != 0) return priorityComp;
          if (deadlineComp != 0) return deadlineComp;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
    }

    final inProgressCategory = allTasks.where((t) => t.status.isInProgress).toList();
    final overdueCategory = allTasks.where((t) => t.status.isTodo && isOverdue(t)).toList();
    final todoCategory = allTasks.where((t) => t.status.isTodo && !isOverdue(t)).toList();
    final doneCategory = allTasks.where((t) => t.status.isDone).toList();

    if (inProgressCategory.isEmpty && overdueCategory.isEmpty && todoCategory.isEmpty && doneCategory.isEmpty) {
      return TaskListEmptyPlaceholder(customPlaceholder: widget.emptyPlaceholder);
    }

    _orderedItemIds.clear();

    void addTasksToOrder(List<Task> categoryTasks) {
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        for (final t in categoryTasks) {
          _orderedItemIds.add(t.id);
        }
      } else {
        final allAvailableTasks = {for (var t in taskState.tasks) t.id: t}
          ..addAll({for (var t in taskState.overdueTasks) t.id: t})
          ..addAll({for (var t in taskState.unscheduledTasks) t.id: t});
        final flattened = TaskHierarchyUtils.buildHierarchy(categoryTasks, allTasks: allAvailableTasks);
        for (final n in flattened) {
          if (n is TaskNode) {
            _orderedItemIds.add(n.task.id);
          }
        }
      }
    }

    addTasksToOrder(inProgressCategory);
    addTasksToOrder(overdueCategory);
    addTasksToOrder(todoCategory);
    if (_isDoneExpanded) {
      addTasksToOrder(doneCategory);
    }

    if (widget.onOrderedIdsChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onOrderedIdsChanged!(List.from(_orderedItemIds));
      });
    }

    int nodeIndex = 0;
    Widget buildNode(TaskHierarchyNode node, bool Function(Task) overdueFn) {
      final isTaskNode = node is TaskNode;
      FocusNode? focusNode;
      bool autofocus = false;

      if (isTaskNode) {
        final isFirst = nodeIndex == 0;
        autofocus = nodeIndex == 0 && widget.searchQuery == null && widget.firstNode == null;
        focusNode = (isFirst && widget.firstNode != null)
            ? widget.firstNode!
            : _itemFocusNodes.putIfAbsent(node.task.id, () => FocusNode(debugLabel: 'Task_${node.task.id}'));

        if (isFirst && widget.firstNode != null) {
          _itemFocusNodes[node.task.id] = widget.firstNode!;
        }
        nodeIndex++;
      }

      return TaskHierarchyItem(
        node: node,
        taskIsOverdue: isTaskNode ? overdueFn(node.task) : false,
        showScheduleDate: isTaskNode ? widget.showScheduleDate : false,
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

    List<Widget> buildHierarchy(List<Task> categoryTasks, bool Function(Task) overdueFn) {
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        return categoryTasks.map((t) => buildNode(TaskNode(t, 0), overdueFn)).toList();
      }
      final allAvailableTasks = {for (var t in taskState.tasks) t.id: t}
        ..addAll({for (var t in taskState.overdueTasks) t.id: t})
        ..addAll({for (var t in taskState.unscheduledTasks) t.id: t});

      final flattened = TaskHierarchyUtils.buildHierarchy(categoryTasks, allTasks: allAvailableTasks);
      return flattened.map((n) => buildNode(n, overdueFn)).toList();
    }

    return Shortcuts(
      shortcuts: Map.fromEntries([
        if (widget.enablePlanShortcut) ...[
          const MapEntry(SingleActivator(LogicalKeyboardKey.keyT, control: true), PlanTaskIntent()),
          const MapEntry(
            SingleActivator(LogicalKeyboardKey.keyT, control: true, shift: true),
            PlanTaskTomorrowIntent(),
          ),
        ],
      ]),
      child: Actions(
        actions: {
          MoveNextIntent: NonTypingAction<MoveNextIntent>((_) {
            _moveFocus(1);
          }),
          MovePrevIntent: NonTypingAction<MovePrevIntent>((_) {
            _moveFocus(-1);
          }),
          PlanTaskIntent: NonTypingAction<PlanTaskIntent>((_) {
            if (widget.selectedTaskIds.isNotEmpty) {
              taskNotifier.scheduleTasksForToday(widget.selectedTaskIds.toList()).then((_) {
                widget.onClearSelection?.call();
              });
            } else {
              final taskId = _getFocusedTaskId();
              if (taskId != null) {
                taskNotifier.scheduleTasksForToday([taskId]);
              }
            }
          }),
          PlanTaskTomorrowIntent: NonTypingAction<PlanTaskTomorrowIntent>((_) {
            if (widget.selectedTaskIds.isNotEmpty) {
              taskNotifier.scheduleTasksForTomorrow(widget.selectedTaskIds.toList()).then((_) {
                widget.onClearSelection?.call();
              });
            } else {
              final taskId = _getFocusedTaskId();
              if (taskId != null) {
                taskNotifier.scheduleTasksForTomorrow([taskId]);
              }
            }
          }),
        },
        child: ListView(
          padding: widget.padding,
          children: [
            if (inProgressCategory.isNotEmpty) ...[
              TaskListSectionHeader(
                title: 'In Progress',
                color: AppColors.accent,
                amount: inProgressCategory.length,
              ),
              const SizedBox(height: 8),
              ...buildHierarchy(inProgressCategory, isOverdue),
              const SizedBox(height: 20),
            ],
            if (overdueCategory.isNotEmpty) ...[
              TaskListSectionHeader(
                title: 'Overdue',
                color: AppColors.error,
                amount: overdueCategory.length,
              ),
              const SizedBox(height: 8),
              ...buildHierarchy(overdueCategory, (_) => true),
              const SizedBox(height: 20),
            ],
            if (todoCategory.isNotEmpty) ...[
              TaskListSectionHeader(
                title: 'Todo',
                amount: todoCategory.length,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              ...buildHierarchy(todoCategory, (_) => false),
            ],
            if (doneCategory.isNotEmpty) ...[
              const SizedBox(height: 20),
              TaskListSectionHeader(
                title: 'Done',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                amount: doneCategory.length,
                onTap: () => setState(() => _isDoneExpanded = !_isDoneExpanded),
                trailing: AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: _isDoneExpanded ? 0.5 : 0,
                  child: Icon(Icons.expand_more, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _isDoneExpanded
                    ? Column(children: buildHierarchy(doneCategory, (_) => false))
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _getFocusedTaskId() {
    if (_orderedItemIds.isEmpty) return null;
    for (int i = 0; i < _orderedItemIds.length; i++) {
      FocusNode? node;
      if (i == 0 && widget.firstNode != null) {
        node = widget.firstNode;
      } else {
        node = _itemFocusNodes[_orderedItemIds[i]];
      }
      if (node?.hasFocus ?? false) {
        return _orderedItemIds[i];
      }
    }
    return null;
  }
}
