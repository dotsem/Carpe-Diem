import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/blocker_indicator.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_hierarchy_indicator.dart';
import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/core/utils/task_reorder_utils.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/chip/small_chip.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/kanban/kanban_card.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_drop_zone.dart';

class KanbanColumn extends ConsumerStatefulWidget {
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
  ConsumerState<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends ConsumerState<KanbanColumn> {
  int _hoveredChildren = 0;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        if (details.data.status != widget.acceptedStatus) {
          widget.onDragEntering?.call();
          return true;
        }
        return false;
      },
      onLeave: (details) => widget.onDragExiting?.call(),
      onAcceptWithDetails: (details) {
        widget.onDragExiting?.call();
        widget.onStatusChange(details.data, widget.acceptedStatus);
      },
      builder: (context, candidateData, rejectedData) {
        if (widget.isCollapsed) {
          return _buildCollapsed(context);
        }
        return _buildFull(context, candidateData.isNotEmpty || _hoveredChildren > 0);
      },
    );
  }

  Widget _buildCollapsed(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.titleColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.titleColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context, bool isHighlighted) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isHighlighted ? widget.titleColor.withValues(alpha: 0.1) : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? widget.titleColor.withValues(alpha: 0.4) : Theme.of(context).colorScheme.surfaceContainerHigh,
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: widget.titleColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                SmallChip(
                  borderRadius: 10,
                  color: widget.titleColor.withValues(alpha: 0.15),
                  child: Text(
                    '${widget.tasks.length}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.titleColor),
                  ),
                ),
                if (widget.onToggle != null && widget.isNarrow) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 16),
                    onPressed: widget.onToggle,
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
            child: widget.tasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  )
                : Consumer(
                    builder: (context, ref, child) {
                      final taskState = ref.watch(taskProvider);
                      final allAvailableTasks = {for (var t in taskState.tasks) t.id: t}
                        ..addAll({for (var t in taskState.overdueTasks) t.id: t})
                        ..addAll({for (var t in taskState.unscheduledTasks) t.id: t});

                      final projectNotifier = ref.read(projectProvider.notifier);
                      final hierarchical = TaskHierarchyUtils.buildHierarchy(widget.tasks, allTasks: allAvailableTasks);
                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: hierarchical.length,
                        itemBuilder: (context, index) {
                          final node = hierarchical[index];
                          
                          Widget childWidget = const SizedBox.shrink();

                          if (node is TaskNode) {
                            final task = node.task;
                            final focusNode = widget.itemFocusNodes?.putIfAbsent(
                              task.id,
                              () => FocusNode(debugLabel: 'KanbanTask_${task.id}'),
                            );
                            childWidget = KanbanCard(
                              key: ValueKey(task.id),
                              node: node,
                              projectNotifier: projectNotifier,
                              onContextMenu: widget.onContextMenu,
                              onEdit: widget.onEdit,
                              focusNode: focusNode,
                            );
                          } else if (node is BlockerIndicatorNode) {
                            childWidget = TaskHierarchyIndicator(
                              depth: node.depth,
                              child: BlockerIndicator(
                                blockerId: node.blockerId,
                                blockerTitle: node.blockerTitle,
                                blockedTaskId: node.blockedTaskId,
                              ),
                            );
                          }

                          return TaskDropZoneWrapper(
                            index: index,
                            onHover: (hovered) {
                              setState(() {
                                if (hovered) {
                                  _hoveredChildren++;
                                } else {
                                  _hoveredChildren--;
                                }
                              });
                            },
                            onDrop: (task, newIndex) {
                              final settings = ref.read(settingsProvider);
                              final newSortOrder = TaskReorderUtils.handleReorder(
                                nodes: hierarchical,
                                draggedTask: task,
                                newIndex: newIndex,
                                settings: settings,
                              );
                              if (newSortOrder != null) {
                                ref.read(taskProvider.notifier).reorderTask(task, newSortOrder);
                              }
                              if (task.status != widget.acceptedStatus) {
                                widget.onStatusChange(task, widget.acceptedStatus);
                              }
                            },
                            child: childWidget,
                          );
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
