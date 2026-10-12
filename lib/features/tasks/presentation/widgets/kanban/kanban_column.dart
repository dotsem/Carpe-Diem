import 'package:carpe_diem/core/utils/task_hierarchy_reorder_utils.dart';
import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/core/utils/task_reorder_utils.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/small_chip.dart';
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
import 'package:carpe_diem/features/tasks/presentation/widgets/task_drop_zone.dart';
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
  int _hoveredChildren = 0;

  bool _inSameGroup(Task a, Task b) {
    final s = ref.read(settingsProvider);
    return TaskReorderUtils.inSameGroup(a, b, s, isPlanView: widget.isPlanView);
  }

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
    _updateOrder(
      task,
      TaskReorderService.computeSortOrder(
        placement: TaskPlacement.bottom,
        activeList: same,
      ),
    );
  }

  void _handleTaskDrop(Task task, int newIndex, List<TaskHierarchyNode> nodes) {
    _updateOrder(
      task,
      TaskReorderUtils.handleReorder(
        nodes: nodes,
        draggedTask: task,
        newIndex: newIndex,
        settings: ref.read(settingsProvider),
        isPlanView: widget.isPlanView,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        final canAccept = details.data.status != widget.acceptedStatus;
        if (canAccept) widget.onDragEntering?.call();
        ref.read(taskDragProvider.notifier).setValidTarget(canAccept);
        return canAccept;
      },
      onLeave: (_) {
        widget.onDragExiting?.call();
        ref.read(taskDragProvider.notifier).setValidTarget(false);
      },
      onAcceptWithDetails: (details) => _acceptDrop(details.data),
      builder: (context, candidateData, rejectedData) => widget.isCollapsed
          ? KanbanCollapsedColumn(
              title: widget.title,
              titleColor: widget.titleColor,
              onToggle: widget.onToggle,
            )
          : _buildFull(
              context,
              candidateData.isNotEmpty || _hoveredChildren > 0,
            ),
    );
  }

  Widget _buildFull(BuildContext context, bool isHighlighted) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isHighlighted
            ? widget.titleColor.withValues(alpha: 0.1)
            : theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? widget.titleColor.withValues(alpha: 0.4)
              : theme.colorScheme.surfaceContainerHigh,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.titleColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                SmallChip(
                  borderRadius: 10,
                  color: widget.titleColor.withValues(alpha: 0.15),
                  child: Text(
                    '${widget.tasks.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.titleColor,
                    ),
                  ),
                ),
                if (widget.onToggle != null && widget.isNarrow)
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 16),
                    onPressed: widget.onToggle,
                    padding: const EdgeInsets.only(left: 4),
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: widget.tasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : Consumer(
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
                      final projectNotifier = ref.read(
                        projectProvider.notifier,
                      );
                      final hierarchical = TaskHierarchyUtils.buildHierarchy(
                        widget.tasks,
                        allTasks: allAvailableTasks,
                        collapsedParentIds: ref.watch(
                          collapsedSubtasksProvider,
                        ),
                      );
                      return TaskDropZoneScope(
                        urgentSectionEndIndex:
                            TaskReorderUtils.getUrgentSectionEndIndex(
                              hierarchical,
                            ),
                        itemCount: hierarchical.length,
                        isPositionUnchanged: (task, targetIndex) =>
                            TaskReorderUtils.isPositionUnchangedInNodes(
                              draggedTask: task,
                              targetIndex: targetIndex,
                              nodes: hierarchical,
                            ),
                        isPositionValid: (task, targetIndex) =>
                            TaskHierarchyReorderUtils.isPositionValidInNodes(
                              draggedTask: task,
                              targetIndex: targetIndex,
                              nodes: hierarchical,
                              settings: ref.read(settingsProvider),
                              isPlanView: widget.isPlanView,
                            ),
                        isLastChildInGroup: (task, index) =>
                            TaskHierarchyReorderUtils.isLastChildInGroup(
                              task: task,
                              index: index,
                              nodes: hierarchical,
                            ),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: hierarchical.length,
                          itemBuilder: (context, index) {
                            final node = hierarchical[index];
                            Widget childWidget = const SizedBox.shrink();

                            if (node is TaskNode) {
                              final task = node.task;
                              final focusNode = widget.itemFocusNodes
                                  ?.putIfAbsent(
                                    task.id,
                                    () => FocusNode(
                                      debugLabel: 'KanbanTask_${task.id}',
                                    ),
                                  );
                              childWidget = KanbanCard(
                                key: ValueKey(task.id),
                                node: node,
                                tasks: widget.tasks,
                                projectNotifier: projectNotifier,
                                onContextMenu: widget.onContextMenu,
                                onEdit: widget.onEdit,
                                focusNode: focusNode,
                              );
                            }

                            return TaskDropZoneWrapper(
                              index: index,
                              onHover: (hovered) => setState(() {
                                _hoveredChildren += hovered ? 1 : -1;
                              }),
                              onDrop: (task, newIndex) =>
                                  _handleTaskDrop(task, newIndex, hierarchical),
                              child: childWidget,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
