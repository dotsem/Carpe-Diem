import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_drag_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_drag_proxy.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_scope.dart';
import 'package:carpe_diem/flutter_ext/platform_draggable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskPlatformDraggable extends ConsumerWidget {
  final Task task;
  final Widget child;
  final double feedbackWidth;
  final int selectedCount;

  const TaskPlatformDraggable({
    required this.task,
    required this.child,
    required this.feedbackWidth,
    super.key,
    this.selectedCount = 1,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PlatformDraggable<Task>(
      key: ValueKey('draggable_${task.id}'),
      data: task,
      onDragStarted: () {
        ref.read(taskDragProvider.notifier).startDrag(task.id);
      },
      onDragUpdate: (details) {
        ref
            .read(taskDragProvider.notifier)
            .updatePointerOffset(details.globalPosition);
      },
      onDragEnd: (details) {
        TaskReorderScope.of(context)?.handleDragEnd(details);
        ref.read(taskDragProvider.notifier).endDrag();
      },
      feedback: TaskDragProxy(
        task: task,
        selectedCount: selectedCount,
        width: feedbackWidth,
      ),
      childWhenDragging: const SizedBox.shrink(),
      child: child,
    );
  }
}
