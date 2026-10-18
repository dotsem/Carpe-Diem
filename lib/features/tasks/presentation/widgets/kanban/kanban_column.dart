import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_utils.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/kanban/kanban_column_header.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_reorder_service.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/subtask_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_drag_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/kanban/kanban_card.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/kanban/kanban_collapsed_column.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/task_empty_space_drop_zone.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_item.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KanbanColumn extends ConsumerStatefulWidget {
  final String title;
  final Color titleColor;
  final List<Task> tasks;
  final TaskStatus acceptedStatus;
  final void Function(Task task, TaskStatus status) onStatusChange;
  final void Function(Task task, Offset localPosition, RenderBox renderBox)
  onContextMenu;
  final void Function(Task task) onEdit;
  final bool isCollapsed;
  final bool isNarrow;
  final bool isPlanView;
  final VoidCallback? onToggle;
  final VoidCallback? onDragEntering;
  final VoidCallback? onDragExiting;
  final Map<String, FocusNode>? itemFocusNodes;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.titleColor,
    required this.tasks,
    required this.acceptedStatus,
    required this.onStatusChange,
    required this.onContextMenu,
    required this.onEdit,
    this.isNarrow = false,
    this.isPlanView = true,
    this.isCollapsed = false,
    this.onToggle,
    this.onDragEntering,
    this.onDragExiting,
    this.itemFocusNodes,
  });

  @override
  ConsumerState<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends ConsumerState<KanbanColumn> {
  bool _inSameGroup(Task a, Task b) => TaskReorderUtils.inSameGroup(
    a,
    b,
    ref.read(settingsProvider),
    isPlanView: widget.isPlanView,
  );

  void _updateOrder(Task task, String? order) {
    if (task.status != widget.acceptedStatus) {
      final updated = task.copyWith(
        sortOrder: order ?? task.sortOrder,
        planSortOrder: widget.isPlanView ? (order ?? task.planSortOrder) : null,
      );
      widget.onStatusChange(updated, widget.acceptedStatus);
    } else if (order != null) {
      ref
          .read(taskProvider.notifier)
          .reorderTask(task, order, isPlanOrder: widget.isPlanView);
    }
  }

  void _acceptDrop(Task task) {
    widget.onDragExiting?.call();
    ref.read(taskDragProvider.notifier).endDrag();
    final same = widget.tasks.where((t) => _inSameGroup(t, task)).toList();
    final order = TaskReorderService.computeSortOrder(
      placement: TaskPlacement.bottom,
      activeList: same,
    );
    _updateOrder(task, order);
  }

  void _handleTaskDrop(Task task, int newIndex, List<TaskHierarchyNode> nodes) {
    final order = TaskReorderUtils.handleReorder(
      nodes: nodes,
      draggedTask: task,
      newIndex: newIndex,
      settings: ref.read(settingsProvider),
      isPlanView: widget.isPlanView,
    );
    _updateOrder(task, order);
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        final canAccept = widget.isCollapsed
            ? details.data.status != widget.acceptedStatus
            : true;
        if (canAccept && details.data.status != widget.acceptedStatus) {
          widget.onDragEntering?.call();
        }
        ref.read(taskDragProvider.notifier).setValidTarget(canAccept);
        return canAccept;
      },
      onLeave: (_) {
        widget.onDragExiting?.call();
        ref.read(taskDragProvider.notifier).setValidTarget(false);
      },
      onAcceptWithDetails: (details) {
        if (details.data.status != widget.acceptedStatus) {
          _acceptDrop(details.data);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.any(
          (task) => task != null && task.status != widget.acceptedStatus,
        );
        return widget.isCollapsed
            ? KanbanCollapsedColumn(
                title: widget.title,
                titleColor: widget.titleColor,
                onToggle: widget.onToggle,
              )
            : _buildFull(context, isHighlighted);
      },
    );
  }

  Widget _buildFull(BuildContext context, bool isHighlighted) {
    final theme = Theme.of(context);
    return Consumer(
      builder: (context, ref, child) {
        final taskState = ref.watch(taskProvider);
        final allAvailableTasks = {
          for (final t in [
            ...taskState.tasks,
            ...taskState.overdueTasks,
            ...taskState.unscheduledTasks,
          ])
            t.id: t,
        };
        final projectNotifier = ref.read(projectProvider.notifier);
        final hierarchical = TaskHierarchyUtils.buildHierarchy(
          widget.tasks,
          allTasks: allAvailableTasks,
          collapsedParentIds: ref.watch(collapsedSubtasksProvider),
        );

        return TaskReorderScope(
          nodes: hierarchical,
          isPlanView: widget.isPlanView,
          onDrop: (task, newIndex) =>
              _handleTaskDrop(task, newIndex, hierarchical),
          child: Builder(
            builder: (context) {
              final scope = TaskReorderScope.of(context);
              return ValueListenableBuilder<TaskReorderActiveDrop?>(
                valueListenable: scope!.activeDropNotifier,
                builder: (context, activeDrop, _) {
                  final isScopeHighlighted =
                      activeDrop != null &&
                      activeDrop.task.status != widget.acceptedStatus;
                  final highlighted = isHighlighted || isScopeHighlighted;
                  final slotInfo = TaskReorderListSlot.from(
                    itemCount: hierarchical.length,
                    activeDrop: activeDrop,
                  );

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: highlighted
                          ? widget.titleColor.withValues(alpha: 0.1)
                          : theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: highlighted
                            ? widget.titleColor.withValues(alpha: 0.4)
                            : theme.colorScheme.surfaceContainerHigh,
                        width: highlighted ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KanbanColumnHeader(
                          title: widget.title,
                          titleColor: widget.titleColor,
                          count: widget.tasks.length,
                          isNarrow: widget.isNarrow,
                          onToggle: widget.onToggle,
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: widget.tasks.isEmpty
                              ? TaskEmptySpaceDropZone(
                                  child: Center(
                                    child: Text(
                                      'No tasks',
                                      style: TextStyle(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                )
                              : CustomScrollView(
                                  slivers: [
                                    SliverPadding(
                                      padding: const EdgeInsets.all(8),
                                      sliver: SliverList(
                                        delegate: SliverChildBuilderDelegate((
                                          context,
                                          index,
                                        ) {
                                          if (slotInfo.isPlaceholder(index)) {
                                            return TaskReorderPlaceholderItem(
                                              slotIndex:
                                                  slotInfo.placeholderIndex!,
                                              task: slotInfo.task!,
                                            );
                                          }
                                          final actualIndex = slotInfo
                                              .toOriginalIndex(index);
                                          final node =
                                              hierarchical[actualIndex];
                                          Widget childWidget =
                                              const SizedBox.shrink();
                                          if (node is TaskNode) {
                                            final task = node.task;
                                            final focusNode = widget
                                                .itemFocusNodes
                                                ?.putIfAbsent(
                                                  task.id,
                                                  () => FocusNode(
                                                    debugLabel:
                                                        'KanbanTask_${task.id}',
                                                  ),
                                                );
                                            childWidget = KanbanCard(
                                              key: ValueKey(task.id),
                                              node: node,
                                              tasks: widget.tasks,
                                              projectNotifier: projectNotifier,
                                              onContextMenu:
                                                  widget.onContextMenu,
                                              onEdit: widget.onEdit,
                                              focusNode: focusNode,
                                            );
                                          }
                                          return TaskReorderItem(
                                            index: actualIndex,
                                            child: childWidget,
                                          );
                                        }, childCount: slotInfo.totalCount),
                                      ),
                                    ),
                                    const SliverFillRemaining(
                                      hasScrollBody: false,
                                      child: TaskEmptySpaceDropZone(),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
