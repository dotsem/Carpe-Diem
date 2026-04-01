import 'package:carpe_diem/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/providers/task_provider.dart';
import 'package:carpe_diem/ui/widgets/blocker_indicator.dart';
import 'package:carpe_diem/ui/widgets/chip/small_chip.dart';
import 'package:carpe_diem/ui/widgets/context_menu/task_card_context_menu.dart';
import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/ui/widgets/task_hierarchy_indicator.dart';
import 'package:carpe_diem/ui/widgets/task_card.dart';
import 'package:flutter/material.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/data/models/task.dart';
import 'package:carpe_diem/data/models/task_status.dart';
import 'package:carpe_diem/providers/project_provider.dart';
import 'package:provider/provider.dart';

class KanbanBoard extends StatefulWidget {
  final List<Task> tasks;
  final ProjectProvider projectProvider;
  final void Function(Task task, TaskStatus status) onStatusChange;
  final void Function(Task task, Offset localPosition, RenderBox renderBox) onContextMenu;
  final void Function(Task task) onEdit;
  final Map<String, FocusNode>? itemFocusNodes;
  final ValueChanged<List<String>>? onOrderedIdsChanged;

  const KanbanBoard({
    super.key,
    required this.tasks,
    required this.projectProvider,
    required this.onStatusChange,
    required this.onContextMenu,
    required this.onEdit,
    this.itemFocusNodes,
    this.onOrderedIdsChanged,
  });

