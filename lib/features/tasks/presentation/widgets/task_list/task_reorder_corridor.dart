import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_drag_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_drop_zone_scope.dart';

class TaskReorderCorridor extends ConsumerStatefulWidget {
  final Widget child;
  final ScrollController scrollController;
  final List<TaskHierarchyNode> nodes;
  final EdgeInsets padding;
  final void Function(Task task, int targetIndex) onDrop;

  const TaskReorderCorridor({
    super.key,
    required this.child,
    required this.scrollController,
    required this.nodes,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    required this.onDrop,
  });

  @override
  ConsumerState<TaskReorderCorridor> createState() =>
      _TaskReorderCorridorState();
}

class _TaskReorderCorridorState extends ConsumerState<TaskReorderCorridor>
    with SingleTickerProviderStateMixin {
  late final Ticker _scrollTicker;
  Duration _lastTick = Duration.zero;
  double _scrollVelocity = 0;
  bool _isRouteAttached = false;
  bool _isCorridorTargetActive = false;
  int? _corridorTargetIndex;
  Task? _lastActiveTask;

  @override
  void initState() {
    super.initState();
    _scrollTicker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _detachGlobalRoute();
    _scrollTicker.dispose();
    super.dispose();
  }

  void _attachGlobalRoute() {
    if (!_isRouteAttached) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(
        _handleGlobalPointerEvent,
      );
      _isRouteAttached = true;
    }
  }

  void _detachGlobalRoute() {
    if (_isRouteAttached) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(
        _handleGlobalPointerEvent,
      );
      _isRouteAttached = false;
    }
    _stopAutoScroll();
    _isCorridorTargetActive = false;
    _corridorTargetIndex = null;
  }

  void _startOrUpdateAutoScroll(int direction, double deltaY) {
    final speed = (150.0 + 7.0 * deltaY).clamp(150.0, 1200.0);
    _scrollVelocity = direction * speed;
    if (!_scrollTicker.isActive) {
      _lastTick = Duration.zero;
      _scrollTicker.start();
    }
  }

  void _stopAutoScroll() {
    if (_scrollTicker.isActive) {
      _scrollTicker.stop();
    }
    _lastTick = Duration.zero;
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    final dt = (elapsed - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = elapsed;

    if (!widget.scrollController.hasClients) return;

    final currentOffset = widget.scrollController.offset;
    final delta = _scrollVelocity * dt;
    final newOffset = (currentOffset + delta).clamp(
      widget.scrollController.position.minScrollExtent,
      widget.scrollController.position.maxScrollExtent,
    );

    if ((newOffset - currentOffset).abs() > 0.01) {
      widget.scrollController.jumpTo(newOffset);
    }
  }

  Task? _findTask(String? id) {
    if (id == null) return null;
    for (final node in widget.nodes) {
      if (node.task?.id == id) return node.task;
    }
    return null;
  }

  void _handleGlobalPointerEvent(PointerEvent event) {
    final dragSession = ref.read(taskDragProvider);
    final draggedTaskId = dragSession.draggedTaskId;
    if (draggedTaskId == null && event is! PointerUpEvent) {
      _detachGlobalRoute();
      return;
    }

    final scope = TaskDropZoneScope.of(context);
    if (scope == null) return;

    if (event is PointerMoveEvent) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return;

      final origin = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final rect = origin & size;
      final horizontalMargin = math.max(32.0, widget.padding.left);
      final corridorLeft = rect.left - horizontalMargin;
      final corridorRight = rect.right + horizontalMargin;

      final px = event.position.dx;
      final py = event.position.dy;

      if (px < corridorLeft || px > corridorRight) {
        _stopAutoScroll();
        if (_isCorridorTargetActive) {
          _isCorridorTargetActive = false;
          _corridorTargetIndex = null;
          scope.activeDropNotifier.value = null;
          ref.read(taskDragProvider.notifier).setValidTarget(false);
        }
        return;
      }

      final task = _findTask(draggedTaskId) ?? _lastActiveTask;
      if (task == null) return;
      _lastActiveTask = task;

      if (py < rect.top) {
        final deltaY = rect.top - py;
        _startOrUpdateAutoScroll(-1, deltaY);
        final topIndex = scope.resolveClampedTopIndex(task);
        final isUnchanged = scope.isPositionUnchanged(task, topIndex);
        final isValid = scope.isPositionValid(task, topIndex);

        _isCorridorTargetActive = true;
        _corridorTargetIndex = topIndex;
        scope.activeDropNotifier.value = TaskDropState(
          index: topIndex,
          task: task,
        );
        ref
            .read(taskDragProvider.notifier)
            .setValidTarget(isValid && !isUnchanged);
      } else if (py > rect.bottom) {
        final deltaY = py - rect.bottom;
        _startOrUpdateAutoScroll(1, deltaY);
        final bottomIndex = scope.resolveClampedBottomIndex(task);
        final isUnchanged = scope.isPositionUnchanged(task, bottomIndex);
        final isValid = scope.isPositionValid(task, bottomIndex);

        _isCorridorTargetActive = true;
        _corridorTargetIndex = bottomIndex;
        scope.activeDropNotifier.value = TaskDropState(
          index: bottomIndex,
          task: task,
        );
        ref
            .read(taskDragProvider.notifier)
            .setValidTarget(isValid && !isUnchanged);
      } else {
        _stopAutoScroll();
        if (_isCorridorTargetActive) {
          _isCorridorTargetActive = false;
          _corridorTargetIndex = null;
        }
      }
    } else if (event is PointerUpEvent) {
      _stopAutoScroll();
      if (_isCorridorTargetActive) {
        final targetIndex = _corridorTargetIndex;
        final task = _findTask(draggedTaskId) ?? _lastActiveTask;
        _isCorridorTargetActive = false;
        _corridorTargetIndex = null;
        _lastActiveTask = null;
        scope.activeDropNotifier.value = null;
        ref.read(taskDragProvider.notifier).endDrag();
        if (task != null &&
            targetIndex != null &&
            scope.isPositionValid(task, targetIndex) &&
            !scope.isPositionUnchanged(task, targetIndex)) {
          widget.onDrop(task, targetIndex);
        }
      }
      _detachGlobalRoute();
    } else if (event is PointerCancelEvent) {
      _stopAutoScroll();
      _isCorridorTargetActive = false;
      _corridorTargetIndex = null;
      _lastActiveTask = null;
      _detachGlobalRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TaskDragState>(taskDragProvider, (prev, next) {
      if (next.draggedTaskId != null && prev?.draggedTaskId == null) {
        _attachGlobalRoute();
      } else if (next.draggedTaskId == null && prev?.draggedTaskId != null) {
        _detachGlobalRoute();
      }
    });

    return widget.child;
  }
}
