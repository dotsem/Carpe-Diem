import 'package:carpe_diem/core/theme/animation_context.dart';
import 'package:flutter/material.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_scope.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_list_slot.dart';

export 'package:carpe_diem/features/tasks/presentation/widgets/task_reorder_list_slot.dart';

class TaskReorderItem extends StatefulWidget {
  final int index;
  final int? visualIndex;
  final Widget child;
  final bool Function(Task)? canAccept;

  const TaskReorderItem({
    super.key,
    required this.index,
    this.visualIndex,
    required this.child,
    this.canAccept,
  });

  @override
  State<TaskReorderItem> createState() => _TaskReorderItemState();
}

class _TaskReorderItemState extends State<TaskReorderItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final CurvedAnimation _curvedAnimation;
  late Animation<Offset> _animation;

  int get _currentVisualIndex => widget.visualIndex ?? widget.index;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _animation = const AlwaysStoppedAnimation(Offset.zero);
  }

  @override
  void didUpdateWidget(covariant TaskReorderItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldVisual = oldWidget.visualIndex ?? oldWidget.index;
    final newVisual = _currentVisualIndex;
    if (oldVisual != newVisual) {
      if (!context.animationsEnabled) return;
      final delta = (oldVisual - newVisual).toDouble();
      if (delta.abs() <= 3) {
        setState(() {
          _animation = Tween<Offset>(
            begin: Offset(0, delta),
            end: Offset.zero,
          ).animate(_curvedAnimation);
        });
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _curvedAnimation.dispose();
    _controller.dispose();
    super.dispose();
  }

  int _resolveRawIndex(
    BuildContext context,
    Offset globalOffset,
    Offset? pointerOffset,
    TaskReorderScopeInherited? scope,
  ) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final targetOffset = pointerOffset ?? globalOffset;
      final localY = box.globalToLocal(targetOffset).dy;
      if (localY >= box.size.height) return widget.index + 1;
      final ratio = localY / box.size.height;
      final currentDropIndex = scope?.activeDropNotifier.value?.index;
      final threshold = currentDropIndex == widget.index
          ? 0.65
          : (currentDropIndex == widget.index + 1 ? 0.35 : 0.50);
      return ratio < threshold ? widget.index : widget.index + 1;
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
        final rawIndex = _resolveRawIndex(
          context,
          details.offset,
          scope.pointerOffset,
          scope,
        );
        scope.onHoverSlot(details.data, rawIndex);
        return true;
      },
      onMove: (details) {
        final rawIndex = _resolveRawIndex(
          context,
          details.offset,
          scope.pointerOffset,
          scope,
        );
        scope.onHoverSlot(details.data, rawIndex);
      },
      onLeave: (_) {
        scope.onLeaveSlot();
      },
      onAcceptWithDetails: (details) {
        final rawIndex = _resolveRawIndex(
          context,
          details.offset,
          scope.pointerOffset,
          scope,
        );
        scope.drop(details.data, rawIndex);
      },
      builder: (context, _, _) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (_animation.value == Offset.zero) return child!;
          return FractionalTranslation(
            translation: _animation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class TaskReorderPlaceholderItem extends StatelessWidget {
  final int slotIndex;
  final Task? task;
  final double height;

  const TaskReorderPlaceholderItem({
    super.key,
    required this.slotIndex,
    this.task,
    this.height = 52.0,
  });

  static Widget? maybeBuild({
    required TaskReorderListSlot slotInfo,
    required int index,
    TaskReorderActiveDrop? activeDrop,
  }) {
    if (!slotInfo.isPlaceholder(index)) return null;
    final slot = activeDrop?.slot.isValid == true
        ? activeDrop!.slot.index
        : (slotInfo.draggedIndex ?? index);
    return TaskReorderPlaceholderItem(
      key: const ValueKey('drag_placeholder_gap'),
      slotIndex: slot,
      task: slotInfo.task,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = TaskReorderScope.of(context);
    final theme = Theme.of(context);
    final emptySpace = SizedBox(
      height: height,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.22),
            strokeAlign: BorderSide.strokeAlignInside,
            width: 1.5,
          ),
        ),
      ),
    );
    if (scope == null) return emptySpace;

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        scope.onHoverSlot(details.data, slotIndex);
        return true;
      },
      onMove: (details) {
        scope.onHoverSlot(details.data, slotIndex);
      },
      onLeave: (_) {
        scope.onLeaveSlot();
      },
      onAcceptWithDetails: (details) {
        scope.drop(details.data, slotIndex);
      },
      builder: (context, _, _) => emptySpace,
    );
  }
}
