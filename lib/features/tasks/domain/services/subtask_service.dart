import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/tasks/data/models/subtask_completion_conflict.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';

class SubtaskService {
  static Future<SubtaskCompletionConflict?> checkSubtaskConflict({
    required ITaskRepository repo,
    required Task task,
  }) async {
    final subtasks = await repo.getByParent(task.id);
    final incomplete = subtasks.where((s) => !s.isCompleted).toList();
    if (incomplete.isNotEmpty) {
      return SubtaskCompletionConflict(
        parentTask: task,
        incompleteSubtasks: incomplete,
      );
    }
    return null;
  }

  /// Returns the parent of [task] if completing [task] leaves every sibling
  /// done and the parent itself is still open.
  static Future<Task?> findCompletableParent({
    required ITaskRepository repo,
    required Task task,
  }) async {
    if (task.parentId == null) return null;
    final siblings = await repo.getByParent(task.parentId!);
    if (!siblings.where((s) => s.id != task.id).every((s) => s.isCompleted)) {
      return null;
    }
    final parent = await repo.getById(task.parentId!);
    if (parent == null || parent.isCompleted) return null;
    return parent;
  }

  static List<Task> getAllSubtasks({
    required String parentId,
    required List<Task> allTasks,
  }) {
    final result = <Task>[];
    void collect(String pid) {
      final children = allTasks.where((t) => t.parentId == pid).toList();
      for (final child in children) {
        result.add(child);
        collect(child.id);
      }
    }

    collect(parentId);
    return result;
  }

  static Future<List<Task>> getAllSubtasksFromRepo({
    required ITaskRepository repo,
    required String parentId,
  }) async {
    final result = <Task>[];
    Future<void> collect(String pid) async {
      final children = await repo.getByParent(pid);
      for (final child in children) {
        result.add(child);
        await collect(child.id);
      }
    }

    await collect(parentId);
    return result;
  }
}
