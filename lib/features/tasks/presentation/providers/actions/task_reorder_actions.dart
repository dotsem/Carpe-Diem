import 'package:carpe_diem/core/reorder/lexorank.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_engine.dart';
import 'package:carpe_diem/features/tasks/domain/reorder/task_reorder_utils.dart';
import 'package:carpe_diem/features/tasks/domain/task_prefs.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';

abstract final class TaskReorderActions {
  static bool dispatchReorder({
    required List<TaskHierarchyNode> nodes,
    required Task draggedTask,
    required int newIndex,
    required TaskPrefs prefs,
    Set<String> selectedTaskIds = const {},
    bool isPlanView = false,
    TaskNotifier? notifier,
    void Function(Task, String)? onReorder,
    void Function(Map<String, String>)? onMultiReorder,
  }) {
    if (selectedTaskIds.contains(draggedTask.id)) {
      final ranks = TaskReorderUtils.handleMultiReorder(
        nodes: nodes,
        draggedTask: draggedTask,
        newIndex: newIndex,
        selectedTaskIds: selectedTaskIds,
        settings: prefs,
        isPlanView: isPlanView,
      );
      if (ranks != null && ranks.isNotEmpty) {
        if (onMultiReorder != null) {
          onMultiReorder(ranks);
        } else {
          notifier?.bulkReorderTasks(ranks, isPlanOrder: isPlanView);
        }
        return true;
      }
    }
    final rank = TaskReorderUtils.handleReorder(
      nodes: nodes,
      draggedTask: draggedTask,
      newIndex: newIndex,
      settings: prefs,
      isPlanView: isPlanView,
    );
    if (rank == null) return false;
    if (onReorder != null) {
      onReorder(draggedTask, rank);
    } else {
      notifier?.reorderTask(draggedTask, rank, isPlanOrder: isPlanView);
    }
    return true;
  }

  static void moveToTop(
    TaskNotifier notifier,
    Task task,
    List<Task> tasks,
    TaskPrefs prefs, {
    bool isPlanView = false,
  }) => _moveToEdge(
    notifier,
    task,
    tasks,
    prefs,
    toTop: true,
    isPlanView: isPlanView,
  );

  static void moveToBottom(
    TaskNotifier notifier,
    Task task,
    List<Task> tasks,
    TaskPrefs prefs, {
    bool isPlanView = false,
  }) => _moveToEdge(
    notifier,
    task,
    tasks,
    prefs,
    toTop: false,
    isPlanView: isPlanView,
  );

  static void _moveToEdge(
    TaskNotifier notifier,
    Task task,
    List<Task> tasks,
    TaskPrefs prefs, {
    required bool toTop,
    bool isPlanView = false,
  }) {
    final same = tasks
        .where(
          (candidate) => TaskReorderEngine.inSameGroup(candidate, task, prefs),
        )
        .toList();
    if (same.isEmpty || (toTop ? same.first.id : same.last.id) == task.id) {
      return;
    }
    final edge = TaskReorderEngine.getEffectiveRank(
      same,
      toTop ? 0 : same.length - 1,
      isPlanView: isPlanView,
    );
    notifier.reorderTask(
      task,
      LexoRank.generateBetween(toTop ? null : edge, toTop ? edge : null),
      isPlanOrder: isPlanView,
    );
  }
}
