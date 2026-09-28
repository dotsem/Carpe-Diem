import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_drag_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card_placeholder.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_drop_zone_scope.dart';

export 'package:carpe_diem/features/tasks/presentation/widgets/task_drop_zone_scope.dart';

class TaskDropZoneWrapper extends ConsumerWidget {
  final int index;
  final Widget child;
  final void Function(Task task, int newIndex) onDrop;
  final bool Function(Task)? canAccept;
  final void Function(bool)? onHover;

  const TaskDropZoneWrapper({
    super.key,
    required this.index,
    required this.child,
    required this.onDrop,
    this.canAccept,
    this.onHover,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = TaskDropZoneScope.of(context);
    if (scope == null) return _buildStandaloneTarget(context, ref);

    return ValueListenableBuilder<TaskDropState?>(
      valueListenable: scope.activeDropNotifier,
      builder: (context, activeDrop, _) {
        final showTop =
            activeDrop != null &&
            activeDrop.index == index &&
            scope.isPositionValid(activeDrop.task, index) &&
            !scope.isPositionUnchanged(activeDrop.task, index);
        final showBottom =
            activeDrop != null &&
            activeDrop.index == index + 1 &&
            scope.isPositionValid(activeDrop.task, index + 1) &&
            !scope.isPositionUnchanged(activeDrop.task, index + 1) &&
            (index == scope.itemCount - 1 ||
                scope.isLastChildInGroup(activeDrop.task, index));

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTop)
              _buildDragSlot(
                ref: ref,
                scope: scope,
                targetIndex: index,
                placeholder: TaskCardPlaceholder(task: activeDrop.task),
              ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                child,
                Positioned.fill(
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildDragSlot(
                          ref: ref,
                          scope: scope,
                          targetIndex: index,
                        ),
                      ),
                      Expanded(
                        child: _buildDragSlot(
                          ref: ref,
                          scope: scope,
                          targetIndex: index + 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showBottom)
              _buildDragSlot(
                ref: ref,
                scope: scope,
                targetIndex: index + 1,
                placeholder: TaskCardPlaceholder(task: activeDrop.task),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDragSlot({
    required WidgetRef ref,
    required TaskDropZoneScopeInherited scope,
    required int targetIndex,
    Widget? placeholder,
  }) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        final effectiveIndex = scope.resolveEffectiveIndex(
          details.data,
          targetIndex,
        );
        if (!scope.isPositionValid(details.data, effectiveIndex)) {
          ref.read(taskDragProvider.notifier).setValidTarget(false);
          return false;
        }
        if (canAccept != null && !canAccept!(details.data)) {
          ref.read(taskDragProvider.notifier).setValidTarget(false);
          return false;
        }
        onHover?.call(true);
        scope.activeDropNotifier.value = TaskDropState(
          index: effectiveIndex,
          task: details.data,
        );
        final isUnchanged = scope.isPositionUnchanged(
          details.data,
          effectiveIndex,
        );
        ref.read(taskDragProvider.notifier).setValidTarget(!isUnchanged);
        return true;
      },
      onLeave: (details) {
        onHover?.call(false);
        if (scope.activeDropNotifier.value?.index == targetIndex) {
          scope.activeDropNotifier.value = null;
        }
        ref.read(taskDragProvider.notifier).setValidTarget(false);
      },
      onAcceptWithDetails: (details) {
        onHover?.call(false);
        final targetIndexResolved = scope.resolveEffectiveIndex(
          details.data,
          targetIndex,
        );
        scope.activeDropNotifier.value = null;
        ref.read(taskDragProvider.notifier).endDrag();
        if (scope.isPositionValid(details.data, targetIndexResolved)) {
          onDrop(details.data, targetIndexResolved);
        }
      },
      builder: (context, candidateData, rejectedData) =>
          placeholder ?? const SizedBox.expand(),
    );
  }

  Widget _buildStandaloneTarget(BuildContext context, WidgetRef ref) {
    Task? activeTask;
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        activeTask = details.data;
        onHover?.call(true);
        final accept = canAccept?.call(details.data) ?? true;
        ref.read(taskDragProvider.notifier).setValidTarget(accept);
        return accept;
      },
      onLeave: (details) {
        onHover?.call(false);
        activeTask = null;
        ref.read(taskDragProvider.notifier).setValidTarget(false);
      },
      onAcceptWithDetails: (details) {
        onHover?.call(false);
        ref.read(taskDragProvider.notifier).endDrag();
        onDrop(details.data, index);
      },
      builder: (context, candidateData, rejectedData) {
        final task = candidateData.isNotEmpty
            ? candidateData.first
            : activeTask;
        if (task != null) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TaskCardPlaceholder(task: task),
              child,
            ],
          );
        }
        return child;
      },
    );
  }
}
