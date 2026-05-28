import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:flutter/material.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/kanban_column.dart';

class KanbanBoard extends ConsumerStatefulWidget {
  final List<Task> tasks;
  final void Function(Task task, TaskStatus status) onStatusChange;
  final void Function(Task task, Offset localPosition, RenderBox renderBox) onContextMenu;
  final void Function(Task task) onEdit;
  final Map<String, FocusNode>? itemFocusNodes;
  final ValueChanged<List<String>>? onOrderedIdsChanged;

  const KanbanBoard({
    super.key,
    required this.tasks,
    required this.onStatusChange,
    required this.onContextMenu,
    required this.onEdit,
    this.itemFocusNodes,
    this.onOrderedIdsChanged,
  });

  @override
  ConsumerState<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends ConsumerState<KanbanBoard> {
  bool _forceExpanded = false;
  bool _isDraggingOver = false;
  bool _isTransitioning = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = List<Task>.from(widget.tasks);
    tasks.sort((a, b) {
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

    final todo = tasks.where((t) => t.status.isTodo).toList();
    final inProgress = tasks.where((t) => t.status.isInProgress).toList();
    final done = tasks.where((t) => t.status.isDone).toList();

    if (widget.onOrderedIdsChanged != null) {
      final taskState = ref.watch(taskProvider);
      final allAvailableTasks = {for (var t in taskState.tasks) t.id: t}
        ..addAll({for (var t in taskState.overdueTasks) t.id: t})
        ..addAll({for (var t in taskState.unscheduledTasks) t.id: t});

      List<String> getFlatIds(List<Task> categoryTasks) {
        final flattened = TaskHierarchyUtils.buildHierarchy(categoryTasks, allTasks: allAvailableTasks);
        return flattened.whereType<TaskNode>().map((n) => n.task.id).toList();
      }

      final orderedIds = [...getFlatIds(todo), ...getFlatIds(inProgress)];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onOrderedIdsChanged!(orderedIds);
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;
        final isExpanded = !isNarrow || _forceExpanded || _isDraggingOver;

        final standardColumnWidth = (constraints.maxWidth - 32) / 3;
        final responsiveColumnWidth = isNarrow ? (constraints.maxWidth - 16) / 2 - 20 : standardColumnWidth;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: responsiveColumnWidth,
                  child: KanbanColumn(
                    title: 'Todo',
                    titleColor: Theme.of(context).colorScheme.onSurface,
                    tasks: todo,
                    acceptedStatus: TaskStatus.todo,
                    onStatusChange: widget.onStatusChange,
                    onContextMenu: widget.onContextMenu,
                    onEdit: widget.onEdit,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: responsiveColumnWidth,
                  child: KanbanColumn(
                    title: 'In Progress',
                    titleColor: AppColors.accent,
                    tasks: inProgress,
                    acceptedStatus: TaskStatus.inProgress,
                    onStatusChange: widget.onStatusChange,
                    onContextMenu: widget.onContextMenu,
                    onEdit: widget.onEdit,
                  ),
                ),
                const SizedBox(width: 16),
                ItemSizeTransitionBuilder(
                  isExpanded: isExpanded,
                  width: responsiveColumnWidth,
                  isNarrow: isNarrow,
                  doneTasks: done,
                  onStatusChange: widget.onStatusChange,
                  onContextMenu: widget.onContextMenu,
                  onEdit: widget.onEdit,
                  itemFocusNodes: widget.itemFocusNodes,
                  scrollController: _scrollController,
                  forceExpanded: _forceExpanded,
                  isDraggingOver: _isDraggingOver,
                  isTransitioning: _isTransitioning,
                  onToggle: () {
                    setState(() {
                      _forceExpanded = !_forceExpanded;
                      _isTransitioning = true;
                    });
                  },
                  onDragEntering: () {
                    setState(() {
                      _isDraggingOver = true;
                      _isTransitioning = true;
                    });
                  },
                  onDragExiting: () => setState(() => _isDraggingOver = false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ItemSizeTransitionBuilder extends ConsumerStatefulWidget {
  final bool isExpanded;
  final double width;
  final bool isNarrow;
  final List<Task> doneTasks;
  final void Function(Task task, TaskStatus status) onStatusChange;
  final void Function(Task task, Offset localPosition, RenderBox renderBox) onContextMenu;
  final void Function(Task task) onEdit;
  final Map<String, FocusNode>? itemFocusNodes;
  final ScrollController scrollController;
  final bool forceExpanded;
  final bool isDraggingOver;
  final bool isTransitioning;
  final VoidCallback onToggle;
  final VoidCallback onDragEntering;
  final VoidCallback onDragExiting;

  const ItemSizeTransitionBuilder({
    super.key,
    required this.isExpanded,
    required this.width,
    required this.isNarrow,
    required this.doneTasks,
    required this.onStatusChange,
    required this.onContextMenu,
    required this.onEdit,
    required this.itemFocusNodes,
    required this.scrollController,
    required this.forceExpanded,
    required this.isDraggingOver,
    required this.isTransitioning,
    required this.onToggle,
    required this.onDragEntering,
    required this.onDragExiting,
  });

  @override
  ConsumerState<ItemSizeTransitionBuilder> createState() => _ItemSizeTransitionBuilderState();
}

class _ItemSizeTransitionBuilderState extends ConsumerState<ItemSizeTransitionBuilder> {
  bool _localTransitioning = false;

  @override
  void initState() {
    super.initState();
    _localTransitioning = widget.isTransitioning;
  }

  @override
  void didUpdateWidget(ItemSizeTransitionBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTransitioning != oldWidget.isTransitioning) {
      _localTransitioning = widget.isTransitioning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(end: widget.isExpanded ? widget.width : 24),
      onEnd: () {
        if (mounted) setState(() => _localTransitioning = false);
      },
      builder: (context, width, child) {
        if (_localTransitioning && widget.scrollController.hasClients && widget.isExpanded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (widget.scrollController.hasClients && _localTransitioning) {
              widget.scrollController.jumpTo(widget.scrollController.position.maxScrollExtent);
            }
          });
        }

        return SizedBox(
          width: width,
          child: KanbanColumn(
            title: 'Done',
            titleColor: AppColors.success,
            tasks: widget.doneTasks,
            isNarrow: widget.isNarrow,
            acceptedStatus: TaskStatus.done,
            onStatusChange: widget.onStatusChange,
            onContextMenu: widget.onContextMenu,
            onEdit: widget.onEdit,
            itemFocusNodes: widget.itemFocusNodes,
            isCollapsed: !widget.isExpanded,
            onToggle: widget.onToggle,
            onDragEntering: widget.onDragEntering,
            onDragExiting: widget.onDragExiting,
          ),
        );
      },
    );
  }
}