  @override
  State<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<KanbanBoard> {
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
    final tasks = widget.tasks;
    final todo = tasks.where((t) => t.status.isTodo).toList();
    final inProgress = tasks.where((t) => t.status.isInProgress).toList();
    final done = tasks.where((t) => t.status.isDone).toList();

    if (widget.onOrderedIdsChanged != null) {
      final taskProvider = context.read<TaskProvider>();
      final allAvailableTasks = {for (var t in taskProvider.tasks) t.id: t}
        ..addAll({for (var t in taskProvider.overdueTasks) t.id: t})
        ..addAll({for (var t in taskProvider.unscheduledTasks) t.id: t});

      List<String> getFlatIds(List<Task> categoryTasks) {
        final flattened = TaskHierarchyUtils.buildHierarchy(categoryTasks, allTasks: allAvailableTasks);
        return flattened.whereType<TaskNode>().map((n) => n.task.id).toList();
      }

      // Exclude 'done' column from sequential navigation as requested
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
                  child: _KanbanColumn(
                    title: 'Todo',
                    titleColor: AppColors.text,
                    tasks: todo,
                    acceptedStatus: TaskStatus.todo,
                    projectProvider: widget.projectProvider,
                    onStatusChange: widget.onStatusChange,
                    onContextMenu: widget.onContextMenu,
                    onEdit: widget.onEdit,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: responsiveColumnWidth,
                  child: _KanbanColumn(
                    title: 'In Progress',
                    titleColor: AppColors.accent,
                    tasks: inProgress,
                    acceptedStatus: TaskStatus.inProgress,
                    projectProvider: widget.projectProvider,
                    onStatusChange: widget.onStatusChange,
                    onContextMenu: widget.onContextMenu,
                    onEdit: widget.onEdit,
                  ),
                ),
                const SizedBox(width: 16),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(end: isExpanded ? responsiveColumnWidth : 24),
                  onEnd: () {
                    if (mounted) setState(() => _isTransitioning = false);
                  },
                  builder: (context, width, child) {
                    if (_isTransitioning && _scrollController.hasClients && isExpanded) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients && _isTransitioning) {
                          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                        }
                      });
                    }

                    return SizedBox(
                      width: width,
                      child: _KanbanColumn(
                        title: 'Done',
                        titleColor: AppColors.success,
                        tasks: done,
                        isNarrow: isNarrow,
                        acceptedStatus: TaskStatus.done,
                        projectProvider: widget.projectProvider,
                        onStatusChange: widget.onStatusChange,
                        onContextMenu: widget.onContextMenu,
                        onEdit: widget.onEdit,
                        itemFocusNodes: widget.itemFocusNodes,
                        isCollapsed: !isExpanded,
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
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final Color titleColor;
  final List<Task> tasks;
  final TaskStatus acceptedStatus;
  final ProjectProvider projectProvider;
  final void Function(Task task, TaskStatus status) onStatusChange;
  final void Function(Task task, Offset localPosition, RenderBox renderBox) onContextMenu;
  final void Function(Task task) onEdit;
  final bool isCollapsed;
  final bool isNarrow;
  final VoidCallback? onToggle;
  final VoidCallback? onDragEntering;
  final VoidCallback? onDragExiting;
  final Map<String, FocusNode>? itemFocusNodes;

  const _KanbanColumn({
    required this.title,
    required this.titleColor,
    required this.tasks,
    required this.acceptedStatus,
    required this.projectProvider,
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
  Widget build(BuildContext context) {
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
        return _buildFull(context, candidateData.isNotEmpty);
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              SmallChip(
                padding: EdgeInsets.all(2.0),
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

  Widget _buildFull(BuildContext context, bool isHighlighted) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isHighlighted ? titleColor.withValues(alpha: 0.1) : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? titleColor.withValues(alpha: 0.4) : AppColors.surfaceLight,
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
                    color: AppColors.textSecondary,
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
                      child: Text('Drop tasks here', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final taskProvider = context.read<TaskProvider>();
                      final allAvailableTasks = {for (var t in taskProvider.tasks) t.id: t}
                        ..addAll({for (var t in taskProvider.overdueTasks) t.id: t})
                        ..addAll({for (var t in taskProvider.unscheduledTasks) t.id: t});

                      final hierarchical = TaskHierarchyUtils.buildHierarchy(tasks, allTasks: allAvailableTasks);
                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: hierarchical.length,
                        itemBuilder: (context, index) {
                          final node = hierarchical[index];
                          if (node is TaskNode) {
                            final task = node.task;
                            // Critical: Registration in shared map allows parent screen to track current focus
                            final focusNode = itemFocusNodes?.putIfAbsent(
                              task.id,
                              () => FocusNode(debugLabel: 'KanbanTask_${task.id}'),
                            );
                            return _KanbanCard(
                              key: ValueKey(task.id),
                              node: node,
                              project: projectProvider,
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

class _KanbanCard extends StatelessWidget {
  final TaskNode node;
  final ProjectProvider project;
  final void Function(Task task, Offset localPosition, RenderBox renderBox) onContextMenu;
  final void Function(Task task) onEdit;
  final FocusNode? focusNode;

  const _KanbanCard({
    super.key,
    required this.node,
    required this.project,
    required this.onContextMenu,
    required this.onEdit,
    this.focusNode,
  });

  Task get task => node.task;
  int get depth => node.depth;

  bool get isOverdue {
    if (task.scheduledDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return task.scheduledDate!.isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
          child: Text(task.title, style: const TextStyle(color: AppColors.text, fontSize: 14)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _wrapHierarchy(context, task, project, context.read<TaskProvider>(), isOverdue: isOverdue),
      ),
      child: _wrapHierarchy(context, task, project, context.read<TaskProvider>(), isOverdue: isOverdue),
    );
  }

  Widget _wrapHierarchy(
    BuildContext context,
    Task task,
    ProjectProvider projectProvider,
    TaskProvider provider, {
    bool isOverdue = false,
  }) {
    final card = _buildTaskCard(context, task, projectProvider, provider, isOverdue: isOverdue);

    return TaskHierarchyIndicator(depth: depth, child: card);
  }

  TaskCard _buildTaskCard(
    BuildContext context,
    Task task,
    ProjectProvider projectProvider,
    TaskProvider provider, {
    bool isOverdue = false,
  }) {
    return TaskCard(
      key: ValueKey(task.id),
      task: task,
      project: task.projectId != null ? projectProvider.getById(task.projectId!) : null,
      isOverdue: isOverdue,
      useTimer: false,
      leading: Container(),
      focusNode: focusNode,
      onToggle: (_) => provider.toggleComplete(task),
      onTap: () => onEdit(task),
      onContextMenu: (localPosition, renderBox) => showTaskCardContextMenu(context, task, localPosition, renderBox),
    );
  }
}
