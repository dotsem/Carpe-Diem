import 'package:flutter/material.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_engine.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card_placeholder.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_scope.dart';

class TaskReorderItem extends StatefulWidget {
  final int index;
  final Widget child;
  final bool Function(Task)? canAccept;

  const TaskReorderItem({
    super.key,
    required this.index,
    required this.child,
    this.canAccept,
  });

  @override
  State<TaskReorderItem> createState() => _TaskReorderItemState();
}

class _TaskReorderItemState extends State<TaskReorderItem> {
  final GlobalKey _childKey = GlobalKey();

  int _resolveRawIndex(Offset globalOffset) {
    final box = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final localY = box.globalToLocal(globalOffset).dy;
      return localY < (box.size.height / 2) ? widget.index : widget.index + 1;
    }
    return widget.index;
  }

  @override
  Widget build(BuildContext context) {
    final scope = TaskReorderScope.of(context);
    if (scope == null) return widget.child;

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        if (widget.canAccept != null && !widget.canAccept!(details.data)) {
          return false;
        }
        final rawIndex = _resolveRawIndex(details.offset);
        scope.onHoverSlot(details.data, rawIndex);
        return true;
      },
      onMove: (details) {
        final rawIndex = _resolveRawIndex(details.offset);
        scope.onHoverSlot(details.data, rawIndex);
      },
      onLeave: (_) {
        scope.onLeaveSlot();
      },
      onAcceptWithDetails: (details) {
        final rawIndex = _resolveRawIndex(details.offset);
        scope.drop(details.data, rawIndex);
      },
      builder: (context, _, _) {
        return ValueListenableBuilder<TaskReorderActiveDrop?>(
          valueListenable: scope.activeDropNotifier,
          builder: (context, activeDrop, _) {
            final isLast =
                widget.index == scope.nodes.length - 1 ||
                (activeDrop != null &&
                    TaskReorderEngine.isLastChildInGroup(
                      task: activeDrop.task,
                      index: widget.index,
                      nodes: scope.nodes,
                    ));

            final showTop =
                activeDrop != null &&
                activeDrop.slot.isValid &&
                !activeDrop.slot.isUnchanged &&
                activeDrop.slot.index == widget.index;

            final showBottom =
                activeDrop != null &&
                activeDrop.slot.isValid &&
                !activeDrop.slot.isUnchanged &&
                activeDrop.slot.index == widget.index + 1 &&
                isLast;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showTop) TaskCardPlaceholder(task: activeDrop.task),
                KeyedSubtree(key: _childKey, child: widget.child),
                if (showBottom) TaskCardPlaceholder(task: activeDrop.task),
              ],
            );
          },
        );
      },
    );
  }
}
