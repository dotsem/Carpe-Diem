import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/tasks/data/models/subtask_completion_conflict.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';

class SubtaskService {
  final ITaskRepository _repo;
  const SubtaskService(this._repo);

  Future<SubtaskCompletionConflict?> checkSubtaskConflict(Task task) async {
    final incomplete = (await _repo.getByParent(
      task.id,
    )).where((subtask) => !subtask.isCompleted).toList();
    return incomplete.isEmpty
        ? null
        : SubtaskCompletionConflict(
            parentTask: task,
            incompleteSubtasks: incomplete,
          );
  }

  Future<Task?> findCompletableParent(Task task) async {
    if (task.parentId == null) return null;
    final siblings = await _repo.getByParent(task.parentId!);
    if (!siblings.where((s) => s.id != task.id).every((s) => s.isCompleted)) {
      return null;
    }
    final parent = await _repo.getById(task.parentId!);
    return parent == null || parent.isCompleted ? null : parent;
  }

  List<Task> getAllSubtasks({
    required String parentId,
    required List<Task> allTasks,
  }) {
    final result = <Task>[];
    void collect(String id) {
      for (final child in allTasks.where((task) => task.parentId == id)) {
        result.add(child);
        collect(child.id);
      }
    }

    collect(parentId);
    return result;
  }

  Future<List<Task>> getAllSubtasksFromRepo(String parentId) async {
    final result = <Task>[];
    Future<void> collect(String id) async {
      for (final child in await _repo.getByParent(id)) {
        result.add(child);
        await collect(child.id);
      }
    }

    await collect(parentId);
    return result;
  }
}
