import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card_context_menu.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/blocker_indicator.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_hierarchy_indicator.dart';
import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/small_chip.dart';

class KanbanColumn extends ConsumerWidget {
  final String title;
  final Color titleColor;
  final List<Task> tasks;
  final TaskStatus acceptedStatus;
  final void Function(Task task, TaskStatus status) onStatusChange;
  final void Function(Task task, Offset localPosition, RenderBox renderBox) onContextMenu;
  final void Function(Task task) onEdit;
  final bool isCollapsed;
  final bool isNarrow;
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
    this.isCollapsed = false,
    this.onToggle,
    this.onDragEntering,
    this.onDragExiting,
    this.itemFocusNodes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        if (details.data.status != acceptedStatus) {
          onDragEntering?.call();
          return true;
        }
        return false;
      },
      onLeave: (details) => onDragExiting?.call(),
      onAcceptWithDetails: (details) {
        onDragExiting?.call();
        onStatusChange(details.data, acceptedStatus);
      },
      builder: (context, candidateData, rejectedData) {
        if (isCollapsed) {
          return _buildCollapsed(context);
        }
        return _buildFull(context, ref, candidateData.isNotEmpty);
      },
    );
  }

  Widget _buildCollapsed(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHigh),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              SmallChip(
                padding: const EdgeInsets.all(2.0),
                borderRadius: 10,
                color: titleColor.withValues(alpha: 0.15),
                child: Text(
                  '${tasks.length}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: titleColor),
                ),
              ),
              const SizedBox(height: 12),
              RotatedBox(
                quarterTurns: 1,
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: titleColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context, WidgetRef ref, bool isHighlighted) {
    final projectNotifier = ref.read(projectProvider.notifier);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isHighlighted ? titleColor.withValues(alpha: 0.1) : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? titleColor.withValues(alpha: 0.4) : Theme.of(context).colorScheme.surfaceContainerHigh,
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
                    title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: titleColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                SmallChip(
                  borderRadius: 10,
                  color: titleColor.withValues(alpha: 0.15),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: titleColor),
                  ),
                ),
                if (onToggle != null && isNarrow) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 16),
                    onPressed: onToggle,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Drop tasks here',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final taskState = ref.watch(taskProvider);
                      final allAvailableTasks = {for (var t in taskState.tasks) t.id: t}
                        ..addAll({for (var t in taskState.overdueTasks) t.id: t})
                        ..addAll({for (var t in taskState.unscheduledTasks) t.id: t});

                      final hierarchical = TaskHierarchyUtils.buildHierarchy(tasks, allTasks: allAvailableTasks);
                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: hierarchical.length,
                        itemBuilder: (context, index) {
                          final node = hierarchical[index];
                          if (node is TaskNode) {
                            final task = node.task;
                            final focusNode = itemFocusNodes?.putIfAbsent(
                              task.id,
                              () => FocusNode(debugLabel: 'KanbanTask_${task.id}'),
                            );
                            return KanbanCard(
                              key: ValueKey(task.id),
                              node: node,
                              projectNotifier: projectNotifier,
                              onContextMenu: onContextMenu,
                              onEdit: onEdit,
                              focusNode: focusNode,
                            );
                          } else if (node is BlockerIndicatorNode) {
                            return TaskHierarchyIndicator(
                              depth: node.depth,
                              child: BlockerIndicator(
                                blockerId: node.blockerId,
                                blockerTitle: node.blockerTitle,
                                blockedTaskId: node.blockedTaskId,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class KanbanCard extends ConsumerWidget {
  final TaskNode node;
  final ProjectNotifier projectNotifier;
  final void Function(Task task, Offset localPosition, RenderBox renderBox) onContextMenu;
  final void Function(Task task) onEdit;
  final FocusNode? focusNode;

  const KanbanCard({
    super.key,
    required this.node,
    required this.projectNotifier,
    required this.onContextMenu,
    required this.onEdit,
    this.focusNode,
  });

  Task get task => node.task;
  int get depth => node.depth;
  bool get isOverdue => task.isOverdue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(task.title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _wrapHierarchy(context, ref, task, projectNotifier, isOverdue: isOverdue),
      ),
      child: _wrapHierarchy(context, ref, task, projectNotifier, isOverdue: isOverdue),
    );
  }

  Widget _wrapHierarchy(
    BuildContext context,
    WidgetRef ref,
    Task task,
    ProjectNotifier projectNotifier, {
    bool isOverdue = false,
  }) {
    final card = _buildTaskCard(context, ref, task, projectNotifier, isOverdue: isOverdue);
    return TaskHierarchyIndicator(depth: depth, child: card);
  }

  TaskCard _buildTaskCard(
    BuildContext context,
    WidgetRef ref,
    Task task,
    ProjectNotifier projectNotifier, {
    bool isOverdue = false,
  }) {
    final taskNotifier = ref.read(taskProvider.notifier);
    return TaskCard(
      key: ValueKey(task.id),
      task: task,
      project: task.projectId != null ? projectNotifier.getById(task.projectId!) : null,
      isOverdue: isOverdue,
      useTimer: false,
      leading: Container(),
      focusNode: focusNode,
      onToggle: (_) => taskNotifier.toggleComplete(task),
      onTap: () => onEdit(task),
      onContextMenu: (localPosition, renderBox) =>
          showTaskCardContextMenu(context, ref, task, localPosition, renderBox),
    );
  }
}
