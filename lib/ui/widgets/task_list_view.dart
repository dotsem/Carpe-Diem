import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/utils/fuzzy_search_utils.dart';
import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/providers/project_provider.dart';
import 'package:carpe_diem/providers/task_provider.dart';
import 'package:carpe_diem/ui/widgets/blocker_indicator.dart';
import 'package:carpe_diem/ui/widgets/chip/small_chip.dart';
import 'package:carpe_diem/ui/widgets/task_card.dart';
import 'package:flutter/material.dart';
import 'package:carpe_diem/data/models/task.dart';
import 'package:carpe_diem/ui/widgets/task_hierarchy_indicator.dart';
import 'package:provider/provider.dart';
import 'package:carpe_diem/ui/shortcuts/app_shortcuts.dart';

class TaskListView extends StatefulWidget {
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
  }) : padding = padding ?? const EdgeInsets.symmetric(vertical: 16);

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final projectProvider = context.read<ProjectProvider>();
    final taskProvider = context.read<TaskProvider>();

    bool isOverdue(Task t) {
      if (t.deadline != null) {
        return t.deadline!.isBefore(today) && !t.isCompleted;
      }
      return t.scheduledDate != null && t.scheduledDate!.isBefore(today) && !t.isCompleted;
    }

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
        if (a.priority != b.priority) return b.priority.index.compareTo(a.priority.index);
        if (a.deadline != b.deadline) {
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        }
        return b.createdAt.compareTo(a.createdAt);
      });
    }

    final inProgressCategory = allTasks.where((t) => t.status.isInProgress).toList();
    final overdueCategory = allTasks.where((t) => t.status.isTodo && isOverdue(t)).toList();
    final todoCategory = allTasks.where((t) => t.status.isTodo && !isOverdue(t)).toList();
    final doneCategory = allTasks.where((t) => t.status.isDone).toList();

    if (inProgressCategory.isEmpty && overdueCategory.isEmpty && todoCategory.isEmpty && doneCategory.isEmpty) {
      return widget._buildEmptyState(context);
    }

    _orderedItemIds.clear();

    void addTasksToOrder(List<Task> categoryTasks) {
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        for (final t in categoryTasks) {
          _orderedItemIds.add(t.id);
        }
      } else {
        final allAvailableTasks = {for (var t in taskProvider.tasks) t.id: t}
          ..addAll({for (var t in taskProvider.overdueTasks) t.id: t})
          ..addAll({for (var t in taskProvider.unscheduledTasks) t.id: t});
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
      if (node is TaskNode) {
        final autofocus = nodeIndex == 0 && widget.searchQuery == null && widget.firstNode == null;
        final isFirst = nodeIndex == 0;
        final focusNode = (isFirst && widget.firstNode != null)
            ? widget.firstNode!
            : _itemFocusNodes.putIfAbsent(node.task.id, () => FocusNode(debugLabel: 'Task_${node.task.id}'));

        if (isFirst && widget.firstNode != null) {
          _itemFocusNodes[node.task.id] = widget.firstNode!;
        }

        nodeIndex++;
        return widget._buildHierarchyNode(
          context,
          node,
          projectProvider,
          taskProvider,
          overdueFn(node.task),
          widget.showScheduleDate,
          autofocus,
          focusNode,
        );
      } else if (node is BlockerIndicatorNode) {
        return widget._buildHierarchyNode(context, node, projectProvider, taskProvider, false, false, false, null);
      }
      return const SizedBox.shrink();
    }

    List<Widget> buildHierarchy(List<Task> categoryTasks, bool Function(Task) overdueFn) {
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        return categoryTasks.map((t) => buildNode(TaskNode(t, 0), overdueFn)).toList();
      }
      final allAvailableTasks = {for (var t in taskProvider.tasks) t.id: t}
        ..addAll({for (var t in taskProvider.overdueTasks) t.id: t})
        ..addAll({for (var t in taskProvider.unscheduledTasks) t.id: t});

      final flattened = TaskHierarchyUtils.buildHierarchy(categoryTasks, allTasks: allAvailableTasks);
      return flattened.map((n) => buildNode(n, overdueFn)).toList();
    }

    return Actions(
      actions: {
        MoveNextIntent: NonTypingAction<MoveNextIntent>((_) {
          _moveFocus(1);
        }),
        MovePrevIntent: NonTypingAction<MovePrevIntent>((_) {
          _moveFocus(-1);
        }),
      },
      child: ListView(
        padding: widget.padding,
        children: [
          if (inProgressCategory.isNotEmpty) ...[
            widget._buildHeader(context, 'In Progress', color: AppColors.accent, amount: inProgressCategory.length),
            const SizedBox(height: 8),
            ...buildHierarchy(inProgressCategory, isOverdue),
            const SizedBox(height: 20),
          ],
          if (overdueCategory.isNotEmpty) ...[
            widget._buildHeader(context, 'Overdue', color: AppColors.error, amount: overdueCategory.length),
            const SizedBox(height: 8),
            ...buildHierarchy(overdueCategory, (_) => true),
            const SizedBox(height: 20),
          ],
          if (todoCategory.isNotEmpty) ...[
            widget._buildHeader(context, 'Todo', amount: todoCategory.length, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            ...buildHierarchy(todoCategory, (_) => false),
          ],
          if (doneCategory.isNotEmpty) ...[
            const SizedBox(height: 20),
            widget._buildHeader(
              context,
              'Done',
              color: AppColors.textSecondary,
              amount: doneCategory.length,
              onTap: () => setState(() => _isDoneExpanded = !_isDoneExpanded),
              trailing: AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: _isDoneExpanded ? 0.5 : 0,
                child: const Icon(Icons.expand_more, color: AppColors.textSecondary, size: 20),
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
    );
  }
}

extension TaskListViewPrivate on TaskListView {
  Widget _buildHeader(
    BuildContext context,
    String title, {
    Color? color,
    int? amount,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    Widget content = Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        SmallChip(
          color: color?.withValues(alpha: 0.15) ?? Colors.transparent,
          borderRadius: 10,
          child: Text(
            '${amount ?? tasks.length}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing],
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: content),
      );
    }
    return content;
  }

  Widget _buildHierarchyNode(
    BuildContext context,
    TaskHierarchyNode node,
    ProjectProvider projectProvider,
    TaskProvider taskProvider,
    bool taskIsOverdue,
    bool showScheduleDate,
    bool autofocus,
    FocusNode? focusNode,
  ) {
    Widget child;
    if (node is TaskNode) {
      child = TaskCard(
        key: ValueKey(node.task.id),
        task: node.task,
        project: node.task.projectId != null ? projectProvider.getById(node.task.projectId!) : null,
        isOverdue: taskIsOverdue,
        autofocus: autofocus,
        focusNode: focusNode,
        onToggle: isReadOnly
            ? (_) {}
            : selectionMode
            ? (value) => onSelectedChanged?.call(node.task)
            : (_) => taskProvider.toggleComplete(node.task),
        isChecked: selectionMode ? selectedTaskIds.contains(node.task.id) : null,
        selectionMode: selectionMode,
        onTap: isReadOnly ? () {} : () => onEdit?.call(node.task),
        showScheduleDate: showScheduleDate,
        onContextMenu: isReadOnly
            ? null
            : onContextMenu != null
            ? (pos, box) => onContextMenu!(context, node.task, pos, box)
            : null,
        leading: isReadOnly ? const SizedBox.shrink() : null,
        trailing: isReadOnly ? const SizedBox.shrink() : trailingBuilder?.call(context, node.task),
      );
    } else if (node is BlockerIndicatorNode) {
      child = BlockerIndicator(
        blockerId: node.blockerId,
        blockerTitle: node.blockerTitle,
        blockedTaskId: node.blockedTaskId,
      );
    } else {
      return const SizedBox.shrink();
    }

    return TaskHierarchyIndicator(depth: node.depth, child: child);
  }

  Widget _buildEmptyState(BuildContext context) {
    if (emptyPlaceholder != null) return emptyPlaceholder!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text('No tasks found', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }
}
