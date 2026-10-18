import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_engine.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_slot.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_drag_provider.dart';

class TaskReorderActiveDrop {
  final int index;
  final Task task;
  final TaskReorderSlot slot;

  const TaskReorderActiveDrop({
    required this.index,
    required this.task,
    required this.slot,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskReorderActiveDrop &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          task.id == other.task.id &&
          slot == other.slot;

  @override
  int get hashCode => Object.hash(index, task.id, slot);
}

class TaskReorderScope extends ConsumerStatefulWidget {
  final List<TaskHierarchyNode> nodes;
  final bool isPlanView;
  final SettingsState? settings;
  final void Function(Task task, int targetIndex) onDrop;
  final Widget child;

  const TaskReorderScope({
    super.key,
    required this.nodes,
    this.isPlanView = false,
    this.settings,
    required this.onDrop,
    required this.child,
  });

  static TaskReorderScopeInherited? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TaskReorderScopeInherited>();
  }

  @override
  ConsumerState<TaskReorderScope> createState() => _TaskReorderScopeState();
}

class _TaskReorderScopeState extends ConsumerState<TaskReorderScope> {
  final ValueNotifier<TaskReorderActiveDrop?> _activeDrop =
      ValueNotifier<TaskReorderActiveDrop?>(null);
  int _hoverEpoch = 0;

  @override
  void dispose() {
    _activeDrop.dispose();
    super.dispose();
  }

  TaskReorderSlot _resolveSlot(Task task, int rawIndex) {
    SettingsState? settings = widget.settings;
    if (settings == null) {
      try {
        settings = ref.read(settingsProvider);
      } catch (_) {
        // fallback for isolated widget tests without settings provider overrides
      }
    }
    return TaskReorderEngine.resolveSlot(
      nodes: widget.nodes,
      draggedTask: task,
      rawIndex: rawIndex,
      settings: settings,
      isPlanView: widget.isPlanView,
    );
  }

  void _onHoverSlot(Task task, int rawIndex) {
    _hoverEpoch++;
    final slot = _resolveSlot(task, rawIndex);
    _activeDrop.value = TaskReorderActiveDrop(
      index: slot.index,
      task: task,
      slot: slot,
    );
    ref
        .read(taskDragProvider.notifier)
        .setValidTarget(slot.isValid && !slot.isUnchanged);
  }

  void _onLeaveSlot() {
    final currentEpoch = ++_hoverEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_hoverEpoch == currentEpoch) {
        _activeDrop.value = null;
        ref.read(taskDragProvider.notifier).setValidTarget(false);
      }
    });
  }

  void _drop(Task task, int rawIndex) {
    _hoverEpoch++;
    final slot = _resolveSlot(task, rawIndex);
    _activeDrop.value = null;
    ref.read(taskDragProvider.notifier).endDrag();
    if (slot.isValid && !slot.isUnchanged) {
      widget.onDrop(task, slot.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TaskReorderScopeInherited(
      activeDropNotifier: _activeDrop,
      nodes: widget.nodes,
      isPlanView: widget.isPlanView,
      resolveSlot: _resolveSlot,
      onHoverSlot: _onHoverSlot,
      onLeaveSlot: _onLeaveSlot,
      drop: _drop,
      child: widget.child,
    );
  }
}

class TaskReorderScopeInherited extends InheritedWidget {
  final ValueNotifier<TaskReorderActiveDrop?> activeDropNotifier;
  final List<TaskHierarchyNode> nodes;
  final bool isPlanView;
  final TaskReorderSlot Function(Task task, int rawIndex) resolveSlot;
  final void Function(Task task, int rawIndex) onHoverSlot;
  final void Function() onLeaveSlot;
  final void Function(Task task, int rawIndex) drop;

  const TaskReorderScopeInherited({
    super.key,
    required this.activeDropNotifier,
    required this.nodes,
    required this.isPlanView,
    required this.resolveSlot,
    required this.onHoverSlot,
    required this.onLeaveSlot,
    required this.drop,
    required super.child,
  });

  @override
  bool updateShouldNotify(TaskReorderScopeInherited oldWidget) {
    return activeDropNotifier != oldWidget.activeDropNotifier ||
        nodes != oldWidget.nodes ||
        isPlanView != oldWidget.isPlanView;
  }
}
