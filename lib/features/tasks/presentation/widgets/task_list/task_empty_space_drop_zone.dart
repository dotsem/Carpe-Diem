import 'package:flutter/material.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_scope.dart';

class TaskEmptySpaceDropZone extends StatelessWidget {
  final void Function(Task task, int newIndex)? onDrop;

  final Widget? child;

  const TaskEmptySpaceDropZone({super.key, this.onDrop, this.child});

  @override
  Widget build(BuildContext context) {
    final scope = TaskReorderScope.of(context);
    if (scope == null) return child ?? const SizedBox.shrink();

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        scope.onHoverSlot(details.data, scope.nodes.length);
        return true;
      },
      onLeave: (details) {
        scope.onLeaveSlot();
      },
      onAcceptWithDetails: (details) {
        scope.drop(details.data, scope.nodes.length);
      },
      builder: (context, candidateData, rejectedData) =>
          child ?? const SizedBox.expand(),
    );
  }
}
