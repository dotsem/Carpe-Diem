import 'package:carpe_diem/core/theme/animation_context.dart';
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
  final void Function(Task, Offset, RenderBox) onContextMenu;
  final void Function(Task) onEdit;
  final bool isCollapsed, isNarrow, isPlanView;
  final VoidCallback? onToggle, onDragEntering, onDragExiting;
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
      final updated = order ?? task.sortOrder;
      final plan = widget.isPlanView ? updated : null;
      widget.onStatusChange(
        task.copyWith(sortOrder: updated, planSortOrder: plan),
        widget.acceptedStatus,
      );
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

  FocusNode? _focusNode(String id) => widget.itemFocusNodes?.putIfAbsent(
    id,
    () => FocusNode(debugLabel: 'Task_$id'),
  );

  @override
  Widget build(BuildContext context) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        final foreign = details.data.status != widget.acceptedStatus;
        final canAccept = !widget.isCollapsed || foreign;
        if (canAccept && foreign) widget.onDragEntering?.call();
        ref.read(taskDragProvider.notifier).setValidTarget(canAccept);
        return canAccept;
      },
      onLeave: (_) {
        widget.onDragExiting?.call();
        ref.read(taskDragProvider.notifier).setValidTarget(false);
      },
      onAcceptWithDetails: (details) {
        final foreign = details.data.status != widget.acceptedStatus;
        if (!widget.isCollapsed || foreign) _acceptDrop(details.data);
      },
      builder: (context, candidateData, _) => widget.isCollapsed
          ? KanbanCollapsedColumn(
              title: widget.title,
              titleColor: widget.titleColor,
              onToggle: widget.onToggle,
            )
          : _buildFull(
              context,
              candidateData.any(
                (t) => t != null && t.status != widget.acceptedStatus,
              ),
            ),
    );
  }

  static const _bottomDropZone = SliverToBoxAdapter(
    child: SizedBox(height: 48, child: TaskEmptySpaceDropZone()),
  );

  Widget _buildEmpty(ThemeData theme) => TaskEmptySpaceDropZone(
    child: Center(
      child: Text(
        'No tasks',
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
    ),
  );

  BoxDecoration _decoration(ThemeData theme, bool hi) => BoxDecoration(
    color: hi
        ? widget.titleColor.withValues(alpha: 0.1)
        : theme.scaffoldBackgroundColor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: hi
          ? widget.titleColor.withValues(alpha: 0.4)
          : theme.colorScheme.surfaceContainerHigh,
      width: hi ? 2 : 1,
    ),
  );

  Widget _buildFull(BuildContext context, bool isHighlighted) {
    final theme = Theme.of(context);
    final hierarchical = TaskHierarchyUtils.buildHierarchy(
      widget.tasks,
      allTasks: {for (final t in ref.watch(taskProvider).allTasks) t.id: t},
      collapsedParentIds: ref.watch(collapsedSubtasksProvider),
    );
    final projectNotifier = ref.read(projectProvider.notifier);

    return TaskReorderScope(
      nodes: hierarchical,
      isPlanView: widget.isPlanView,
      onDrop: (task, newIndex) => _handleTaskDrop(task, newIndex, hierarchical),
      child: Builder(
        builder: (context) {
          final scope = TaskReorderScope.of(context);
          return ValueListenableBuilder<TaskReorderActiveDrop?>(
            valueListenable: scope!.activeDropNotifier,
            builder: (context, activeDrop, _) {
              final isTarget =
                  activeDrop != null &&
                  activeDrop.task.status != widget.acceptedStatus;
              final highlighted = isHighlighted || isTarget;
              final slotInfo = TaskReorderListSlot.forNodes(
                nodes: hierarchical,
                activeDrop: activeDrop,
                draggedTaskId: ref.watch(taskDragProvider).draggedTaskId,
              );

              return AnimatedContainer(
                duration: context.animationsEnabled
                    ? const Duration(milliseconds: 200)
                    : Duration.zero,
                curve: Curves.easeInOut,
                decoration: _decoration(theme, highlighted),
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
                      child:
                          (slotInfo.totalCount == 0 &&
                              slotInfo.placeholderIndex == null)
                          ? _buildEmpty(theme)
                          : CustomScrollView(
                              slivers: [
                                SliverPadding(
                                  padding: const EdgeInsets.all(8),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final actual =
                                            slotInfo.isPlaceholder(index)
                                            ? null
                                            : slotInfo.toOriginalIndex(index);
                                        final node = actual != null
                                            ? hierarchical[actual]
                                            : null;
                                        return KanbanCardItem(
                                          index: index,
                                          slotInfo: slotInfo,
                                          activeDrop: activeDrop,
                                          nodes: hierarchical,
                                          child: node is TaskNode
                                              ? KanbanCard(
                                                  key: ValueKey(node.task.id),
                                                  node: node,
                                                  tasks: widget.tasks,
                                                  projectNotifier:
                                                      projectNotifier,
                                                  onContextMenu:
                                                      widget.onContextMenu,
                                                  onEdit: widget.onEdit,
                                                  focusNode: _focusNode(
                                                    node.task.id,
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                        );
                                      },
                                      childCount: slotInfo.totalCount,
                                      findChildIndexCallback: (k) =>
                                          slotInfo.findChildIndex(
                                            k,
                                            prefix: 'kanban_',
                                            nodes: hierarchical,
                                          ),
                                    ),
                                  ),
                                ),
                                _bottomDropZone,
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
  }
}
