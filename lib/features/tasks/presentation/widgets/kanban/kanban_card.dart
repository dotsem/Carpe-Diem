import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/context_menu/task_card_context_menu.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_drag_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card_dotted_placeholder.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_hierarchy_indicator.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_drag_proxy.dart';
import 'package:carpe_diem/features/common/presentation/widgets/platform_draggable.dart';

class KanbanCard extends ConsumerWidget {
  final TaskNode node;
  final ProjectNotifier projectNotifier;
  final List<Task> tasks;
  final void Function(Task task, Offset localPosition, RenderBox renderBox)
  onContextMenu;
  final void Function(Task task) onEdit;
  final FocusNode? focusNode;

  const KanbanCard({
    super.key,
    required this.node,
    required this.projectNotifier,
    required this.tasks,
    required this.onContextMenu,
    required this.onEdit,
    this.focusNode,
  });

  Task get task => node.task;
  int get depth => node.depth;
  bool get isOverdue => task.isOverdue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragSession = ref.watch(taskDragProvider);
    final isThisTaskDragged = dragSession.draggedTaskId == task.id;
    final showDotted = isThisTaskDragged && dragSession.hasValidTarget;

    final cardContent = _wrapHierarchy(
      context,
      ref,
      task,
      projectNotifier,
      isOverdue: isOverdue,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return PlatformDraggable<Task>(
          data: task,
          delay: const Duration(milliseconds: 150),
          onDragStarted: () {
            ref.read(taskDragProvider.notifier).startDrag(task.id);
          },
          onDragEnd: (_) {
            ref.read(taskDragProvider.notifier).endDrag();
          },
          feedback: TaskDragProxy(
            task: task,
            selectedCount: 1,
            width: constraints.maxWidth,
          ),
          childWhenDragging: showDotted
              ? TaskHierarchyIndicator(
                  depth: depth,
                  child: TaskCardDottedPlaceholder(
                    child: _buildTaskCard(
                      context,
                      ref,
                      task,
                      projectNotifier,
                      isOverdue: isOverdue,
                    ),
                  ),
                )
              : Opacity(opacity: 0.3, child: cardContent),
          child: cardContent,
        );
      },
    );
  }

  Widget _wrapHierarchy(
    BuildContext context,
    WidgetRef ref,
    Task task,
    ProjectNotifier projectNotifier, {
    bool isOverdue = false,
  }) {
    final card = _buildTaskCard(
      context,
      ref,
      task,
      projectNotifier,
      isOverdue: isOverdue,
    );
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
    final isNested = node.isBundledUnderParent;
    return TaskCard(
      key: ValueKey(task.id),
      task: task,
      project: task.projectId != null
          ? projectNotifier.getById(task.projectId!)
          : null,
      hideProjectInfo: isNested,
      hideProjectGradient: false,
      isOverdue: isOverdue,
      useTimer: false,
      leading: Container(),
      focusNode: focusNode,
      onToggle: (_) => taskNotifier.toggleComplete(task),
      onTap: () => onEdit(task),
      onContextMenu: (localPosition, renderBox) => showTaskCardContextMenu(
        context,
        ref,
        task,
        tasks,
        localPosition,
        renderBox,
      ),
    );
  }
}
