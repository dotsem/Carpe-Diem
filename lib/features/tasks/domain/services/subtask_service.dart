import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/tasks/data/models/subtask_completion_conflict.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/domain/services/task_completion_service.dart';

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

  static Future<Command> buildCompleteSubtaskCommand({
    required ITaskRepository repo,
    required Task task,
  }) async {
    final subtaskCmd = TaskCompletionService.buildCompleteCommand(
      repo: repo,
      task: task,
    );
    if (task.parentId == null) return subtaskCmd;

    final siblings = await repo.getByParent(task.parentId!);
    final otherSiblings = siblings.where((s) => s.id != task.id);
    final allOtherSiblingsDone = otherSiblings.every((s) => s.isCompleted);

    if (allOtherSiblingsDone) {
      final parent = await repo.getById(task.parentId!);
      if (parent != null && !parent.isCompleted) {
        final parentCmd = TaskCompletionService.buildCompleteCommand(
          repo: repo,
          task: parent,
        );
        return CompoundCommand([
          subtaskCmd,
          parentCmd,
        ], 'Complete "${task.title}" and auto-complete "${parent.title}"');
      }
    }

    return subtaskCmd;
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
