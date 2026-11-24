import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/domain/task_prefs.dart';

class DeadlinePropagationService {
  final ITaskRepository _repo;
  final TaskPrefs Function() _prefs;
  const DeadlinePropagationService(this._repo, this._prefs);

  Future<List<UpdateCommand<Task>>> buildPropagationCommands(
    Task task, {
    Set<String>? visited,
  }) async {
    if (!_prefs().inheritParentDeadline ||
        task.deadline == null ||
        task.blockedById == null) {
      return const [];
    }
    final localVisited = visited ?? <String>{};
    if (!localVisited.add(task.id)) return const [];
    final blocker = await _repo.getById(task.blockedById!);
    if (blocker == null) return const [];
    final commands = <UpdateCommand<Task>>[];
    if (blocker.deadline == null || blocker.deadline!.isAfter(task.deadline!)) {
      final updated = blocker.copyWith(deadline: task.deadline);
      commands.add(
        UpdateCommand(
          repo: _repo,
          previous: blocker,
          next: updated,
          displayName: blocker.title,
        ),
      );
      commands.addAll(
        await buildPropagationCommands(updated, visited: localVisited),
      );
    }
    return commands;
  }
}
