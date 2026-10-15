import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_drag_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_drop_zone_scope.dart';

class TaskEmptySpaceDropZone extends ConsumerWidget {
  final void Function(Task task, int newIndex) onDrop;

  const TaskEmptySpaceDropZone({super.key, required this.onDrop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = TaskDropZoneScope.of(context);
    if (scope == null) return const SizedBox.shrink();

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        final task = details.data;
        final effectiveIndex = scope.resolveClampedBottomIndex(task);
        if (!scope.isPositionValid(task, effectiveIndex)) {
          ref.read(taskDragProvider.notifier).setValidTarget(false);
          return false;
        }
        scope.activeDropNotifier.value = TaskDropState(
          index: effectiveIndex,
          task: task,
        );
        final isUnchanged = scope.isPositionUnchanged(task, effectiveIndex);
        ref.read(taskDragProvider.notifier).setValidTarget(!isUnchanged);
        return true;
      },
      onLeave: (details) {
        scope.activeDropNotifier.value = null;
        ref.read(taskDragProvider.notifier).setValidTarget(false);
      },
      onAcceptWithDetails: (details) {
        final task = details.data;
        final effectiveIndex = scope.resolveClampedBottomIndex(task);
        scope.activeDropNotifier.value = null;
        ref.read(taskDragProvider.notifier).endDrag();
        if (scope.isPositionValid(task, effectiveIndex)) {
          onDrop(task, effectiveIndex);
        }
      },
      builder: (context, candidateData, rejectedData) =>
          const SizedBox.expand(),
    );
  }
}
